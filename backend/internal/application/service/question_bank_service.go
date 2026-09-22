package service

import (
	"context"

	"backend/internal/application/dto"
	"backend/internal/domain"
	"github.com/google/uuid"
)

type QuestionBankService interface {
	Create(ctx context.Context, userID uuid.UUID, req dto.CreateBankQuestionRequest) (*dto.BankQuestionDTO, error)
	List(ctx context.Context, userID uuid.UUID, filter domain.BankQuestionFilter, pg domain.Pagination) (*dto.PaginatedBankQuestionsDTO, error)
	Update(ctx context.Context, userID uuid.UUID, id uuid.UUID, req dto.UpdateBankQuestionRequest) (*dto.BankQuestionDTO, error)
	Delete(ctx context.Context, userID uuid.UUID, id uuid.UUID) error
	// AddToForm menyalin (COPY, bukan reference) satu BankQuestion menjadi Question
	// baru di form tujuan.
	AddToForm(ctx context.Context, userID uuid.UUID, bankQuestionID uuid.UUID, formID uuid.UUID) (*dto.QuestionDTO, error)
	// SaveFromQuestion menyalin satu Question yang sudah ada di sebuah form menjadi
	// entri baru di Bank Soal (kebalikan dari AddToForm).
	SaveFromQuestion(ctx context.Context, userID uuid.UUID, questionID uuid.UUID, req dto.SaveQuestionToBankRequest) (*dto.BankQuestionDTO, error)
}

type questionBankService struct {
	bankRepo     domain.BankQuestionRepository
	questionRepo domain.QuestionRepository
	formRepo     domain.FormRepository
}

func NewQuestionBankService(bankRepo domain.BankQuestionRepository, questionRepo domain.QuestionRepository, formRepo domain.FormRepository) QuestionBankService {
	return &questionBankService{bankRepo: bankRepo, questionRepo: questionRepo, formRepo: formRepo}
}

func mapBankOptionsFromInput(bankQuestionID uuid.UUID, inputs []dto.BankQuestionOptionInput) []domain.BankQuestionOption {
	var opts []domain.BankQuestionOption
	for i, o := range inputs {
		opts = append(opts, domain.BankQuestionOption{
			ID:              uuid.New(),
			BankQuestionID:  bankQuestionID,
			OptionText:      o.OptionText,
			ImgURL:          o.ImgURL,
			AudioURL:        o.AudioURL,
			VideoURL:        o.VideoURL,
			MatchKey:        o.MatchKey,
			MatchTargetText: o.MatchTargetText,
			IsCorrect:       o.IsCorrect,
			OrderIndex:      i + 1,
		})
	}
	return opts
}

func mapBankQuestionToDTO(q *domain.BankQuestion) *dto.BankQuestionDTO {
	var opts []dto.BankQuestionOptionDTO
	for _, o := range q.Options {
		opts = append(opts, dto.BankQuestionOptionDTO{
			ID:              o.ID,
			OptionText:      o.OptionText,
			ImgURL:          o.ImgURL,
			AudioURL:        o.AudioURL,
			VideoURL:        o.VideoURL,
			MatchKey:        o.MatchKey,
			MatchTargetText: o.MatchTargetText,
			IsCorrect:       o.IsCorrect,
			OrderIndex:      o.OrderIndex,
		})
	}
	return &dto.BankQuestionDTO{
		ID:           q.ID,
		Subject:      q.Subject,
		Topic:        q.Topic,
		Difficulty:   q.Difficulty,
		QuestionText: q.QuestionText,
		QuestionType: q.QuestionType,
		CodeLanguage: q.CodeLanguage,
		ImgURL:       q.ImgURL,
		AudioURL:     q.AudioURL,
		VideoURL:     q.VideoURL,
		Points:       q.Points,
		CreatedAt:    q.CreatedAt,
		Options:      opts,
	}
}

func (s *questionBankService) Create(ctx context.Context, userID uuid.UUID, req dto.CreateBankQuestionRequest) (*dto.BankQuestionDTO, error) {
	difficulty := req.Difficulty
	if difficulty == "" {
		difficulty = domain.DifficultyMedium
	}
	points := req.Points
	if points <= 0 {
		points = 10
	}

	bq := &domain.BankQuestion{
		ID:           uuid.New(),
		UserID:       userID,
		Subject:      req.Subject,
		Topic:        req.Topic,
		Difficulty:   difficulty,
		QuestionText: req.QuestionText,
		QuestionType: req.QuestionType,
		CodeLanguage: req.CodeLanguage,
		ImgURL:       req.ImgURL,
		AudioURL:     req.AudioURL,
		VideoURL:     req.VideoURL,
		Points:       points,
	}
	bq.Options = mapBankOptionsFromInput(bq.ID, req.Options)

	if err := s.bankRepo.Create(ctx, bq); err != nil {
		return nil, err
	}
	return mapBankQuestionToDTO(bq), nil
}

func (s *questionBankService) List(ctx context.Context, userID uuid.UUID, filter domain.BankQuestionFilter, pg domain.Pagination) (*dto.PaginatedBankQuestionsDTO, error) {
	items, total, err := s.bankRepo.ListByUser(ctx, userID, filter, pg)
	if err != nil {
		return nil, err
	}
	var dtos []dto.BankQuestionDTO
	for _, it := range items {
		dtos = append(dtos, *mapBankQuestionToDTO(&it))
	}
	return &dto.PaginatedBankQuestionsDTO{Items: dtos, Total: total, Limit: pg.Limit, Offset: pg.Offset}, nil
}

func (s *questionBankService) Update(ctx context.Context, userID uuid.UUID, id uuid.UUID, req dto.UpdateBankQuestionRequest) (*dto.BankQuestionDTO, error) {
	existing, err := s.bankRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if existing.UserID != userID {
		return nil, domain.ErrForbidden
	}

	existing.Subject = req.Subject
	existing.Topic = req.Topic
	if req.Difficulty != "" {
		existing.Difficulty = req.Difficulty
	}
	existing.QuestionText = req.QuestionText
	existing.QuestionType = req.QuestionType
	existing.CodeLanguage = req.CodeLanguage
	existing.ImgURL = req.ImgURL
	existing.AudioURL = req.AudioURL
	existing.VideoURL = req.VideoURL
	if req.Points > 0 {
		existing.Points = req.Points
	}
	existing.Options = mapBankOptionsFromInput(existing.ID, req.Options)

	if err := s.bankRepo.Update(ctx, existing); err != nil {
		return nil, err
	}
	return mapBankQuestionToDTO(existing), nil
}

func (s *questionBankService) Delete(ctx context.Context, userID uuid.UUID, id uuid.UUID) error {
	existing, err := s.bankRepo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if existing.UserID != userID {
		return domain.ErrForbidden
	}
	return s.bankRepo.Delete(ctx, id)
}

func (s *questionBankService) AddToForm(ctx context.Context, userID uuid.UUID, bankQuestionID uuid.UUID, formID uuid.UUID) (*dto.QuestionDTO, error) {
	bq, err := s.bankRepo.GetByID(ctx, bankQuestionID)
	if err != nil {
		return nil, err
	}
	if bq.UserID != userID {
		return nil, domain.ErrForbidden
	}

	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}
	if form.UserID != userID {
		return nil, domain.ErrForbidden
	}

	existingQuestions, _ := s.questionRepo.GetQuestionsByFormID(ctx, formID)
	nextOrder := len(existingQuestions) + 1

	isAutoScored := true
	switch bq.QuestionType {
	case domain.TypeShortText, domain.TypeLongText, domain.TypeCode, domain.TypeMath:
		isAutoScored = false
	}

	newQ := domain.Question{
		ID:           uuid.New(),
		FormID:       formID,
		QuestionText: bq.QuestionText,
		QuestionType: bq.QuestionType,
		CodeLanguage: bq.CodeLanguage,
		ImgURL:       bq.ImgURL,
		AudioURL:     bq.AudioURL,
		VideoURL:     bq.VideoURL,
		IsAutoScored: isAutoScored,
		Points:       bq.Points,
		OrderIndex:   nextOrder,
		IsRequired:   true,
	}
	for _, o := range bq.Options {
		newQ.Options = append(newQ.Options, domain.QuestionOption{
			ID:              uuid.New(),
			QuestionID:      newQ.ID,
			OptionText:      o.OptionText,
			ImgURL:          o.ImgURL,
			AudioURL:        o.AudioURL,
			VideoURL:        o.VideoURL,
			MatchKey:        o.MatchKey,
			MatchTargetText: o.MatchTargetText,
			IsCorrect:       o.IsCorrect,
			OrderIndex:      o.OrderIndex,
		})
	}

	if err := s.questionRepo.CreateQuestion(ctx, &newQ); err != nil {
		return nil, err
	}

	var optDTOs []dto.OptionDTO
	for _, o := range newQ.Options {
		optDTOs = append(optDTOs, dto.OptionDTO{
			ID: o.ID, QuestionID: o.QuestionID, OptionText: o.OptionText,
			ImgURL: o.ImgURL, AudioURL: o.AudioURL, VideoURL: o.VideoURL,
			MatchKey: o.MatchKey, MatchTargetText: o.MatchTargetText,
			IsCorrect: o.IsCorrect, OrderIndex: o.OrderIndex,
		})
	}
	return &dto.QuestionDTO{
		ID: newQ.ID, FormID: newQ.FormID, QuestionText: newQ.QuestionText,
		QuestionType: newQ.QuestionType, ImgURL: newQ.ImgURL, IsAutoScored: newQ.IsAutoScored,
		Points: newQ.Points, OrderIndex: newQ.OrderIndex, IsRequired: newQ.IsRequired,
		Options: optDTOs,
	}, nil
}

func (s *questionBankService) SaveFromQuestion(ctx context.Context, userID uuid.UUID, questionID uuid.UUID, req dto.SaveQuestionToBankRequest) (*dto.BankQuestionDTO, error) {
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

	difficulty := req.Difficulty
	if difficulty == "" {
		difficulty = domain.DifficultyMedium
	}

	bq := &domain.BankQuestion{
		ID:           uuid.New(),
		UserID:       userID,
		Subject:      req.Subject,
		Topic:        req.Topic,
		Difficulty:   difficulty,
		QuestionText: q.QuestionText,
		QuestionType: q.QuestionType,
		CodeLanguage: q.CodeLanguage,
		ImgURL:       q.ImgURL,
		AudioURL:     q.AudioURL,
		VideoURL:     q.VideoURL,
		Points:       q.Points,
	}
	for i, o := range q.Options {
		bq.Options = append(bq.Options, domain.BankQuestionOption{
			ID: uuid.New(), BankQuestionID: bq.ID, OptionText: o.OptionText, ImgURL: o.ImgURL,
			AudioURL: o.AudioURL, VideoURL: o.VideoURL, MatchKey: o.MatchKey,
			MatchTargetText: o.MatchTargetText, IsCorrect: o.IsCorrect, OrderIndex: i + 1,
		})
	}

	if err := s.bankRepo.Create(ctx, bq); err != nil {
		return nil, err
	}
	return mapBankQuestionToDTO(bq), nil
}
