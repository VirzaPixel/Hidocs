package service

import (
	"context"
	"encoding/json"
	"time"

	"backend/internal/application/dto"
	"backend/internal/domain"
	infraWS "backend/internal/infrastructure/websocket"
	"github.com/google/uuid"
)

type ResponseService interface {
	SubmitResponse(ctx context.Context, formID uuid.UUID, req dto.SubmitFormRequest) (*dto.SubmitResponseResult, error)
	AutosaveAnswer(ctx context.Context, responseID uuid.UUID, req dto.AutosaveAnswerRequest) (*dto.AutosaveResponse, error)
	SendTelemetry(ctx context.Context, responseID uuid.UUID, req dto.TelemetryEventRequest) error
	GetSessionState(ctx context.Context, responseID uuid.UUID) (*dto.SessionStateDTO, error)
	AcknowledgeWarning(ctx context.Context, responseID uuid.UUID) error
	GetLiveMonitoring(ctx context.Context, userID uuid.UUID, formID uuid.UUID) ([]dto.LiveMonitoringStudentDTO, error)
	RestartStudentSession(ctx context.Context, userID uuid.UUID, formID uuid.UUID, responseID uuid.UUID, req dto.RestartStudentSessionRequest) error
	// FIX: sekarang menerima domain.Pagination dan mengembalikan total count,
	// dipakai endpoint list responses supaya tidak menarik semua data sekaligus.
	GetFormResponses(ctx context.Context, userID uuid.UUID, formID uuid.UUID, pg domain.Pagination) ([]dto.ResponseDetailDTO, int64, error)
	GetMySubmissions(ctx context.Context, email string) ([]dto.ResponseDetailDTO, error)
	GetResponseByID(ctx context.Context, userID uuid.UUID, responseID uuid.UUID) (*dto.ResponseDetailDTO, error)
	GradeResponse(ctx context.Context, userID uuid.UUID, responseID uuid.UUID, req dto.GradeResponseRequest) error
	GetAnalytics(ctx context.Context, userID uuid.UUID, formID uuid.UUID) (*domain.FormAnalytics, error)
}

type responseService struct {
	responseRepo domain.ResponseRepository
	formRepo     domain.FormRepository
	questionRepo domain.QuestionRepository
	// FIX: baru — dipakai canAccessForMonitoring() untuk fitur Share Monitoring.
	collabRepo domain.CollaboratorRepository
}

func NewResponseService(respRepo domain.ResponseRepository, formRepo domain.FormRepository, questionRepo domain.QuestionRepository, collabRepo domain.CollaboratorRepository) ResponseService {
	return &responseService{
		responseRepo: respRepo,
		formRepo:     formRepo,
		questionRepo: questionRepo,
		collabRepo:   collabRepo,
	}
}

// FIX: baru — dipakai di GetLiveMonitoring, RestartStudentSession, GetFormResponses,
// dan GetAnalytics. Akses diberikan ke PEMILIK form ATAU guru yang di-invite lewat
// Share Monitoring (role MONITOR, read-only). GetResponseByID & GradeResponse SENGAJA
// tidak diubah — tetap owner-only, karena itu aksi grading/detail per-jawaban, bukan
// dashboard monitoring.
func (s *responseService) canAccessForMonitoring(ctx context.Context, form *domain.Form, userID uuid.UUID) bool {
	if form.UserID == userID {
		return true
	}
	if s.collabRepo == nil {
		return false
	}
	ok, _ := s.collabRepo.IsCollaborator(ctx, form.ID, userID)
	return ok
}

func (s *responseService) SubmitResponse(ctx context.Context, formID uuid.UUID, req dto.SubmitFormRequest) (*dto.SubmitResponseResult, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, domain.ErrFormNotFound
	}

	if form.Status == domain.StatusClosed {
		return nil, domain.ErrFormClosed
	}

	// Schedule validation
	if form.FormSettings != nil {
		now := time.Now()
		if form.FormSettings.StartTime != nil && now.Before(*form.FormSettings.StartTime) {
			return nil, domain.ErrFormNotStarted
		}
		if form.FormSettings.EndTime != nil && now.After(*form.FormSettings.EndTime) {
			return nil, domain.ErrFormEnded
		}
	}

	// FIX: sebelumnya cuma cek IsOneTimeSubmission (on/off). Sekarang mendukung
	// MaxAttempts numerik (mis. maks 2x), dengan IsOneTimeSubmission tetap dihormati
	// untuk form lama yang belum pernah set MaxAttempts (diperlakukan sebagai maks 1x).
	if form.FormSettings != nil {
		maxAttempts := form.FormSettings.MaxAttempts
		if maxAttempts <= 0 && form.FormSettings.IsOneTimeSubmission {
			maxAttempts = 1
		}
		if maxAttempts > 0 {
			count, _ := s.responseRepo.CountSubmissionsByEmail(ctx, formID, req.RespondentEmail)
			if count >= int64(maxAttempts) {
				return nil, domain.ErrAlreadySubmitted
			}
		}
	}

	responseID := uuid.New()
	if req.ResponseID != nil && *req.ResponseID != uuid.Nil {
		responseID = *req.ResponseID
	}

	var totalScore float64 = 0
	var answers []domain.ResponseAnswer

	// Map existing questions & options for auto-grading
	questionsMap := make(map[uuid.UUID]domain.Question)
	for _, q := range form.Questions {
		questionsMap[q.ID] = q
	}

	// Kumpulkan seluruh jawaban terpilih per soal lebih dulu. Soal CHECKBOXES
	// (kotak centang) dikirim oleh klien sebagai SATU BARIS jawaban per opsi
	// yang dipilih, jadi penilaiannya harus memakai seluruh pilihan sekaligus —
	// sama seperti Google Forms (all-or-nothing: semua kunci benar & tanpa
	// pilihan salah baru dapat penuh).
	selectedByQuestion := make(map[uuid.UUID]map[uuid.UUID]bool)
	for _, ansReq := range req.Answers {
		if ansReq.SelectedOptionID == nil {
			continue
		}
		if selectedByQuestion[ansReq.QuestionID] == nil {
			selectedByQuestion[ansReq.QuestionID] = make(map[uuid.UUID]bool)
		}
		selectedByQuestion[ansReq.QuestionID][*ansReq.SelectedOptionID] = true
	}
	// Mencegah poin soal yang sama dihitung lebih dari sekali.
	gradedQuestions := make(map[uuid.UUID]bool)

	for _, ansReq := range req.Answers {
		q, exists := questionsMap[ansReq.QuestionID]
		if !exists {
			continue
		}

		var scoreGiven float64 = 0
		var matchPairJSON *string
		if len(ansReq.MatchPairs) > 0 {
			if b, err := json.Marshal(ansReq.MatchPairs); err == nil {
				s := string(b)
				matchPairJSON = &s
			}
		}

		ans := domain.ResponseAnswer{
			ID:               uuid.New(),
			ResponseID:       responseID,
			QuestionID:       ansReq.QuestionID,
			SelectedOptionID: ansReq.SelectedOptionID,
			AnswerText:       ansReq.AnswerText,
			IsFlagged:        ansReq.IsFlagged,
			MatchPairJSON:    matchPairJSON,
		}

		// 1. Auto-Grading for Multiple Choice / Dropdown / YesNo
		if q.IsAutoScored && (q.QuestionType == domain.TypeMultipleChoice || q.QuestionType == domain.TypeDropdown || q.QuestionType == domain.TypeYesNo) && ansReq.SelectedOptionID != nil {
			for _, opt := range q.Options {
				if opt.ID == *ansReq.SelectedOptionID && opt.IsCorrect {
					scoreGiven = float64(q.Points)
					totalScore += scoreGiven
					break
				}
			}
		}

		// 1b. Auto-Grading for CHECKBOXES (multi jawaban, all-or-nothing ala
		// Google Forms). Hanya baris PERTAMA dari soal tersebut yang membawa
		// poin supaya jawaban multi-baris tidak dihitung berkali-kali.
		if q.IsAutoScored && q.QuestionType == domain.TypeCheckboxes && !gradedQuestions[q.ID] {
			gradedQuestions[q.ID] = true

			selected := selectedByQuestion[q.ID]
			correctIDs := make(map[uuid.UUID]bool, len(q.Options))
			for _, opt := range q.Options {
				if opt.IsCorrect {
					correctIDs[opt.ID] = true
				}
			}

			if len(correctIDs) > 0 && len(selected) == len(correctIDs) {
				exactMatch := true
				for id := range selected {
					if !correctIDs[id] {
						exactMatch = false
						break
					}
				}
				if exactMatch {
					scoreGiven = float64(q.Points)
					totalScore += scoreGiven
				}
			}
		}

		// 2. Auto-Grading for MATCHING Question Type (Proportional scoring)
		if q.IsAutoScored && q.QuestionType == domain.TypeMatching && len(ansReq.MatchPairs) > 0 {
			correctMatches := 0
			totalPairs := 0
			for _, opt := range q.Options {
				if opt.MatchKey != nil && opt.MatchTargetText != nil && *opt.MatchKey != "" {
					totalPairs++
					for _, pair := range ansReq.MatchPairs {
						if pair.MatchKey == *opt.MatchKey && pair.MatchTargetText == *opt.MatchTargetText {
							correctMatches++
							break
						}
					}
				}
			}
			if totalPairs > 0 {
				ratio := float64(correctMatches) / float64(totalPairs)
				scoreGiven = ratio * float64(q.Points)
				totalScore += scoreGiven
			}
		}

		ans.ScoreGiven = &scoreGiven
		answers = append(answers, ans)
	}

	platform := req.DevicePlatform
	if platform == "" {
		platform = "WEB"
	}

	now := time.Now()
	// Update existing session or create fresh response
	formResponse := &domain.FormResponse{
		ID:              responseID,
		FormID:          formID,
		RespondentEmail: req.RespondentEmail,
		Status:          domain.ResponseStatusSubmitted,
		DevicePlatform:  platform,
		TotalScore:      &totalScore,
		IsAutoSubmitted: req.IsAutoSubmitted,
		StartedAt:       now,
		LastHeartbeat:   now,
		SubmittedAt:     now,
	}

	if req.ResponseID != nil && *req.ResponseID != uuid.Nil {
		_ = s.responseRepo.UpdateResponseGrade(ctx, responseID, totalScore)
		_ = s.responseRepo.UpdateResponseStatus(ctx, responseID, domain.ResponseStatusSubmitted)
	} else {
		if err := s.responseRepo.CreateResponse(ctx, formResponse); err != nil {
			return nil, err
		}
	}

	// Bulk upsert all answers in a single high-performance query AFTER formResponse exists
	if len(answers) > 0 {
		_ = s.responseRepo.UpsertAnswersBatch(ctx, answers)
	}

	infraWS.GlobalHub.BroadcastToForm(formID, "STUDENT_SUBMIT", map[string]any{
		"response_id":      responseID,
		"respondent_email": req.RespondentEmail,
		"status":           domain.ResponseStatusSubmitted,
		"total_score":      totalScore,
		"submitted_at":     formResponse.SubmittedAt,
	})

	return &dto.SubmitResponseResult{
		ResponseID:      responseID,
		TotalScore:      totalScore,
		IsAutoSubmitted: req.IsAutoSubmitted,
		SubmittedAt:     formResponse.SubmittedAt,
		Message:         "Response submitted successfully",
	}, nil
}

func (s *responseService) AutosaveAnswer(ctx context.Context, responseID uuid.UUID, req dto.AutosaveAnswerRequest) (*dto.AutosaveResponse, error) {
	var matchPairJSON *string
	if len(req.MatchPairs) > 0 {
		if b, err := json.Marshal(req.MatchPairs); err == nil {
			str := string(b)
			matchPairJSON = &str
		}
	}

	answer := &domain.ResponseAnswer{
		ID:               uuid.New(),
		ResponseID:       responseID,
		QuestionID:       req.QuestionID,
		SelectedOptionID: req.SelectedOptionID,
		AnswerText:       req.AnswerText,
		IsFlagged:        req.IsFlagged,
		MatchPairJSON:    matchPairJSON,
	}

	if err := s.responseRepo.UpsertAnswer(ctx, answer); err != nil {
		return nil, err
	}

	if resp, err := s.responseRepo.GetResponseByID(ctx, responseID); err == nil && resp != nil {
		infraWS.GlobalHub.BroadcastToForm(resp.FormID, "STUDENT_UPDATE", map[string]any{
			"response_id": responseID,
			"question_id": req.QuestionID,
			"is_flagged":  req.IsFlagged,
		})
	}

	return &dto.AutosaveResponse{
		Success:    true,
		Message:    "Answer autosaved successfully",
		QuestionID: req.QuestionID,
		IsFlagged:  req.IsFlagged,
		SavedAt:    time.Now(),
	}, nil
}

func (s *responseService) SendTelemetry(ctx context.Context, responseID uuid.UUID, req dto.TelemetryEventRequest) error {
	err := s.responseRepo.UpdateTelemetry(ctx, responseID, req.EventType, req.EventMessage, req.CurrentQuestionIndex, req.Metadata)
	if err == nil {
		if resp, err2 := s.responseRepo.GetResponseByID(ctx, responseID); err2 == nil && resp != nil {
			infraWS.GlobalHub.BroadcastToForm(resp.FormID, "TELEMETRY", map[string]any{
				"response_id":            responseID,
				"event_type":             req.EventType,
				"event_message":          req.EventMessage,
				"current_question_index": req.CurrentQuestionIndex,
			})
		}
	}
	return err
}

func (s *responseService) GetSessionState(ctx context.Context, responseID uuid.UUID) (*dto.SessionStateDTO, error) {
	resp, err := s.responseRepo.GetResponseByID(ctx, responseID)
	if err != nil {
		return nil, err
	}

	form, err := s.formRepo.GetByID(ctx, resp.FormID)
	if err != nil {
		return nil, err
	}

	var questions []dto.SessionQuestionItemDTO
	for _, q := range form.Questions {
		answered := false
		flagged := false
		var selectedOpt *uuid.UUID
		var ansText string
		var matchPairs []dto.MatchPairItem

		for _, a := range resp.Answers {
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

		questions = append(questions, dto.SessionQuestionItemDTO{
			QuestionID:       q.ID,
			OrderIndex:       q.OrderIndex,
			IsAnswered:       answered,
			IsFlagged:        flagged,
			SelectedOptionID: selectedOpt,
			AnswerText:       ansText,
			MatchPairs:       matchPairs,
		})
	}

	var duration *int
	if form.FormSettings != nil {
		duration = form.FormSettings.DurationMinutes
	}

	return &dto.SessionStateDTO{
		ResponseID:            resp.ID,
		FormID:                resp.FormID,
		Status:                string(resp.Status),
		CurrentQuestionIndex:  resp.CurrentQuestionIndex,
		WarningMessage:        resp.WarningMessage,
		IsWarningAcknowledged: resp.IsWarningAcknowledged,
		StartedAt:             resp.StartedAt,
		DurationMinutes:       duration,
		Questions:             questions,
	}, nil
}

func (s *responseService) AcknowledgeWarning(ctx context.Context, responseID uuid.UUID) error {
	return s.responseRepo.AcknowledgeWarning(ctx, responseID)
}

func (s *responseService) GetLiveMonitoring(ctx context.Context, userID uuid.UUID, formID uuid.UUID) ([]dto.LiveMonitoringStudentDTO, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}

	if !s.canAccessForMonitoring(ctx, form, userID) {
		return nil, domain.ErrForbidden
	}

	students, err := s.responseRepo.GetLiveMonitoringByFormID(ctx, formID)
	if err != nil {
		return nil, err
	}

	var dtos []dto.LiveMonitoringStudentDTO
	for _, st := range students {
		dtos = append(dtos, dto.LiveMonitoringStudentDTO{
			ResponseID:           st.ResponseID,
			RespondentEmail:      st.RespondentEmail,
			Status:               string(st.Status),
			CurrentQuestionIndex: st.CurrentQuestionIndex,
			TotalQuestions:       st.TotalQuestions,
			AnsweredCount:        st.AnsweredCount,
			FlaggedCount:         st.FlaggedCount,
			TabSwitchCount:       st.TabSwitchCount,
			BlurCount:            st.BlurCount,
			DevicePlatform:       st.DevicePlatform,
			WarningMessage:       st.WarningMessage,
			StartedAt:            st.StartedAt,
			LastHeartbeat:        st.LastHeartbeat,
			IsSuspicious:         st.IsSuspicious,
		})
	}

	return dtos, nil
}

func (s *responseService) RestartStudentSession(ctx context.Context, userID uuid.UUID, formID uuid.UUID, responseID uuid.UUID, req dto.RestartStudentSessionRequest) error {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return err
	}

	if !s.canAccessForMonitoring(ctx, form, userID) {
		return domain.ErrForbidden
	}

	err = s.responseRepo.RestartStudentResponse(ctx, responseID, req.WarningMessage)
	if err == nil {
		infraWS.GlobalHub.BroadcastToForm(formID, "STUDENT_RESTART", map[string]any{
			"response_id":     responseID,
			"warning_message": req.WarningMessage,
			"status":          domain.ResponseStatusRestarted,
		})
	}
	return err
}

func (s *responseService) GetFormResponses(ctx context.Context, userID uuid.UUID, formID uuid.UUID, pg domain.Pagination) ([]dto.ResponseDetailDTO, int64, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, 0, err
	}

	if !s.canAccessForMonitoring(ctx, form, userID) {
		return nil, 0, domain.ErrForbidden
	}

	responses, total, err := s.responseRepo.GetResponsesByFormIDPaginated(ctx, formID, pg)
	if err != nil {
		return nil, 0, err
	}

	var dtos []dto.ResponseDetailDTO
	for _, r := range responses {
		dtos = append(dtos, *s.mapResponseToDTO(&r))
	}
	return dtos, total, nil
}

func (s *responseService) GetMySubmissions(ctx context.Context, email string) ([]dto.ResponseDetailDTO, error) {
	responses, err := s.responseRepo.GetResponsesByEmail(ctx, email)
	if err != nil {
		return nil, err
	}

	var dtos []dto.ResponseDetailDTO
	for _, r := range responses {
		dtos = append(dtos, *s.mapResponseToDTO(&r))
	}
	return dtos, nil
}

func (s *responseService) GetResponseByID(ctx context.Context, userID uuid.UUID, responseID uuid.UUID) (*dto.ResponseDetailDTO, error) {
	resp, err := s.responseRepo.GetResponseByID(ctx, responseID)
	if err != nil {
		return nil, err
	}

	if resp.Form != nil && resp.Form.UserID != userID {
		return nil, domain.ErrForbidden
	}

	return s.mapResponseToDTO(resp), nil
}

func (s *responseService) GradeResponse(ctx context.Context, userID uuid.UUID, responseID uuid.UUID, req dto.GradeResponseRequest) error {
	resp, err := s.responseRepo.GetResponseByID(ctx, responseID)
	if err != nil {
		return err
	}

	if resp.Form != nil && resp.Form.UserID != userID {
		return domain.ErrForbidden
	}

	// Per-question essay scores (bulk grading)
	if len(req.EssayScores) > 0 {
		for qidStr, score := range req.EssayScores {
			qid, err := uuid.Parse(qidStr)
			if err != nil {
				continue
			}
			if err := s.responseRepo.UpdateAnswerScore(ctx, responseID, qid, score); err != nil {
				continue
			}
		}
	}

	return s.responseRepo.UpdateResponseGrade(ctx, responseID, req.TotalScore)
}

func (s *responseService) GetAnalytics(ctx context.Context, userID uuid.UUID, formID uuid.UUID) (*domain.FormAnalytics, error) {
	form, err := s.formRepo.GetByID(ctx, formID)
	if err != nil {
		return nil, err
	}

	if !s.canAccessForMonitoring(ctx, form, userID) {
		return nil, domain.ErrForbidden
	}

	return s.responseRepo.GetAnalyticsByFormID(ctx, formID)
}

func (s *responseService) mapResponseToDTO(resp *domain.FormResponse) *dto.ResponseDetailDTO {
	var answers []dto.AnswerDetailDTO
	for _, a := range resp.Answers {
		detail := dto.AnswerDetailDTO{
			ID:                 a.ID,
			QuestionID:         a.QuestionID,
			SelectedOptionID:   a.SelectedOptionID,
			AnswerText:         a.AnswerText,
			IsFlagged:          a.IsFlagged,
			MatchPairJSON:      a.MatchPairJSON,
			ScoreGiven:         a.ScoreGiven,
		}

		if a.Question != nil {
			detail.QuestionText = a.Question.QuestionText
		}
		if a.SelectedOption != nil {
			detail.SelectedOption = a.SelectedOption.OptionText
			detail.SelectedOptionText = a.SelectedOption.OptionText
			isCorrect := a.SelectedOption.IsCorrect
			detail.IsCorrect = &isCorrect
			if isCorrect {
				if a.Question != nil && a.Question.Points > 0 {
					detail.PointsEarned = float64(a.Question.Points)
				} else if a.ScoreGiven != nil {
					detail.PointsEarned = *a.ScoreGiven
				}
			} else {
				detail.PointsEarned = 0
			}
		} else if a.ScoreGiven != nil {
			detail.PointsEarned = *a.ScoreGiven
			if a.Question != nil && a.Question.Points > 0 {
				isCorrect := *a.ScoreGiven >= float64(a.Question.Points)
				detail.IsCorrect = &isCorrect
			}
		}

		answers = append(answers, detail)
	}

	return &dto.ResponseDetailDTO{
		ID:              resp.ID,
		FormID:          resp.FormID,
		RespondentEmail: resp.RespondentEmail,
		Status:          string(resp.Status),
		TotalScore:      resp.TotalScore,
		IsAutoSubmitted: resp.IsAutoSubmitted,
		DevicePlatform:  resp.DevicePlatform,
		StartedAt:       resp.StartedAt,
		SubmittedAt:     resp.SubmittedAt,
		Answers:         answers,
	}
}
