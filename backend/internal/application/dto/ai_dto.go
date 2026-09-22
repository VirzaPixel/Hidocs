package dto

import (
	"backend/internal/domain"
	"github.com/google/uuid"
)

// Attachment yang diupload user lebih dulu via /questions/upload-* lalu URL-nya
// diteruskan ke AI agar disematkan ke soal / opsi jawaban.
type AIAttachment struct {
	MediaType   string `json:"media_type" binding:"required,oneof=IMAGE AUDIO VIDEO"`
	URL         string `json:"url" binding:"required"`
	Description string `json:"description"`
	// Target opsional: "QUESTION" atau "OPTION". Kosong = AI yang menentukan.
	Target string `json:"target"`
}

type AIQuestionSpec struct {
	QuestionType domain.QuestionType `json:"question_type" binding:"required"`
	Count        int                 `json:"count" binding:"required,gte=1,lte=50"`
	PointsEach   int                 `json:"points_each"`
	OptionCount  int                 `json:"option_count"`
}

type AIGenerateFormRequest struct {
	// Cara 1 (terstruktur): materi + spesifikasi soal.
	Subject     string           `json:"subject"`
	Topic       string           `json:"topic"`
	GradeLevel  string           `json:"grade_level"`
	Language    string           `json:"language"`
	Difficulty  string           `json:"difficulty"`
	TotalTime   int              `json:"total_time_minutes"`
	Specs       []AIQuestionSpec `json:"specs"`
	Attachments []AIAttachment   `json:"attachments"`

	// Cara 2 (bebas): prompt mentah / hasil speech-to-text. Jika diisi, digabung dengan field terstruktur.
	RawPrompt string `json:"raw_prompt"`

	// Jika true, langsung simpan ke DB. Jika false (default), hanya kembalikan preview.
	AutoSave bool `json:"auto_save"`
	Category string `json:"category"`
}

type AIGeneratedOption struct {
	OptionText string `json:"option_text"`
	IsCorrect  bool   `json:"is_correct"`
	ImgURL     string `json:"img_url,omitempty"`
	AudioURL   string `json:"audio_url,omitempty"`
	VideoURL   string `json:"video_url,omitempty"`
}

type AIGeneratedQuestion struct {
	QuestionText  string              `json:"question_text"`
	QuestionType  domain.QuestionType `json:"question_type"`
	Points        int                 `json:"points"`
	CodeLanguage  string              `json:"code_language,omitempty"`
	ImgURL        string              `json:"img_url,omitempty"`
	AudioURL      string              `json:"audio_url,omitempty"`
	VideoURL      string              `json:"video_url,omitempty"`
	Options       []AIGeneratedOption `json:"options,omitempty"`
	AnswerKeyText string              `json:"answer_key_text,omitempty"`
}

type AIGenerateFormPreview struct {
	Title       string                `json:"title"`
	Description string                `json:"description"`
	Questions   []AIGeneratedQuestion `json:"questions"`
	Mock        bool                  `json:"mock,omitempty"`
}

type AIGenerateFormResponse struct {
	Preview AIGenerateFormPreview `json:"preview"`
	FormID  *uuid.UUID            `json:"form_id,omitempty"`
}

// --- Autograding essay ---

type AIGradeEssayRequest struct {
	QuestionID   uuid.UUID `json:"question_id" binding:"required"`
	AnswerText   string    `json:"answer_text" binding:"required"`
	AnswerKey    string    `json:"answer_key" binding:"required"`
	MaxPoints    float64   `json:"max_points" binding:"gte=0"`
	Rubric       string    `json:"rubric"`
	ResponseID   *uuid.UUID `json:"response_id,omitempty"`
	AutoPersist  bool      `json:"auto_persist"`
}

type AIGradeEssayResponse struct {
	Score      float64 `json:"score"`
	MaxPoints  float64 `json:"max_points"`
	Similarity float64 `json:"similarity"`
	Feedback   string  `json:"feedback"`
	Mock       bool    `json:"mock,omitempty"`
}

type AIGradeResponseRequest struct {
	ResponseID uuid.UUID `json:"response_id" binding:"required"`
	// Jika kosong, pakai kunci dari AnswerKeyText hasil generate / field guru.
	AnswerKeys map[uuid.UUID]string `json:"answer_keys,omitempty"`
	AutoPersist bool `json:"auto_persist"`
}

type AIGradeResponseItem struct {
	QuestionID uuid.UUID `json:"question_id"`
	Score      float64   `json:"score"`
	MaxPoints  float64   `json:"max_points"`
	Feedback   string    `json:"feedback"`
}

type AIGradeResponseResult struct {
	Items      []AIGradeResponseItem `json:"items"`
	TotalAdded float64               `json:"total_added"`
	Mock       bool                  `json:"mock,omitempty"`
}
