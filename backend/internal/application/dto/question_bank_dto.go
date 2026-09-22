package dto

import (
	"time"

	"backend/internal/domain"
	"github.com/google/uuid"
)

type BankQuestionOptionInput struct {
	OptionText      string  `json:"option_text" binding:"required"`
	ImgURL          *string `json:"img_url"`
	AudioURL        *string `json:"audio_url"`
	VideoURL        *string `json:"video_url"`
	MatchKey        *string `json:"match_key"`
	MatchTargetText *string `json:"match_target_text"`
	IsCorrect       bool    `json:"is_correct"`
}

type CreateBankQuestionRequest struct {
	Subject      string                    `json:"subject"`
	Topic        string                    `json:"topic"`
	Difficulty   domain.QuestionDifficulty `json:"difficulty" binding:"omitempty,oneof=EASY MEDIUM HARD"`
	QuestionText string                    `json:"question_text" binding:"required"`
	QuestionType domain.QuestionType       `json:"question_type" binding:"required"`
	CodeLanguage string                    `json:"code_language"`
	ImgURL       string                    `json:"img_url"`
	AudioURL     *string                   `json:"audio_url"`
	VideoURL     *string                   `json:"video_url"`
	Points       int                       `json:"points"`
	Options      []BankQuestionOptionInput `json:"options"`
}

type UpdateBankQuestionRequest = CreateBankQuestionRequest

type BankQuestionOptionDTO struct {
	ID              uuid.UUID `json:"id"`
	OptionText      string    `json:"option_text"`
	ImgURL          *string   `json:"img_url,omitempty"`
	AudioURL        *string   `json:"audio_url,omitempty"`
	VideoURL        *string   `json:"video_url,omitempty"`
	MatchKey        *string   `json:"match_key,omitempty"`
	MatchTargetText *string   `json:"match_target_text,omitempty"`
	IsCorrect       bool      `json:"is_correct"`
	OrderIndex      int       `json:"order_index"`
}

type BankQuestionDTO struct {
	ID           uuid.UUID                 `json:"id"`
	Subject      string                    `json:"subject"`
	Topic        string                    `json:"topic"`
	Difficulty   domain.QuestionDifficulty `json:"difficulty"`
	QuestionText string                    `json:"question_text"`
	QuestionType domain.QuestionType       `json:"question_type"`
	CodeLanguage string                    `json:"code_language,omitempty"`
	ImgURL       string                    `json:"img_url,omitempty"`
	AudioURL     *string                   `json:"audio_url,omitempty"`
	VideoURL     *string                   `json:"video_url,omitempty"`
	Points       int                       `json:"points"`
	CreatedAt    time.Time                 `json:"created_at"`
	Options      []BankQuestionOptionDTO   `json:"options,omitempty"`
}

type PaginatedBankQuestionsDTO struct {
	Items  []BankQuestionDTO `json:"items"`
	Total  int64             `json:"total"`
	Limit  int               `json:"limit"`
	Offset int               `json:"offset"`
}

type AddBankQuestionToFormRequest struct {
	FormID uuid.UUID `json:"form_id" binding:"required"`
}

type SaveQuestionToBankRequest struct {
	Subject    string                    `json:"subject"`
	Topic      string                    `json:"topic"`
	Difficulty domain.QuestionDifficulty `json:"difficulty" binding:"omitempty,oneof=EASY MEDIUM HARD"`
}
