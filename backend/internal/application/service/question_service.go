package service

import (
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"backend/internal/application/dto"
	"backend/internal/domain"
	"github.com/google/uuid"
)

type QuestionService interface {
	AddQuestion(ctx context.Context, userID uuid.UUID, formID uuid.UUID, req dto.CreateQuestionRequest) (*dto.QuestionDTO, error)
	UpdateQuestion(ctx context.Context, userID uuid.UUID, questionID uuid.UUID, req dto.UpdateQuestionRequest) (*dto.QuestionDTO, error)
	DeleteQuestion(ctx context.Context, userID uuid.UUID, questionID uuid.UUID) error
	DeleteOption(ctx context.Context, userID uuid.UUID, optionID uuid.UUID) error
	UploadQuestionImage(ctx context.Context, fileHeader *multipart.FileHeader) (*dto.UploadImageResponse, error)
	UploadMedia(ctx context.Context, fileHeader *multipart.FileHeader) (*dto.UploadMediaResponse, error)
}

type questionService struct {
	questionRepo domain.QuestionRepository
	formRepo     domain.FormRepository
}

func NewQuestionService(questionRepo domain.QuestionRepository, formRepo domain.FormRepository) QuestionService {
	return &questionService{
		questionRepo: questionRepo,
		formRepo:     formRepo,
	}
}

func (s *questionService) AddQuestion(ctx context.Context, userID uuid.UUID, formID uuid.UUID, req dto.CreateQuestionRequest) (*dto.QuestionDTO, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}

	if form.UserID != userID {
		return nil, domain.ErrForbidden
	}

	qID := uuid.New()
	var options []domain.QuestionOption
	for i, optReq := range req.Options {
		idx := optReq.OrderIndex
		if idx == 0 {
			idx = i + 1
		}
		options = append(options, domain.QuestionOption{
			ID:              uuid.New(),
			QuestionID:      qID,
			OptionText:      optReq.OptionText,
			ImgURL:          optReq.ImgURL,
			AudioURL:        optReq.AudioURL,
			VideoURL:        optReq.VideoURL,
			MatchKey:        optReq.MatchKey,
			MatchTargetText: optReq.MatchTargetText,
			IsCorrect:       optReq.IsCorrect,
			OrderIndex:      idx,
		})
	}

	now := time.Now()
	question := &domain.Question{
		ID:            qID,
		FormID:        formID,
		QuestionText:  req.QuestionText,
		QuestionType:  req.QuestionType,
		CodeLanguage:  req.CodeLanguage,
		ImgURL:        req.ImgURL,
		AudioURL:      req.AudioURL,
		VideoURL:      req.VideoURL,
		IsAutoScored:  req.IsAutoScored,
		Points:        req.Points,
		OrderIndex:    req.OrderIndex,
		IsRequired:    req.IsRequired,
		IsAutosavedAt: &now,
		Options:       options,
	}

	if err := s.questionRepo.CreateQuestion(ctx, question); err != nil {
		return nil, err
	}

	return s.mapQuestionToDTO(question), nil
}

func (s *questionService) UpdateQuestion(ctx context.Context, userID uuid.UUID, questionID uuid.UUID, req dto.UpdateQuestionRequest) (*dto.QuestionDTO, error) {
	q, err := s.questionRepo.GetQuestionByID(ctx, questionID)
	if err != nil {
		return nil, err
	}

	form, err := s.formRepo.GetByID(ctx, q.FormID)
	if err != nil {
		return nil, err
	}

	if form.UserID != userID {
		return nil, domain.ErrForbidden
	}

	q.QuestionText = req.QuestionText
	q.QuestionType = req.QuestionType
	q.CodeLanguage = req.CodeLanguage
	q.ImgURL = req.ImgURL
	q.AudioURL = req.AudioURL
	q.VideoURL = req.VideoURL
	q.IsAutoScored = req.IsAutoScored
	q.Points = req.Points
	q.OrderIndex = req.OrderIndex
	q.IsRequired = req.IsRequired
	now := time.Now()
	q.IsAutosavedAt = &now

	var options []domain.QuestionOption
	for i, optReq := range req.Options {
		idx := optReq.OrderIndex
		if idx == 0 {
			idx = i + 1
		}
		options = append(options, domain.QuestionOption{
			ID:              uuid.New(),
			QuestionID:      q.ID,
			OptionText:      optReq.OptionText,
			ImgURL:          optReq.ImgURL,
			AudioURL:        optReq.AudioURL,
			VideoURL:        optReq.VideoURL,
			MatchKey:        optReq.MatchKey,
			MatchTargetText: optReq.MatchTargetText,
			IsCorrect:       optReq.IsCorrect,
			OrderIndex:      idx,
		})
	}
	q.Options = options

	if err := s.questionRepo.UpdateQuestion(ctx, q); err != nil {
		return nil, err
	}

	return s.mapQuestionToDTO(q), nil
}

func (s *questionService) DeleteQuestion(ctx context.Context, userID uuid.UUID, questionID uuid.UUID) error {
	q, err := s.questionRepo.GetQuestionByID(ctx, questionID)
	if err != nil {
		return err
	}

	form, err := s.formRepo.GetByID(ctx, q.FormID)
	if err != nil {
		return err
	}

	if form.UserID != userID {
		return domain.ErrForbidden
	}

	return s.questionRepo.DeleteQuestion(ctx, questionID)
}

func (s *questionService) DeleteOption(ctx context.Context, userID uuid.UUID, optionID uuid.UUID) error {
	opt, err := s.questionRepo.GetOptionByID(ctx, optionID)
	if err != nil {
		return err
	}

	q, err := s.questionRepo.GetQuestionByID(ctx, opt.QuestionID)
	if err != nil {
		return err
	}

	form, err := s.formRepo.GetByID(ctx, q.FormID)
	if err != nil {
		return err
	}

	if form.UserID != userID {
		return domain.ErrForbidden
	}

	return s.questionRepo.DeleteOption(ctx, optionID)
}

func (s *questionService) UploadQuestionImage(ctx context.Context, fileHeader *multipart.FileHeader) (*dto.UploadImageResponse, error) {
	uploadDir := "./uploads"
	if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
		return nil, fmt.Errorf("failed to create upload directory: %w", err)
	}

	ext := filepath.Ext(fileHeader.Filename)
	if ext == "" {
		ext = ".png"
	}
	filename := fmt.Sprintf("%s_%s%s", time.Now().Format("20060102_150405"), uuid.New().String()[:8], ext)
	dstPath := filepath.Join(uploadDir, filename)

	src, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer src.Close()

	out, err := os.Create(dstPath)
	if err != nil {
		return nil, fmt.Errorf("failed to save file: %w", err)
	}
	defer out.Close()

	if _, err = io.Copy(out, src); err != nil {
		return nil, fmt.Errorf("failed to write file to storage: %w", err)
	}

	imageURL := fmt.Sprintf("/uploads/%s", filename)
	return &dto.UploadImageResponse{ImgURL: imageURL}, nil
}

func (s *questionService) UploadMedia(ctx context.Context, fileHeader *multipart.FileHeader) (*dto.UploadMediaResponse, error) {
	uploadDir := "./uploads/media"
	if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
		return nil, fmt.Errorf("failed to create media upload directory: %w", err)
	}

	ext := filepath.Ext(fileHeader.Filename)
	mediaType := "IMAGE"
	switch strings.ToLower(ext) {
	case ".mp3", ".wav", ".ogg", ".m4a":
		mediaType = "AUDIO"
	case ".mp4", ".webm", ".mkv", ".mov":
		mediaType = "VIDEO"
	default:
		mediaType = "IMAGE"
	}

	filename := fmt.Sprintf("%s_%s%s", time.Now().Format("20060102_150405"), uuid.New().String()[:8], ext)
	dstPath := filepath.Join(uploadDir, filename)

	src, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer src.Close()

	out, err := os.Create(dstPath)
	if err != nil {
		return nil, fmt.Errorf("failed to save file: %w", err)
	}
	defer out.Close()

	if _, err = io.Copy(out, src); err != nil {
		return nil, fmt.Errorf("failed to write file to storage: %w", err)
	}

	mediaURL := fmt.Sprintf("/uploads/media/%s", filename)
	return &dto.UploadMediaResponse{
		MediaURL:  mediaURL,
		MediaType: mediaType,
	}, nil
}

func (s *questionService) mapQuestionToDTO(q *domain.Question) *dto.QuestionDTO {
	var optDTOs []dto.OptionDTO
	for _, opt := range q.Options {
		optDTOs = append(optDTOs, dto.OptionDTO{
			ID:              opt.ID,
			QuestionID:      opt.QuestionID,
			OptionText:      opt.OptionText,
			ImgURL:          opt.ImgURL,
			AudioURL:        opt.AudioURL,
			VideoURL:        opt.VideoURL,
			MatchKey:        opt.MatchKey,
			MatchTargetText: opt.MatchTargetText,
			IsCorrect:       opt.IsCorrect,
			OrderIndex:      opt.OrderIndex,
		})
	}

	return &dto.QuestionDTO{
		ID:           q.ID,
		FormID:       q.FormID,
		QuestionText: q.QuestionText,
		QuestionType: q.QuestionType,
		CodeLanguage: q.CodeLanguage,
		ImgURL:       q.ImgURL,
		AudioURL:     q.AudioURL,
		VideoURL:     q.VideoURL,
		IsAutoScored: q.IsAutoScored,
		Points:       q.Points,
		OrderIndex:   q.OrderIndex,
		IsRequired:   q.IsRequired,
		Options:      optDTOs,
	}
}
