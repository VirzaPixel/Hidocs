package dto

import (
	"time"

	"backend/internal/domain"
	"github.com/google/uuid"
)

type CreateFormRequest struct {
	Title       string          `json:"title" binding:"required,min=2,max=255"`
	Description string          `json:"description"`
	Category    string          `json:"category"`
	Type        domain.FormType `json:"type" binding:"required,oneof=SURVEY EXAM"`
	CustomURL   string          `json:"custom_url"`
	IsTemplate  bool            `json:"is_template"`
}

type UpdateFormRequest struct {
	Title       string            `json:"title" binding:"required,min=2,max=255"`
	Description string            `json:"description"`
	Category    string            `json:"category"`
	Type        domain.FormType   `json:"type" binding:"required,oneof=SURVEY EXAM"`
	CustomURL   string            `json:"custom_url"`
	Status      domain.FormStatus `json:"status" binding:"required,oneof=DRAFT REVIEW ACTIVE CLOSED"`
	IsTemplate  bool              `json:"is_template"`
}

type UpdateFormSettingsRequest struct {
	DurationMinutes     *int       `json:"duration_minutes"`
	AutoActiveDays      int        `json:"auto_active_days"`
	IsActiveImmediately bool       `json:"is_active_immediately"`
	IsOneTimeSubmission bool       `json:"is_one_time_submission"`
	MaxAttempts         *int       `json:"max_attempts"`
	RandomizeQuestions  bool       `json:"randomize_questions"`
	RandomizeOptions    bool       `json:"randomize_options"`
	StartTime           *time.Time `json:"start_time"`
	EndTime             *time.Time `json:"end_time"`
	
	// Theme & Customization
	ThemeColor         *string    `json:"theme_color"`
	CoverImageURL      *string    `json:"cover_image_url"`
	LogoURL            *string    `json:"logo_url"`
	FontFamily         *string    `json:"font_family"`
	AllowBacktrack     *bool      `json:"allow_backtrack"`
	ShowQuestionNumber *bool      `json:"show_question_number"`
	FullscreenMode     *bool      `json:"fullscreen_mode"`
	
	// Exam Token / Passcode
	ExamToken          *string    `json:"exam_token"`
	IsTokenProtected   *bool      `json:"is_token_protected"`
	ResultVisibility   *string    `json:"result_visibility"`
	IdentityFieldsJSON *string    `json:"identity_fields_json"`
}

type FormResponseDTO struct {
	ID            uuid.UUID            `json:"id"`
	UserID        uuid.UUID            `json:"user_id"`
	Title         string               `json:"title"`
	Description   string               `json:"description"`
	Category      string               `json:"category"`
	Type          domain.FormType      `json:"type"`
	CustomURL     string               `json:"custom_url"`
	Status        domain.FormStatus    `json:"status"`
	IsTemplate    bool                 `json:"is_template"`
	CreatedAt     time.Time            `json:"created_at"`
	ResponseCount int64                `json:"response_count"`
	FormSettings  *domain.FormSettings `json:"form_settings,omitempty"`
	Questions     []QuestionDTO        `json:"questions,omitempty"`
}

type PublicFormDTO struct {
	ID           uuid.UUID           `json:"id"`
	Title        string              `json:"title"`
	Description  string              `json:"description"`
	Category     string              `json:"category"`
	Type         domain.FormType     `json:"type"`
	CustomURL    string              `json:"custom_url"`
	Status       domain.FormStatus   `json:"status"`
	IsTemplate   bool                `json:"is_template"`
	FormSettings *PublicFormSettings `json:"form_settings,omitempty"`
	Questions    []PublicQuestionDTO `json:"questions"`
}

type PublicFormSettings struct {
	DurationMinutes     *int       `json:"duration_minutes,omitempty"`
	AutoActiveDays      int        `json:"auto_active_days"`
	IsActiveImmediately bool       `json:"is_active_immediately"`
	IsOneTimeSubmission bool       `json:"is_one_time_submission"`
	RandomizeQuestions  bool       `json:"randomize_questions"`
	RandomizeOptions    bool       `json:"randomize_options"`
	StartTime           *time.Time `json:"start_time,omitempty"`
	EndTime             *time.Time `json:"end_time,omitempty"`
	ThemeColor          string     `json:"theme_color"`
	CoverImageURL       *string    `json:"cover_image_url,omitempty"`
	LogoURL             *string    `json:"logo_url,omitempty"`
	FontFamily          string     `json:"font_family"`
	AllowBacktrack      bool       `json:"allow_backtrack"`
	ShowQuestionNumber  bool       `json:"show_question_number"`
	FullscreenMode      bool       `json:"fullscreen_mode"`
	IsTokenProtected    bool       `json:"is_token_protected"`
	// Hasil penilaian: "hidden" | "result_only" | "result_and_score".
	// Tanpa field ini responden tidak pernah tahu hasil/form disembunyikan.
	ResultVisibility    string     `json:"result_visibility"`
	IdentityFieldsJSON  *string    `json:"identity_fields_json,omitempty"`
}

type PublicQuestionDTO struct {
	ID           uuid.UUID           `json:"id"`
	QuestionText string              `json:"question_text"`
	QuestionType domain.QuestionType `json:"question_type"`
	CodeLanguage string              `json:"code_language,omitempty"`
	ImgURL       string              `json:"img_url,omitempty"`
	AudioURL     *string             `json:"audio_url,omitempty"`
	VideoURL     *string             `json:"video_url,omitempty"`
	IsAutoScored bool                `json:"is_auto_scored"`
	Points       int                 `json:"points"`
	OrderIndex   int                 `json:"order_index"`
	IsRequired   bool                `json:"is_required"`
	Options      []PublicOptionDTO   `json:"options,omitempty"`
}

type PublicOptionDTO struct {
	ID              uuid.UUID `json:"id"`
	OptionText      string    `json:"option_text"`
	ImgURL          *string   `json:"img_url,omitempty"`
	AudioURL        *string   `json:"audio_url,omitempty"`
	VideoURL        *string   `json:"video_url,omitempty"`
	MatchKey        *string   `json:"match_key,omitempty"`
	MatchTargetText *string   `json:"match_target_text,omitempty"`
	OrderIndex      int       `json:"order_index"`
}

type VerifyExamTokenRequest struct {
	Token           string `json:"token"`
	RespondentEmail string `json:"respondent_email" binding:"omitempty"`
}

type VerifyExamTokenResponse struct {
	ResponseID   uuid.UUID      `json:"response_id"`
	Form         *PublicFormDTO `json:"form"`
	SessionState *SessionStateDTO `json:"session_state"`
}
