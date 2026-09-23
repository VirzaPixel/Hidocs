package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math/rand"
	"net/url"
	"strings"
	"time"

	"backend/internal/application/dto"
	"backend/internal/domain"
	"backend/internal/infrastructure/cache"
	"backend/pkg/utils"
	"github.com/google/uuid"
)

type FormService interface {
	CreateForm(ctx context.Context, userID uuid.UUID, req dto.CreateFormRequest) (*dto.FormResponseDTO, error)
	GetFormByID(ctx context.Context, formID uuid.UUID) (*dto.FormResponseDTO, error)
	ListUserForms(ctx context.Context, userID uuid.UUID, status domain.FormStatus, category string) ([]dto.FormResponseDTO, error)
	GetUserCategories(ctx context.Context, userID uuid.UUID) ([]string, error)
	UpdateForm(ctx context.Context, userID uuid.UUID, formID uuid.UUID, req dto.UpdateFormRequest) (*dto.FormResponseDTO, error)
	DeleteForm(ctx context.Context, userID uuid.UUID, formID uuid.UUID) error
	UpdateFormSettings(ctx context.Context, userID uuid.UUID, formID uuid.UUID, req dto.UpdateFormSettingsRequest) (*domain.FormSettings, error)
	GetPublicForm(ctx context.Context, identifier string) (*dto.PublicFormDTO, error)
	GetFormQRCode(ctx context.Context, identifier string) (string, error)
	VerifyExamToken(ctx context.Context, formID uuid.UUID, req dto.VerifyExamTokenRequest) (*dto.VerifyExamTokenResponse, error)

	// FIX: Share Monitoring — tiga method baru untuk mengelola guru lain yang diberi
	// akses monitoring (read-only) ke sebuah form.
	AddCollaborator(ctx context.Context, ownerID uuid.UUID, formID uuid.UUID, email string) (*dto.CollaboratorDTO, error)
	ListCollaborators(ctx context.Context, ownerID uuid.UUID, formID uuid.UUID) ([]dto.CollaboratorDTO, error)
	RemoveCollaborator(ctx context.Context, ownerID uuid.UUID, formID uuid.UUID, collaboratorUserID uuid.UUID) error
}

type formService struct {
	formRepo     domain.FormRepository
	responseRepo domain.ResponseRepository
	redisClient  *cache.RedisClient
	// FIX: sebelumnya tidak ada base URL sama sekali, jadi GetFormQRCode generate QR
	// dari custom_url MENTAH tanpa domain (lihat fix di GetFormQRCode di bawah).
	appBaseURL string
	// FIX: dua dependency baru untuk fitur Share Monitoring.
	collabRepo domain.CollaboratorRepository
	userRepo   domain.UserRepository
}

func NewFormService(formRepo domain.FormRepository, responseRepo domain.ResponseRepository, redisClient *cache.RedisClient, appBaseURL string, collabRepo domain.CollaboratorRepository, userRepo domain.UserRepository) FormService {
	return &formService{
		formRepo:     formRepo,
		responseRepo: responseRepo,
		redisClient:  redisClient,
		appBaseURL:   appBaseURL,
		collabRepo:   collabRepo,
		userRepo:     userRepo,
	}
}

func (s *formService) CreateForm(ctx context.Context, userID uuid.UUID, req dto.CreateFormRequest) (*dto.FormResponseDTO, error) {
	customURL := req.CustomURL
	if customURL == "" {
		customURL = utils.GenerateSlug(req.Title)
	} else {
		if existing, err := s.formRepo.GetByCustomURL(ctx, customURL); err == nil && existing != nil {
			customURL = customURL + "-" + utils.RandomString(4)
		}
	}

	category := req.Category
	if category == "" {
		category = "General"
	}

	form := &domain.Form{
		ID:          uuid.New(),
		UserID:      userID,
		Title:       req.Title,
		Description: req.Description,
		Category:    category,
		Type:        req.Type,
		CustomURL:   customURL,
		Status:      domain.StatusDraft,
		IsTemplate:  req.IsTemplate,
	}

	if err := s.formRepo.Create(ctx, form); err != nil {
		return nil, err
	}

	defaultDuration := 60
	settings := &domain.FormSettings{
		ID:                  uuid.New(),
		FormID:              form.ID,
		DurationMinutes:     &defaultDuration,
		AutoActiveDays:      30,
		IsActiveImmediately: false,
		IsOneTimeSubmission: false,
		RandomizeQuestions:  false,
		RandomizeOptions:    false,
		ThemeColor:          "#4F46E5",
		FontFamily:          "Inter",
		AllowBacktrack:      true,
		ShowQuestionNumber:  true,
		FullscreenMode:      false,
		IsTokenProtected:    false,
	}
	_ = s.formRepo.UpsertFormSettings(ctx, settings)
	form.FormSettings = settings

	return s.mapFormToDTO(ctx, form), nil
}

func (s *formService) GetFormByID(ctx context.Context, formID uuid.UUID) (*dto.FormResponseDTO, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}
	return s.mapFormToDTO(ctx, form), nil
}

func (s *formService) ListUserForms(ctx context.Context, userID uuid.UUID, status domain.FormStatus, category string) ([]dto.FormResponseDTO, error) {
	formsWithCounts, err := s.formRepo.GetByUserIDWithCounts(ctx, userID, status, category)
	if err != nil {
		return nil, err
	}

	var dtos []dto.FormResponseDTO
	for _, fc := range formsWithCounts {
		formDTO := s.mapFormToDTOWithCount(ctx, &fc.Form, fc.ResponseCount)
		dtos = append(dtos, *formDTO)
	}
	return dtos, nil
}

func (s *formService) GetUserCategories(ctx context.Context, userID uuid.UUID) ([]string, error) {
	return s.formRepo.GetCategoriesByUserID(ctx, userID)
}

func (s *formService) UpdateForm(ctx context.Context, userID uuid.UUID, formID uuid.UUID, req dto.UpdateFormRequest) (*dto.FormResponseDTO, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}

	if form.UserID != userID {
		return nil, domain.ErrForbidden
	}

	form.Title = req.Title
	form.Description = req.Description
	if req.Category != "" {
		form.Category = req.Category
	}
	form.Type = req.Type
	if req.CustomURL != "" {
		form.CustomURL = req.CustomURL
	}
	form.Status = req.Status
	form.IsTemplate = req.IsTemplate

	if err := s.formRepo.Update(ctx, form); err != nil {
		return nil, err
	}

	// Invalidate cache
	if s.redisClient != nil {
		_ = s.redisClient.DeleteCache(ctx, "cache:public_form:"+form.CustomURL)
		_ = s.redisClient.DeleteCache(ctx, "cache:public_form:"+form.ID.String())
	}

	return s.mapFormToDTO(ctx, form), nil
}

func (s *formService) DeleteForm(ctx context.Context, userID uuid.UUID, formID uuid.UUID) error {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return err
	}

	if form.UserID != userID {
		return domain.ErrForbidden
	}

	// Invalidate cache
	if s.redisClient != nil {
		_ = s.redisClient.DeleteCache(ctx, "cache:public_form:"+form.CustomURL)
		_ = s.redisClient.DeleteCache(ctx, "cache:public_form:"+form.ID.String())
	}

	return s.formRepo.Delete(ctx, formID)
}

func (s *formService) UpdateFormSettings(ctx context.Context, userID uuid.UUID, formID uuid.UUID, req dto.UpdateFormSettingsRequest) (*domain.FormSettings, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}

	if form.UserID != userID {
		return nil, domain.ErrForbidden
	}

	existingSettings, _ := s.formRepo.GetFormSettingsByFormID(ctx, formID)
	settings := &domain.FormSettings{
		ID:                  uuid.New(),
		FormID:              formID,
		DurationMinutes:     req.DurationMinutes,
		AutoActiveDays:      req.AutoActiveDays,
		IsActiveImmediately: req.IsActiveImmediately,
		IsOneTimeSubmission: req.IsOneTimeSubmission,
		MaxAttempts:         0,
		RandomizeQuestions:  req.RandomizeQuestions,
		RandomizeOptions:    req.RandomizeOptions,
		StartTime:           req.StartTime,
		EndTime:             req.EndTime,
		ThemeColor:          "#4F46E5",
		FontFamily:          "Inter",
		AllowBacktrack:      true,
		ShowQuestionNumber:  true,
		FullscreenMode:      false,
		IsTokenProtected:    false,
	}

	if existingSettings != nil {
		settings.ID = existingSettings.ID
		settings.ThemeColor = existingSettings.ThemeColor
		settings.CoverImageURL = existingSettings.CoverImageURL
		settings.LogoURL = existingSettings.LogoURL
		settings.FontFamily = existingSettings.FontFamily
		settings.AllowBacktrack = existingSettings.AllowBacktrack
		settings.ShowQuestionNumber = existingSettings.ShowQuestionNumber
		settings.FullscreenMode = existingSettings.FullscreenMode
		settings.ExamToken = existingSettings.ExamToken
		settings.IsTokenProtected = existingSettings.IsTokenProtected
	}

	if req.ThemeColor != nil {
		settings.ThemeColor = *req.ThemeColor
	}
	if req.CoverImageURL != nil {
		settings.CoverImageURL = req.CoverImageURL
	}
	if req.LogoURL != nil {
		settings.LogoURL = req.LogoURL
	}
	if req.FontFamily != nil {
		settings.FontFamily = *req.FontFamily
	}
	if req.AllowBacktrack != nil {
		settings.AllowBacktrack = *req.AllowBacktrack
	}
	if req.ShowQuestionNumber != nil {
		settings.ShowQuestionNumber = *req.ShowQuestionNumber
	}
	if req.FullscreenMode != nil {
		settings.FullscreenMode = *req.FullscreenMode
	}
	if req.ExamToken != nil {
		settings.ExamToken = req.ExamToken
	}
	if req.IsTokenProtected != nil {
		settings.IsTokenProtected = *req.IsTokenProtected
	}
	if req.ResultVisibility != nil {
		settings.ResultVisibility = *req.ResultVisibility
	}
	if req.MaxAttempts != nil {
		settings.MaxAttempts = *req.MaxAttempts
	} else if existingSettings != nil {
		settings.MaxAttempts = existingSettings.MaxAttempts
	}

	if err := s.formRepo.UpsertFormSettings(ctx, settings); err != nil {
		return nil, err
	}

	// Invalidate cache
	if s.redisClient != nil {
		_ = s.redisClient.DeleteCache(ctx, "cache:public_form:"+form.CustomURL)
		_ = s.redisClient.DeleteCache(ctx, "cache:public_form:"+form.ID.String())
	}

	return settings, nil
}

func (s *formService) GetPublicForm(ctx context.Context, identifier string) (*dto.PublicFormDTO, error) {
	cacheKey := "cache:public_form:" + identifier
	if s.redisClient != nil {
		if cachedStr, err := s.redisClient.GetCache(ctx, cacheKey); err == nil && cachedStr != "" {
			var cachedDTO dto.PublicFormDTO
			if err := json.Unmarshal([]byte(cachedStr), &cachedDTO); err == nil {
				return &cachedDTO, nil
			}
		}
	}

	var form *domain.Form
	var err error

	formID, parseErr := uuid.Parse(identifier)
	if parseErr == nil {
		form, err = s.formRepo.GetByID(ctx, formID)
	} else {
		form, err = s.formRepo.GetByCustomURL(ctx, identifier)
	}

	if err != nil {
		return nil, domain.ErrFormNotFound
	}

	if form.Status == domain.StatusClosed {
		return nil, domain.ErrFormClosed
	}

	// Schedule check
	if form.FormSettings != nil {
		now := time.Now()
		if form.FormSettings.StartTime != nil && now.Before(*form.FormSettings.StartTime) {
			return nil, domain.ErrFormNotStarted
		}
		if form.FormSettings.EndTime != nil && now.After(*form.FormSettings.EndTime) {
			return nil, domain.ErrFormEnded
		}
	}

	publicDTO := &dto.PublicFormDTO{
		ID:          form.ID,
		Title:       form.Title,
		Description: form.Description,
		Category:    form.Category,
		Type:        form.Type,
		CustomURL:   form.CustomURL,
		Status:      form.Status,
		IsTemplate:  form.IsTemplate,
		Questions:   []dto.PublicQuestionDTO{},
	}

	isProtected := false
	if form.FormSettings != nil {
		isProtected = form.FormSettings.IsTokenProtected && form.FormSettings.ExamToken != nil && *form.FormSettings.ExamToken != ""
		publicDTO.FormSettings = &dto.PublicFormSettings{
			DurationMinutes:     form.FormSettings.DurationMinutes,
			AutoActiveDays:      form.FormSettings.AutoActiveDays,
			IsActiveImmediately: form.FormSettings.IsActiveImmediately,
			IsOneTimeSubmission: form.FormSettings.IsOneTimeSubmission,
			RandomizeQuestions:  form.FormSettings.RandomizeQuestions,
			RandomizeOptions:    form.FormSettings.RandomizeOptions,
			StartTime:           form.FormSettings.StartTime,
			EndTime:             form.FormSettings.EndTime,
			ThemeColor:          form.FormSettings.ThemeColor,
			CoverImageURL:       form.FormSettings.CoverImageURL,
			LogoURL:             form.FormSettings.LogoURL,
			FontFamily:          form.FormSettings.FontFamily,
			AllowBacktrack:      form.FormSettings.AllowBacktrack,
			ShowQuestionNumber:  form.FormSettings.ShowQuestionNumber,
			FullscreenMode:      form.FormSettings.FullscreenMode,
			IsTokenProtected:    isProtected,
			ResultVisibility:    form.FormSettings.ResultVisibility,
		}
	}

	// If token protected, hide questions from initial payload to prevent inspection before token is validated
	if !isProtected {
		questions := form.Questions
		if form.FormSettings != nil && form.FormSettings.RandomizeQuestions {
			rand.Seed(time.Now().UnixNano())
			rand.Shuffle(len(questions), func(i, j int) {
				questions[i], questions[j] = questions[j], questions[i]
			})
		}

		for _, q := range questions {
			options := q.Options
			if form.FormSettings != nil && form.FormSettings.RandomizeOptions {
				rand.Seed(time.Now().UnixNano())
				rand.Shuffle(len(options), func(i, j int) {
					options[i], options[j] = options[j], options[i]
				})
			}

			var publicOptions []dto.PublicOptionDTO
			for _, opt := range options {
				publicOptions = append(publicOptions, dto.PublicOptionDTO{
					ID:              opt.ID,
					OptionText:      opt.OptionText,
					ImgURL:          opt.ImgURL,
					AudioURL:        opt.AudioURL,
					VideoURL:        opt.VideoURL,
					MatchKey:        opt.MatchKey,
					MatchTargetText: opt.MatchTargetText,
					OrderIndex:      opt.OrderIndex,
				})
			}

			publicDTO.Questions = append(publicDTO.Questions, dto.PublicQuestionDTO{
				ID:           q.ID,
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
				Options:      publicOptions,
			})
		}
	}

	if s.redisClient != nil {
		if jsonBytes, err := json.Marshal(publicDTO); err == nil {
			_ = s.redisClient.SetCache(ctx, cacheKey, string(jsonBytes), 5*time.Minute)
			_ = s.redisClient.SetCache(ctx, "cache:public_form:"+publicDTO.ID.String(), string(jsonBytes), 5*time.Minute)
		}
	}

	return publicDTO, nil
}

func (s *formService) VerifyExamToken(ctx context.Context, formID uuid.UUID, req dto.VerifyExamTokenRequest) (*dto.VerifyExamTokenResponse, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, domain.ErrFormNotFound
	}

	if form.FormSettings == nil || !form.FormSettings.IsTokenProtected || form.FormSettings.ExamToken == nil {
		return nil, errors.New("this form is not protected by an exam token")
	}

	if *form.FormSettings.ExamToken != req.Token {
		return nil, errors.New("invalid exam token. Please check with your exam proctor/teacher")
	}

	// Check if student already submitted
	if form.FormSettings.IsOneTimeSubmission && s.responseRepo != nil {
		alreadySubmitted, _ := s.responseRepo.CheckUserAlreadySubmitted(ctx, formID, req.RespondentEmail)
		if alreadySubmitted {
			return nil, errors.New("you have already completed and submitted this exam")
		}
	}

	// Fetch or initialize active session
	var session *domain.FormResponse
	if s.responseRepo != nil {
		session, _ = s.responseRepo.GetActiveResponseSession(ctx, formID, req.RespondentEmail)
		if session == nil {
			session = &domain.FormResponse{
				ID:                   uuid.New(),
				FormID:               formID,
				RespondentEmail:      req.RespondentEmail,
				Status:               domain.ResponseStatusInProgress,
				CurrentQuestionIndex: 1,
				DevicePlatform:       "WEB",
				StartedAt:            time.Now(),
				LastHeartbeat:        time.Now(),
			}
			_ = s.responseRepo.CreateResponse(ctx, session)
		}
	}

	// Prepare public questions payload
	var publicQuestions []dto.PublicQuestionDTO
	for _, q := range form.Questions {
		var publicOptions []dto.PublicOptionDTO
		for _, opt := range q.Options {
			publicOptions = append(publicOptions, dto.PublicOptionDTO{
				ID:              opt.ID,
				OptionText:      opt.OptionText,
				ImgURL:          opt.ImgURL,
				AudioURL:        opt.AudioURL,
				VideoURL:        opt.VideoURL,
				MatchKey:        opt.MatchKey,
				MatchTargetText: opt.MatchTargetText,
				OrderIndex:      opt.OrderIndex,
			})
		}

		publicQuestions = append(publicQuestions, dto.PublicQuestionDTO{
			ID:           q.ID,
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
			Options:      publicOptions,
		})
	}

	publicForm := &dto.PublicFormDTO{
		ID:          form.ID,
		Title:       form.Title,
		Description: form.Description,
		Category:    form.Category,
		Type:        form.Type,
		CustomURL:   form.CustomURL,
		Status:      form.Status,
		IsTemplate:  form.IsTemplate,
		FormSettings: &dto.PublicFormSettings{
			DurationMinutes:     form.FormSettings.DurationMinutes,
			AutoActiveDays:      form.FormSettings.AutoActiveDays,
			IsActiveImmediately: form.FormSettings.IsActiveImmediately,
			IsOneTimeSubmission: form.FormSettings.IsOneTimeSubmission,
			RandomizeQuestions:  form.FormSettings.RandomizeQuestions,
			RandomizeOptions:    form.FormSettings.RandomizeOptions,
			StartTime:           form.FormSettings.StartTime,
			EndTime:             form.FormSettings.EndTime,
			ThemeColor:          form.FormSettings.ThemeColor,
			CoverImageURL:       form.FormSettings.CoverImageURL,
			LogoURL:             form.FormSettings.LogoURL,
			FontFamily:          form.FormSettings.FontFamily,
			AllowBacktrack:      form.FormSettings.AllowBacktrack,
			ShowQuestionNumber:  form.FormSettings.ShowQuestionNumber,
			FullscreenMode:      form.FormSettings.FullscreenMode,
			IsTokenProtected:    true,
		},
		Questions: publicQuestions,
	}

	var sessionQuestions []dto.SessionQuestionItemDTO
	for _, q := range form.Questions {
		answered := false
		flagged := false
		var selectedOpt *uuid.UUID
		var ansText string
		var matchPairs []dto.MatchPairItem

		if session != nil {
			for _, a := range session.Answers {
				if a.QuestionID == q.ID {
					answered = a.SelectedOptionID != nil || a.AnswerText != "" || (a.MatchPairJSON != nil && *a.MatchPairJSON != "")
					flagged = a.IsFlagged
					selectedOpt = a.SelectedOptionID
					ansText = a.AnswerText
					if a.MatchPairJSON != nil && *a.MatchPairJSON != "" {
						_ = json.Unmarshal([]byte(*a.MatchPairJSON), &matchPairs)
					}
					break
				}
			}
		}

		sessionQuestions = append(sessionQuestions, dto.SessionQuestionItemDTO{
			QuestionID:       q.ID,
			OrderIndex:       q.OrderIndex,
			IsAnswered:       answered,
			IsFlagged:        flagged,
			SelectedOptionID: selectedOpt,
			AnswerText:       ansText,
			MatchPairs:       matchPairs,
		})
	}

	sessionState := &dto.SessionStateDTO{
		ResponseID:            session.ID,
		FormID:                formID,
		Status:                string(session.Status),
		CurrentQuestionIndex:  session.CurrentQuestionIndex,
		WarningMessage:        session.WarningMessage,
		IsWarningAcknowledged: session.IsWarningAcknowledged,
		StartedAt:             session.StartedAt,
		DurationMinutes:       form.FormSettings.DurationMinutes,
		Questions:             sessionQuestions,
	}

	return &dto.VerifyExamTokenResponse{
		ResponseID:   session.ID,
		Form:         publicForm,
		SessionState: sessionState,
	}, nil
}

func (s *formService) GetFormQRCode(ctx context.Context, identifier string) (string, error) {
	form, err := s.GetPublicForm(ctx, identifier)
	if err != nil {
		return "", err
	}

	// FIX: sebelumnya cuma pakai form.CustomURL mentah (mis. "ujian-ipa-8b"), bukan
	// URL publik lengkap — jadi QR yang dipindai tidak mengarah ke mana pun yang valid.
	base := strings.TrimRight(s.appBaseURL, "/")
	publicURL := base + "/f/" + form.CustomURL
	qrURL := "https://quickchart.io/qr?text=" + url.QueryEscape(publicURL) + "&size=300"
	return qrURL, nil
}

func (s *formService) mapFormToDTO(ctx context.Context, form *domain.Form) *dto.FormResponseDTO {
	count, _ := s.formRepo.GetFormResponseCount(ctx, form.ID)
	return s.mapFormToDTOWithCount(ctx, form, count)
}

func (s *formService) mapFormToDTOWithCount(ctx context.Context, form *domain.Form, responseCount int64) *dto.FormResponseDTO {
	var questionDTOs []dto.QuestionDTO
	for _, q := range form.Questions {
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

		questionDTOs = append(questionDTOs, dto.QuestionDTO{
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
		})
	}

	return &dto.FormResponseDTO{
		ID:            form.ID,
		UserID:        form.UserID,
		Title:         form.Title,
		Description:   form.Description,
		Category:      form.Category,
		Type:          form.Type,
		CustomURL:     form.CustomURL,
		Status:        form.Status,
		IsTemplate:    form.IsTemplate,
		CreatedAt:     form.CreatedAt,
		ResponseCount: responseCount,
		FormSettings:  form.FormSettings,
		Questions:     questionDTOs,
	}
}

// FIX: Share Monitoring — implementasi 3 method baru.

func (s *formService) AddCollaborator(ctx context.Context, ownerID uuid.UUID, formID uuid.UUID, email string) (*dto.CollaboratorDTO, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}
	if form.UserID != ownerID {
		return nil, domain.ErrForbidden
	}

	target, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return nil, fmt.Errorf("guru dengan email %s tidak ditemukan", email)
	}
	if target.ID == ownerID {
		return nil, fmt.Errorf("tidak bisa menambahkan diri sendiri sebagai kolaborator")
	}

	alreadyCollab, _ := s.collabRepo.IsCollaborator(ctx, formID, target.ID)
	if alreadyCollab {
		return nil, fmt.Errorf("guru ini sudah punya akses monitoring ke form ini")
	}

	collab := &domain.FormCollaborator{
		ID:        uuid.New(),
		FormID:    formID,
		UserID:    target.ID,
		Role:      domain.CollaboratorRoleMonitor,
		InvitedBy: ownerID,
	}
	if err := s.collabRepo.Add(ctx, collab); err != nil {
		return nil, err
	}

	return &dto.CollaboratorDTO{
		UserID:    target.ID,
		Name:      target.Name,
		Email:     target.Email,
		Role:      string(collab.Role),
		CreatedAt: collab.CreatedAt,
	}, nil
}

func (s *formService) ListCollaborators(ctx context.Context, ownerID uuid.UUID, formID uuid.UUID) ([]dto.CollaboratorDTO, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}
	if form.UserID != ownerID {
		return nil, domain.ErrForbidden
	}

	items, err := s.collabRepo.ListByForm(ctx, formID)
	if err != nil {
		return nil, err
	}

	var dtos []dto.CollaboratorDTO
	for _, c := range items {
		name, email := "", ""
		if c.User != nil {
			name, email = c.User.Name, c.User.Email
		}
		dtos = append(dtos, dto.CollaboratorDTO{
			UserID:    c.UserID,
			Name:      name,
			Email:     email,
			Role:      string(c.Role),
			CreatedAt: c.CreatedAt,
		})
	}
	return dtos, nil
}

func (s *formService) RemoveCollaborator(ctx context.Context, ownerID uuid.UUID, formID uuid.UUID, collaboratorUserID uuid.UUID) error {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return err
	}
	if form.UserID != ownerID {
		return domain.ErrForbidden
	}
	return s.collabRepo.Remove(ctx, formID, collaboratorUserID)
}
