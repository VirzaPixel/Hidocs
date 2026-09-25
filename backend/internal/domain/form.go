package domain

import (
	"time"

	"github.com/google/uuid"
)

type FormType string
type FormStatus string

const (
	TypeSurvey FormType = "SURVEY"
	TypeExam   FormType = "EXAM"

	StatusDraft  FormStatus = "DRAFT"
	// FIX: status baru untuk workflow Draft -> Review -> Publish. Guru menandai form
	// "siap dicek" tanpa langsung mempublikasikannya ke siswa.
	StatusReview FormStatus = "REVIEW"
	StatusActive FormStatus = "ACTIVE"
	StatusClosed FormStatus = "CLOSED"
)

type Form struct {
	ID           uuid.UUID     `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID       uuid.UUID     `gorm:"type:uuid;not null;index" json:"user_id"`
	Title        string        `gorm:"type:varchar(255);not null" json:"title"`
	Description  string        `gorm:"type:text" json:"description"`
	Category     string        `gorm:"type:varchar(100);not null;default:'General';index" json:"category"`
	Type         FormType      `gorm:"type:varchar(20);not null;default:'SURVEY'" json:"type"`
	CustomURL    string        `gorm:"type:varchar(100);uniqueIndex" json:"custom_url"`
	Status       FormStatus    `gorm:"type:varchar(20);not null;default:'DRAFT'" json:"status"`
	IsTemplate   bool          `gorm:"type:boolean;default:false" json:"is_template"`
	CreatedAt    time.Time     `gorm:"type:timestamp;not null;default:now()" json:"created_at"`
	UpdatedAt    time.Time     `gorm:"type:timestamp;not null;default:now()" json:"updated_at"`
	
	// Relations
	User         *User         `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user,omitempty"`
	FormSettings *FormSettings `gorm:"foreignKey:FormID;constraint:OnDelete:CASCADE" json:"form_settings,omitempty"`
	Questions    []Question    `gorm:"foreignKey:FormID;constraint:OnDelete:CASCADE" json:"questions,omitempty"`
}

type FormSettings struct {
	ID                  uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FormID              uuid.UUID  `gorm:"type:uuid;not null;uniqueIndex" json:"form_id"`
	DurationMinutes     *int       `gorm:"type:int" json:"duration_minutes,omitempty"`
	AutoActiveDays      int        `gorm:"type:int;default:30" json:"auto_active_days"`
	IsActiveImmediately bool       `gorm:"type:boolean;default:false" json:"is_active_immediately"`
	IsOneTimeSubmission bool       `gorm:"type:boolean;default:false" json:"is_one_time_submission"`
	// FIX: field baru — pengganti IsOneTimeSubmission yang cuma on/off. 0 = tidak
	// dibatasi. IsOneTimeSubmission TETAP ada untuk kompatibilitas mundur: kalau
	// MaxAttempts diisi 0 tapi IsOneTimeSubmission true, tetap diperlakukan sebagai
	// maks 1 percobaan (lihat response_service.go).
	MaxAttempts         int        `gorm:"type:int;default:0" json:"max_attempts"`
	RandomizeQuestions  bool       `gorm:"type:boolean;default:false" json:"randomize_questions"`
	RandomizeOptions    bool       `gorm:"type:boolean;default:false" json:"randomize_options"`
	StartTime           *time.Time `gorm:"type:timestamp" json:"start_time,omitempty"`
	EndTime             *time.Time `gorm:"type:timestamp" json:"end_time,omitempty"`
	
	// Form Customization & Themes
	ThemeColor         string     `gorm:"type:varchar(50);default:'#4F46E5'" json:"theme_color"`
	CoverImageURL      *string    `gorm:"type:varchar(255)" json:"cover_image_url,omitempty"`
	LogoURL            *string    `gorm:"type:varchar(255)" json:"logo_url,omitempty"`
	FontFamily         string     `gorm:"type:varchar(50);default:'Inter'" json:"font_family"`
	AllowBacktrack     bool       `gorm:"type:boolean;default:true" json:"allow_backtrack"`
	ShowQuestionNumber bool       `gorm:"type:boolean;default:true" json:"show_question_number"`
	FullscreenMode     bool       `gorm:"type:boolean;default:false" json:"fullscreen_mode"`
	
	// Exam Gatekeeper Token
	ExamToken          *string    `gorm:"type:varchar(50)" json:"exam_token,omitempty"`
	IsTokenProtected   bool       `gorm:"type:boolean;default:false" json:"is_token_protected"`
	ResultVisibility   string     `gorm:"type:varchar(30);default:'hidden'" json:"result_visibility"`
	AccessMode         string     `gorm:"type:varchar(20);default:'qr-only'" json:"access_mode"`
}

type FormWithCount struct {
	Form
	ResponseCount int64 `json:"response_count" gorm:"column:response_count"`
}
