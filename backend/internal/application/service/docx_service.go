package service

import (
	"context"
	"strings"

	"backend/internal/application/dto"
	"backend/internal/domain"
	"backend/internal/infrastructure/parser"
	"backend/pkg/utils"
	"github.com/google/uuid"
)

type DocxService interface {
	ImportFormFromDocx(ctx context.Context, userID uuid.UUID, fileBytes []byte) (*dto.FormResponseDTO, error)
	ImportFormFromExcel(ctx context.Context, userID uuid.UUID, fileBytes []byte) (*dto.FormResponseDTO, error)
	// FIX: sebelumnya belum ada — backend cuma bisa import Word & Excel, padahal
	// rencana produknya AI/import harus bisa baca PDF juga.
	ImportFormFromPDF(ctx context.Context, userID uuid.UUID, fileBytes []byte) (*dto.FormResponseDTO, error)
}

type docxService struct {
	docxParser   *parser.DocxParser
	excelParser  *parser.ExcelParser
	pdfParser    *parser.PDFParser
	formRepo     domain.FormRepository
	questionRepo domain.QuestionRepository
}

func NewDocxService(docxParser *parser.DocxParser, formRepo domain.FormRepository, questionRepo domain.QuestionRepository) DocxService {
	return &docxService{
		docxParser:   docxParser,
		excelParser:  parser.NewExcelParser(),
		pdfParser:    parser.NewPDFParser(),
		formRepo:     formRepo,
		questionRepo: questionRepo,
	}
}

// buildFormFromExtracted memusatkan logic yang sebelumnya diduplikasi persis sama
// di ImportFormFromDocx dan ImportFormFromExcel, supaya ImportFormFromPDF (dan
// perbaikan di masa depan) tidak perlu copy-paste ~70 baris lagi.
func importedFormTitle(title, fallback string) string {
	title = strings.TrimSpace(title)
	if title == "" {
		return fallback
	}
	const maxTitleLength = 240
	if len(title) > maxTitleLength {
		title = strings.TrimSpace(title[:maxTitleLength])
	}
	return title
}

func (s *docxService) buildFormFromExtracted(ctx context.Context, userID uuid.UUID, formID uuid.UUID, extracted *parser.ExtractedForm) (*dto.FormResponseDTO, error) {
	title := importedFormTitle(extracted.Title, "Dokumen Soal Import")
	form := &domain.Form{
		ID:          formID,
		UserID:      userID,
		Title:       title,
		Description: extracted.Description,
		Type:        domain.TypeExam,
		CustomURL:   utils.GenerateSlug(title),
		Status:      domain.StatusDraft,
	}

	if err := s.formRepo.Create(ctx, form); err != nil {
		return nil, err
	}

	if len(extracted.Questions) > 0 {
		if err := s.questionRepo.CreateBatchQuestions(ctx, extracted.Questions); err != nil {
			return nil, err
		}
	}

	defaultDuration := 60
	settings := &domain.FormSettings{
		ID:                  uuid.New(),
		FormID:              formID,
		DurationMinutes:     &defaultDuration,
		AutoActiveDays:      30,
		IsActiveImmediately: false,
		IsOneTimeSubmission: false,
		RandomizeQuestions:  false,
		RandomizeOptions:    false,
	}
	_ = s.formRepo.UpsertFormSettings(ctx, settings)
	form.FormSettings = settings

	fullForm, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}

	var qDTOs []dto.QuestionDTO
	for _, q := range fullForm.Questions {
		var optDTOs []dto.OptionDTO
		for _, opt := range q.Options {
			optDTOs = append(optDTOs, dto.OptionDTO{
				ID:         opt.ID,
				QuestionID: opt.QuestionID,
				OptionText: opt.OptionText,
				IsCorrect:  opt.IsCorrect,
				OrderIndex: opt.OrderIndex,
			})
		}
		qDTOs = append(qDTOs, dto.QuestionDTO{
			ID:           q.ID,
			FormID:       q.FormID,
			QuestionText: q.QuestionText,
			QuestionType: q.QuestionType,
			ImgURL:       q.ImgURL,
			IsAutoScored: q.IsAutoScored,
			Points:       q.Points,
			OrderIndex:   q.OrderIndex,
			IsRequired:   q.IsRequired,
			Options:      optDTOs,
		})
	}

	return &dto.FormResponseDTO{
		ID:           fullForm.ID,
		UserID:       fullForm.UserID,
		Title:        fullForm.Title,
		Description:  fullForm.Description,
		Type:         fullForm.Type,
		CustomURL:    fullForm.CustomURL,
		Status:       fullForm.Status,
		IsTemplate:   fullForm.IsTemplate,
		CreatedAt:    fullForm.CreatedAt,
		FormSettings: fullForm.FormSettings,
		Questions:    qDTOs,
	}, nil
}

func (s *docxService) ImportFormFromPDF(ctx context.Context, userID uuid.UUID, fileBytes []byte) (*dto.FormResponseDTO, error) {
	formID := uuid.New()
	extracted, err := s.pdfParser.ParsePDF(fileBytes, formID)
	if err != nil {
		return nil, err
	}
	return s.buildFormFromExtracted(ctx, userID, formID, extracted)
}

func (s *docxService) ImportFormFromDocx(ctx context.Context, userID uuid.UUID, fileBytes []byte) (*dto.FormResponseDTO, error) {
	formID := uuid.New()
	extracted, err := s.docxParser.ParseDocx(fileBytes, formID)
	if err != nil {
		return nil, err
	}

	title := importedFormTitle(extracted.Title, "Dokumen Soal Import")
	form := &domain.Form{
		ID:          formID,
		UserID:      userID,
		Title:       title,
		Description: extracted.Description,
		Type:        domain.TypeExam,
		CustomURL:   utils.GenerateSlug(title),
		Status:      domain.StatusDraft,
	}

	if err := s.formRepo.Create(ctx, form); err != nil {
		return nil, err
	}

	if len(extracted.Questions) > 0 {
		if err := s.questionRepo.CreateBatchQuestions(ctx, extracted.Questions); err != nil {
			return nil, err
		}
	}

	// Create default form settings
	defaultDuration := 60
	settings := &domain.FormSettings{
		ID:                  uuid.New(),
		FormID:              formID,
		DurationMinutes:     &defaultDuration,
		AutoActiveDays:      30,
		IsActiveImmediately: false,
		IsOneTimeSubmission: false,
		RandomizeQuestions:  false,
		RandomizeOptions:    false,
	}
	_ = s.formRepo.UpsertFormSettings(ctx, settings)
	form.FormSettings = settings

	// Retrieve complete form
	fullForm, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}

	var qDTOs []dto.QuestionDTO
	for _, q := range fullForm.Questions {
		var optDTOs []dto.OptionDTO
		for _, opt := range q.Options {
			optDTOs = append(optDTOs, dto.OptionDTO{
				ID:         opt.ID,
				QuestionID: opt.QuestionID,
				OptionText: opt.OptionText,
				IsCorrect:  opt.IsCorrect,
				OrderIndex: opt.OrderIndex,
			})
		}
		qDTOs = append(qDTOs, dto.QuestionDTO{
			ID:           q.ID,
			FormID:       q.FormID,
			QuestionText: q.QuestionText,
			QuestionType: q.QuestionType,
			ImgURL:       q.ImgURL,
			IsAutoScored: q.IsAutoScored,
			Points:       q.Points,
			OrderIndex:   q.OrderIndex,
			IsRequired:   q.IsRequired,
			Options:      optDTOs,
		})
	}

	return &dto.FormResponseDTO{
		ID:           fullForm.ID,
		UserID:       fullForm.UserID,
		Title:        fullForm.Title,
		Description:  fullForm.Description,
		Type:         fullForm.Type,
		CustomURL:    fullForm.CustomURL,
		Status:       fullForm.Status,
		IsTemplate:   fullForm.IsTemplate,
		CreatedAt:    fullForm.CreatedAt,
		FormSettings: fullForm.FormSettings,
		Questions:    qDTOs,
	}, nil
}

func (s *docxService) ImportFormFromExcel(ctx context.Context, userID uuid.UUID, fileBytes []byte) (*dto.FormResponseDTO, error) {
	formID := uuid.New()
	extracted, err := s.excelParser.ParseExcel(fileBytes, formID)
	if err != nil {
		return nil, err
	}

	title := importedFormTitle(extracted.Title, "Dokumen Soal Import")
	form := &domain.Form{
		ID:          formID,
		UserID:      userID,
		Title:       title,
		Description: extracted.Description,
		Type:        domain.TypeExam,
		CustomURL:   utils.GenerateSlug(title),
		Status:      domain.StatusDraft,
	}

	if err := s.formRepo.Create(ctx, form); err != nil {
		return nil, err
	}

	if len(extracted.Questions) > 0 {
		if err := s.questionRepo.CreateBatchQuestions(ctx, extracted.Questions); err != nil {
			return nil, err
		}
	}

	defaultDuration := 60
	settings := &domain.FormSettings{
		ID:                  uuid.New(),
		FormID:              formID,
		DurationMinutes:     &defaultDuration,
		AutoActiveDays:      30,
		IsActiveImmediately: false,
		IsOneTimeSubmission: false,
		RandomizeQuestions:  false,
		RandomizeOptions:    false,
	}
	_ = s.formRepo.UpsertFormSettings(ctx, settings)
	form.FormSettings = settings

	fullForm, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}

	var qDTOs []dto.QuestionDTO
	for _, q := range fullForm.Questions {
		var optDTOs []dto.OptionDTO
		for _, opt := range q.Options {
			optDTOs = append(optDTOs, dto.OptionDTO{
				ID:         opt.ID,
				QuestionID: opt.QuestionID,
				OptionText: opt.OptionText,
				IsCorrect:  opt.IsCorrect,
				OrderIndex: opt.OrderIndex,
			})
		}
		qDTOs = append(qDTOs, dto.QuestionDTO{
			ID:           q.ID,
			FormID:       q.FormID,
			QuestionText: q.QuestionText,
			QuestionType: q.QuestionType,
			ImgURL:       q.ImgURL,
			IsAutoScored: q.IsAutoScored,
			Points:       q.Points,
			OrderIndex:   q.OrderIndex,
			IsRequired:   q.IsRequired,
			Options:      optDTOs,
		})
	}

	return &dto.FormResponseDTO{
		ID:           fullForm.ID,
		UserID:       fullForm.UserID,
		Title:        fullForm.Title,
		Description:  fullForm.Description,
		Type:         fullForm.Type,
		CustomURL:    fullForm.CustomURL,
		Status:       fullForm.Status,
		IsTemplate:   fullForm.IsTemplate,
		CreatedAt:    fullForm.CreatedAt,
		FormSettings: fullForm.FormSettings,
		Questions:    qDTOs,
	}, nil
}
