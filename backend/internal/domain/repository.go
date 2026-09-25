package domain

import (
	"context"

	"github.com/google/uuid"
)

type UserRepository interface {
	Create(ctx context.Context, user *User) error
	CreateBatch(ctx context.Context, users []User) error
	GetByID(ctx context.Context, id uuid.UUID) (*User, error)
	GetByEmail(ctx context.Context, email string) (*User, error)
	GetExistingEmails(ctx context.Context, emails []string) (map[string]bool, error)
	Update(ctx context.Context, user *User) error
	Delete(ctx context.Context, id uuid.UUID) error
	ListAll(ctx context.Context, offset, limit int) ([]User, int64, error)
	
	// Password resets
	CreatePasswordReset(ctx context.Context, reset *PasswordReset) error
	GetPasswordResetByToken(ctx context.Context, token string) (*PasswordReset, error)
	DeletePasswordReset(ctx context.Context, email string) error
}

type FormRepository interface {
	Create(ctx context.Context, form *Form) error
	GetByID(ctx context.Context, id uuid.UUID) (*Form, error)
	GetByCustomURL(ctx context.Context, customURL string) (*Form, error)
	GetByUserID(ctx context.Context, userID uuid.UUID, status FormStatus, category string) ([]Form, error)
	GetByUserIDWithCounts(ctx context.Context, userID uuid.UUID, status FormStatus, category string) ([]FormWithCount, error)
	GetCategoriesByUserID(ctx context.Context, userID uuid.UUID) ([]string, error)
	Update(ctx context.Context, form *Form) error
	Delete(ctx context.Context, id uuid.UUID) error
	
	// Form Settings
	UpsertFormSettings(ctx context.Context, settings *FormSettings) error
	GetFormSettingsByFormID(ctx context.Context, formID uuid.UUID) (*FormSettings, error)
	
	// Stats
	GetFormResponseCount(ctx context.Context, formID uuid.UUID) (int64, error)
}

type QuestionRepository interface {
	CreateQuestion(ctx context.Context, q *Question) error
	CreateBatchQuestions(ctx context.Context, questions []Question) error
	GetQuestionByID(ctx context.Context, id uuid.UUID) (*Question, error)
	GetQuestionsByFormID(ctx context.Context, formID uuid.UUID) ([]Question, error)
	UpdateQuestion(ctx context.Context, q *Question) error
	DeleteQuestion(ctx context.Context, id uuid.UUID) error
	
	// Options
	CreateOption(ctx context.Context, opt *QuestionOption) error
	UpdateOption(ctx context.Context, opt *QuestionOption) error
	DeleteOption(ctx context.Context, id uuid.UUID) error
	GetOptionByID(ctx context.Context, id uuid.UUID) (*QuestionOption, error)
}

type ResponseRepository interface {
	CreateResponse(ctx context.Context, resp *FormResponse) error
	GetResponseByID(ctx context.Context, id uuid.UUID) (*FormResponse, error)
	GetResponsesByFormID(ctx context.Context, formID uuid.UUID) ([]FormResponse, error)
	// FIX: baru ditambahkan untuk endpoint list responses (GET /forms/:id/responses),
	// supaya tidak menarik SEMUA response sekaligus saat form punya 800-1000 pengerjaan.
	// GetResponsesByFormID (di atas) TETAP dipakai apa adanya oleh fitur export,
	// karena export memang butuh data lengkap, bukan sebagian halaman.
	GetResponsesByFormIDPaginated(ctx context.Context, formID uuid.UUID, pg Pagination) ([]FormResponse, int64, error)
	GetResponsesByEmail(ctx context.Context, email string) ([]FormResponse, error)
	GetActiveResponseSession(ctx context.Context, formID uuid.UUID, email string) (*FormResponse, error)
	CheckUserAlreadySubmitted(ctx context.Context, formID uuid.UUID, email string) (bool, error)
	// FIX: baru — untuk batas percobaan NUMERIK (max_attempts), pengganti
	// CheckUserAlreadySubmitted yang cuma bisa on/off (1x atau tidak dibatasi).
	CountSubmissionsByEmail(ctx context.Context, formID uuid.UUID, email string) (int64, error)
	UpdateResponseGrade(ctx context.Context, responseID uuid.UUID, totalScore float64) error
	UpdateAnswerScore(ctx context.Context, responseID uuid.UUID, questionID uuid.UUID, scoreGiven float64) error
	UpdateResponseStatus(ctx context.Context, responseID uuid.UUID, status ResponseStatus) error
	
	// Autosave & Incremental Answers
	UpsertAnswer(ctx context.Context, answer *ResponseAnswer) error
	UpsertAnswersBatch(ctx context.Context, answers []ResponseAnswer) error
	
	// Live Proctoring, Telemetry & Creator Restart
	UpdateTelemetry(ctx context.Context, responseID uuid.UUID, eventType string, eventMessage *string, currentQuestionIdx int, metadata *string) error
	GetLiveMonitoringByFormID(ctx context.Context, formID uuid.UUID) ([]LiveMonitoringStudent, error)
	RestartStudentResponse(ctx context.Context, responseID uuid.UUID, warningMsg string) error
	AcknowledgeWarning(ctx context.Context, responseID uuid.UUID) error
	
	// Analytics
	GetAnalyticsByFormID(ctx context.Context, formID uuid.UUID) (*FormAnalytics, error)
}

type FormAnalytics struct {
	TotalResponses    int64                           `json:"total_responses"`
	AverageScore      float64                         `json:"average_score"`
	HighestScore      float64                         `json:"highest_score"`
	LowestScore       float64                         `json:"lowest_score"`
	QuestionBreakdown map[uuid.UUID]QuestionAnalytics `json:"question_breakdown"`
}

type QuestionAnalytics struct {
	QuestionID     uuid.UUID      `json:"question_id"`
	QuestionText   string         `json:"question_text"`
	TotalAnswered  int64          `json:"total_answered"`
	CorrectCount   int64          `json:"correct_count"`
	AccuracyRate   float64        `json:"accuracy_rate"`
	OptionCounts   map[string]int `json:"option_counts"` // Option ID -> count
}

type AdminRepository interface {
	GetDashboardStats(ctx context.Context) (*AdminStats, error)
	ListCreators(ctx context.Context) ([]User, error)
	ListAdmins(ctx context.Context) ([]User, error)
	UpdateCreatorStatus(ctx context.Context, creatorID uuid.UUID, isActive bool) error
	ListAllForms(ctx context.Context) ([]Form, error)
	DeleteForm(ctx context.Context, formID uuid.UUID) error
}

type AdminStats struct {
	TotalUsers     int64 `json:"total_users"`
	TotalCreators  int64 `json:"total_creators"`
	TotalForms     int64 `json:"total_forms"`
	ActiveExams    int64 `json:"active_exams"`
	TotalResponses int64 `json:"total_responses"`
}
