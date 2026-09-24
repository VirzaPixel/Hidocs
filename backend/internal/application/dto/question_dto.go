package dto

import (
	"backend/internal/domain"
	"github.com/google/uuid"
)

type CreateQuestionRequest struct {
	QuestionText string                `json:"question_text" binding:"required"`
	QuestionType domain.QuestionType   `json:"question_type" binding:"required"`
	CodeLanguage string                `json:"code_language"`
	ImgURL       string                `json:"img_url"`
	AudioURL     *string               `json:"audio_url"`
	VideoURL     *string               `json:"video_url"`
	AnswerKey    *string               `json:"answer_key"`
	Rubric       *string               `json:"rubric"`
	IsAutoScored bool                  `json:"is_auto_scored"`
	Points       int                   `json:"points" binding:"gte=0"`
	OrderIndex   int                   `json:"order_index"`
	IsRequired   bool                  `json:"is_required"`
	Options      []CreateOptionRequest `json:"options"`
}

type UpdateQuestionRequest struct {
	QuestionText string                `json:"question_text" binding:"required"`
	QuestionType domain.QuestionType   `json:"question_type" binding:"required"`
	CodeLanguage string                `json:"code_language"`
	ImgURL       string                `json:"img_url"`
	AudioURL     *string               `json:"audio_url"`
	VideoURL     *string               `json:"video_url"`
	AnswerKey    *string               `json:"answer_key"`
	Rubric       *string               `json:"rubric"`
	IsAutoScored bool                  `json:"is_auto_scored"`
	Points       int                   `json:"points" binding:"gte=0"`
	OrderIndex   int                   `json:"order_index"`
	IsRequired   bool                  `json:"is_required"`
	Options      []CreateOptionRequest `json:"options"`
}

type CreateOptionRequest struct {
	OptionText      string  `json:"option_text" binding:"required"`
	ImgURL          *string `json:"img_url"`
	AudioURL        *string `json:"audio_url"`
	VideoURL        *string `json:"video_url"`
	MatchKey        *string `json:"match_key"`
	MatchTargetText *string `json:"match_target_text"`
	IsCorrect       bool    `json:"is_correct"`
	OrderIndex      int     `json:"order_index"`
}

type QuestionDTO struct {
	ID           uuid.UUID           `json:"id"`
	FormID       uuid.UUID           `json:"form_id"`
	QuestionText string              `json:"question_text"`
	QuestionType domain.QuestionType `json:"question_type"`
	CodeLanguage string              `json:"code_language,omitempty"`
	ImgURL       string              `json:"img_url,omitempty"`
	AudioURL     *string             `json:"audio_url,omitempty"`
	VideoURL     *string             `json:"video_url,omitempty"`
	AnswerKey    *string             `json:"answer_key,omitempty"`
	Rubric       *string             `json:"rubric,omitempty"`
	IsAutoScored bool                `json:"is_auto_scored"`
	Points       int                 `json:"points"`
	OrderIndex   int                 `json:"order_index"`
	IsRequired   bool                `json:"is_required"`
	Options      []OptionDTO         `json:"options,omitempty"`
}

type OptionDTO struct {
	ID              uuid.UUID `json:"id"`
	QuestionID      uuid.UUID `json:"question_id"`
	OptionText      string    `json:"option_text"`
	ImgURL          *string   `json:"img_url,omitempty"`
	AudioURL        *string   `json:"audio_url,omitempty"`
	VideoURL        *string   `json:"video_url,omitempty"`
	MatchKey        *string   `json:"match_key,omitempty"`
	MatchTargetText *string   `json:"match_target_text,omitempty"`
	IsCorrect       bool      `json:"is_correct"`
	OrderIndex      int       `json:"order_index"`
}

type UploadImageResponse struct {
	ImgURL string `json:"img_url"`
}

type UploadMediaResponse struct {
	MediaURL  string `json:"media_url"`
	MediaType string `json:"media_type"`
}
