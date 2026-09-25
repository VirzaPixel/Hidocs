package repository

import (
	"context"
	"errors"
	"time"

	"backend/internal/domain"
	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type responseRepository struct {
	db *gorm.DB
}

func NewResponseRepository(db *gorm.DB) domain.ResponseRepository {
	return &responseRepository{db: db}
}

func (r *responseRepository) CreateResponse(ctx context.Context, resp *domain.FormResponse) error {
	return r.db.WithContext(ctx).Create(resp).Error
}

func (r *responseRepository) GetResponseByID(ctx context.Context, id uuid.UUID) (*domain.FormResponse, error) {
	var resp domain.FormResponse
	err := r.db.WithContext(ctx).
		Preload("Form").
		Preload("Answers").
		Preload("Answers.Question").
		Preload("Answers.Question.Options").
		Preload("Answers.SelectedOption").
		First(&resp, "id = ?", id).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrResponseNotFound
		}
		return nil, err
	}
	return &resp, nil
}

func (r *responseRepository) GetResponsesByFormID(ctx context.Context, formID uuid.UUID) ([]domain.FormResponse, error) {
	var responses []domain.FormResponse
	err := r.db.WithContext(ctx).
		Preload("Answers").
		Preload("Answers.Question").
		Preload("Answers.Question.Options").
		Preload("Answers.SelectedOption").
		Where("form_id = ?", formID).
		Order("submitted_at desc").
		Find(&responses).Error

	return responses, err
}

// FIX: baru — versi paginated dari method di atas, dipakai endpoint list responses
// supaya query tetap ringan berapa pun banyaknya siswa yang sudah submit.
func (r *responseRepository) GetResponsesByFormIDPaginated(ctx context.Context, formID uuid.UUID, pg domain.Pagination) ([]domain.FormResponse, int64, error) {
	var total int64
	if err := r.db.WithContext(ctx).
		Model(&domain.FormResponse{}).
		Where("form_id = ?", formID).
		Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var responses []domain.FormResponse
	err := r.db.WithContext(ctx).
		Preload("Answers").
		Preload("Answers.Question").
		Preload("Answers.Question.Options").
		Preload("Answers.SelectedOption").
		Where("form_id = ?", formID).
		Order("submitted_at desc").
		Limit(pg.Limit).
		Offset(pg.Offset).
		Find(&responses).Error

	return responses, total, err
}

func (r *responseRepository) GetResponsesByEmail(ctx context.Context, email string) ([]domain.FormResponse, error) {
	var responses []domain.FormResponse
	err := r.db.WithContext(ctx).
		Preload("Form").
		Preload("Answers").
		Preload("Answers.Question").
		Preload("Answers.SelectedOption").
		Where("respondent_email = ?", email).
		Order("submitted_at desc").
		Find(&responses).Error

	return responses, err
}

func (r *responseRepository) GetActiveResponseSession(ctx context.Context, formID uuid.UUID, email string) (*domain.FormResponse, error) {
	var resp domain.FormResponse
	err := r.db.WithContext(ctx).
		Preload("Answers").
		Where("form_id = ? AND respondent_email = ? AND status IN ?", formID, email, []domain.ResponseStatus{domain.ResponseStatusInProgress, domain.ResponseStatusRestarted, domain.ResponseStatusBlocked}).
		Order("started_at desc").
		First(&resp).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &resp, nil
}

func (r *responseRepository) CheckUserAlreadySubmitted(ctx context.Context, formID uuid.UUID, email string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&domain.FormResponse{}).
		Where("form_id = ? AND respondent_email = ? AND status = ?", formID, email, domain.ResponseStatusSubmitted).
		Count(&count).Error

	return count > 0, err
}

// FIX: baru — hitung total submission (bukan cuma ada/tidak) untuk batas percobaan numerik.
func (r *responseRepository) CountSubmissionsByEmail(ctx context.Context, formID uuid.UUID, email string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&domain.FormResponse{}).
		Where("form_id = ? AND respondent_email = ? AND status = ?", formID, email, domain.ResponseStatusSubmitted).
		Count(&count).Error

	return count, err
}

func (r *responseRepository) UpdateResponseGrade(ctx context.Context, responseID uuid.UUID, totalScore float64) error {
	return r.db.WithContext(ctx).
		Model(&domain.FormResponse{}).
		Where("id = ?", responseID).
		Update("total_score", totalScore).Error
}

func (r *responseRepository) UpdateAnswerScore(ctx context.Context, responseID uuid.UUID, questionID uuid.UUID, scoreGiven float64) error {
	return r.db.WithContext(ctx).
		Model(&domain.ResponseAnswer{}).
		Where("response_id = ? AND question_id = ?", responseID, questionID).
		Update("score_given", scoreGiven).Error
}

func (r *responseRepository) UpdateResponseStatus(ctx context.Context, responseID uuid.UUID, status domain.ResponseStatus) error {
	return r.db.WithContext(ctx).
		Model(&domain.FormResponse{}).
		Where("id = ?", responseID).
		Update("status", status).Error
}

func (r *responseRepository) UpsertAnswer(ctx context.Context, answer *domain.ResponseAnswer) error {
	return r.db.WithContext(ctx).
		Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "response_id"}, {Name: "question_id"}},
			DoUpdates: clause.AssignmentColumns([]string{"selected_option_id", "answer_text", "score_given", "is_flagged", "match_pair_json"}),
		}).Create(answer).Error
}

func (r *responseRepository) UpsertAnswersBatch(ctx context.Context, answers []domain.ResponseAnswer) error {
	if len(answers) == 0 {
		return nil
	}
	return r.db.WithContext(ctx).
		Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "response_id"}, {Name: "question_id"}},
			DoUpdates: clause.AssignmentColumns([]string{"selected_option_id", "answer_text", "score_given", "is_flagged", "match_pair_json"}),
		}).CreateInBatches(answers, 100).Error
}

func (r *responseRepository) UpdateTelemetry(ctx context.Context, responseID uuid.UUID, eventType string, eventMessage *string, currentQuestionIdx int, metadata *string) error {
	// 1. Create log record
	log := &domain.ProctoringLog{
		ID:           uuid.New(),
		ResponseID:   responseID,
		EventType:    eventType,
		EventMessage: eventMessage,
		Metadata:     metadata,
	}
	_ = r.db.WithContext(ctx).Create(log).Error

	// 2. Increment violation counters on FormResponse
	updates := map[string]interface{}{
		"last_heartbeat": gorm.Expr("NOW()"),
	}
	if currentQuestionIdx > 0 {
		updates["current_question_index"] = currentQuestionIdx
	}

	switch eventType {
	case "TAB_SWITCH", "APP_BACKGROUNDED":
		updates["tab_switch_count"] = gorm.Expr("tab_switch_count + 1")
	case "WINDOW_BLUR", "BLUR", "FULLSCREEN_EXIT", "SPLIT_SCREEN", "FLOATING_WINDOW":
		updates["blur_count"] = gorm.Expr("blur_count + 1")
	case "SESSION_BLOCKED":
		updates["status"] = domain.ResponseStatusBlocked
	}

	return r.db.WithContext(ctx).Model(&domain.FormResponse{}).Where("id = ?", responseID).Updates(updates).Error
}

func (r *responseRepository) GetLiveMonitoringByFormID(ctx context.Context, formID uuid.UUID) ([]domain.LiveMonitoringStudent, error) {
	type rawLiveRow struct {
		ResponseID           uuid.UUID             `gorm:"column:response_id"`
		RespondentEmail      string                `gorm:"column:respondent_email"`
		Status               domain.ResponseStatus `gorm:"column:status"`
		CurrentQuestionIndex int                   `gorm:"column:current_question_index"`
		TotalQuestions       int                   `gorm:"column:total_questions"`
		AnsweredCount        int                   `gorm:"column:answered_count"`
		FlaggedCount         int                   `gorm:"column:flagged_count"`
		TabSwitchCount       int                   `gorm:"column:tab_switch_count"`
		BlurCount            int                   `gorm:"column:blur_count"`
		DevicePlatform       string                `gorm:"column:device_platform"`
		WarningMessage       *string               `gorm:"column:warning_message"`
		StartedAt            time.Time             `gorm:"column:started_at"`
		LastHeartbeat        time.Time             `gorm:"column:last_heartbeat"`
		IsSuspicious         bool                  `gorm:"column:is_suspicious"`
	}

	var rows []rawLiveRow
	query := `
		SELECT 
			r.id AS response_id,
			r.respondent_email,
			r.status,
			r.current_question_index,
			COALESCE(q_cnt.cnt, 0) AS total_questions,
			COUNT(a.id) FILTER (WHERE a.selected_option_id IS NOT NULL OR (a.answer_text IS NOT NULL AND a.answer_text != '') OR (a.match_pair_json IS NOT NULL AND a.match_pair_json::text NOT IN ('', 'null', '[]', '{}'))) AS answered_count,
			COUNT(a.id) FILTER (WHERE a.is_flagged = TRUE) AS flagged_count,
			r.tab_switch_count,
			r.blur_count,
			r.device_platform,
			r.warning_message,
			r.started_at,
			r.last_heartbeat,
			(r.tab_switch_count >= 2 OR r.blur_count >= 3) AS is_suspicious
		FROM form_responses r
		LEFT JOIN response_answers a ON a.response_id = r.id
		LEFT JOIN (
			SELECT form_id, COUNT(*) AS cnt 
			FROM questions 
			WHERE form_id = ? 
			GROUP BY form_id
		) q_cnt ON q_cnt.form_id = r.form_id
		WHERE r.form_id = ?
		GROUP BY r.id, q_cnt.cnt
		ORDER BY r.last_heartbeat DESC
	`

	if err := r.db.WithContext(ctx).Raw(query, formID, formID).Scan(&rows).Error; err != nil {
		return nil, err
	}

	results := make([]domain.LiveMonitoringStudent, 0, len(rows))
	for _, row := range rows {
		results = append(results, domain.LiveMonitoringStudent{
			ResponseID:           row.ResponseID,
			RespondentEmail:      row.RespondentEmail,
			Status:               row.Status,
			CurrentQuestionIndex: row.CurrentQuestionIndex,
			TotalQuestions:       row.TotalQuestions,
			AnsweredCount:        row.AnsweredCount,
			FlaggedCount:         row.FlaggedCount,
			TabSwitchCount:       row.TabSwitchCount,
			BlurCount:            row.BlurCount,
			DevicePlatform:       row.DevicePlatform,
			WarningMessage:       row.WarningMessage,
			StartedAt:            row.StartedAt,
			LastHeartbeat:        row.LastHeartbeat,
			IsSuspicious:         row.IsSuspicious,
		})
	}

	return results, nil
}

func (r *responseRepository) RestartStudentResponse(ctx context.Context, responseID uuid.UUID, warningMsg string) error {
	return r.db.WithContext(ctx).Model(&domain.FormResponse{}).
		Where("id = ?", responseID).
		Updates(map[string]interface{}{
			"status":                   domain.ResponseStatusRestarted,
			"warning_message":          warningMsg,
			"is_warning_acknowledged":  false,
			"current_question_index":   1,
			"tab_switch_count":         0,
			"blur_count":               0,
			"last_heartbeat":           gorm.Expr("NOW()"),
		}).Error
}

func (r *responseRepository) AcknowledgeWarning(ctx context.Context, responseID uuid.UUID) error {
	return r.db.WithContext(ctx).Model(&domain.FormResponse{}).
		Where("id = ?", responseID).
		Updates(map[string]interface{}{
			"is_warning_acknowledged": true,
			"status":                  domain.ResponseStatusInProgress,
		}).Error
}

func (r *responseRepository) GetAnalyticsByFormID(ctx context.Context, formID uuid.UUID) (*domain.FormAnalytics, error) {
	var responses []domain.FormResponse
	err := r.db.WithContext(ctx).
		Preload("Answers").
		Where("form_id = ?", formID).
		Find(&responses).Error

	if err != nil {
		return nil, err
	}

	analytics := &domain.FormAnalytics{
		TotalResponses:    int64(len(responses)),
		QuestionBreakdown: make(map[uuid.UUID]domain.QuestionAnalytics),
	}

	if len(responses) == 0 {
		return analytics, nil
	}

	var sumScore float64
	var countWithScore float64
	var highest float64
	var lowest float64
	first := true

	for _, resp := range responses {
		if resp.TotalScore != nil {
			score := *resp.TotalScore
			sumScore += score
			countWithScore++

			if first {
				highest = score
				lowest = score
				first = false
			} else {
				if score > highest {
					highest = score
				}
				if score < lowest {
					lowest = score
				}
			}
		}
	}

	if countWithScore > 0 {
		analytics.AverageScore = sumScore / countWithScore
		analytics.HighestScore = highest
		analytics.LowestScore = lowest
	}

	// Fetch all questions for this form
	var questions []domain.Question
	r.db.WithContext(ctx).Preload("Options").Where("form_id = ?", formID).Find(&questions)

	for _, q := range questions {
		qAnalytics := domain.QuestionAnalytics{
			QuestionID:   q.ID,
			QuestionText: q.QuestionText,
			OptionCounts: make(map[string]int),
		}

		for _, opt := range q.Options {
			qAnalytics.OptionCounts[opt.ID.String()] = 0
		}

		var totalAns int64
		var correctAns int64

		for _, resp := range responses {
			for _, ans := range resp.Answers {
				if ans.QuestionID == q.ID {
					totalAns++
					if ans.SelectedOptionID != nil {
						optIDStr := ans.SelectedOptionID.String()
						qAnalytics.OptionCounts[optIDStr]++

						// Check if selected option was correct
						for _, opt := range q.Options {
							if opt.ID == *ans.SelectedOptionID && opt.IsCorrect {
								correctAns++
								break
							}
						}
					}
				}
			}
		}

		qAnalytics.TotalAnswered = totalAns
		qAnalytics.CorrectCount = correctAns
		if totalAns > 0 {
			qAnalytics.AccuracyRate = (float64(correctAns) / float64(totalAns)) * 100.0
		}

		analytics.QuestionBreakdown[q.ID] = qAnalytics
	}

	return analytics, nil
}
