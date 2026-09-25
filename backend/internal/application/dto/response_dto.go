package dto

import (
	"time"

	"github.com/google/uuid"
)

type MatchPairItem struct {
	MatchKey        string `json:"match_key"`
	MatchTargetText string `json:"match_target_text"`
}

type SubmitFormRequest struct {
	ResponseID      *uuid.UUID           `json:"response_id,omitempty"`
	RespondentEmail string               `json:"respondent_email" binding:"required,email"`
	Passcode        string               `json:"passcode"`
	IsAutoSubmitted bool                 `json:"is_auto_submitted"`
	DevicePlatform  string               `json:"device_platform"`
	Answers         []SubmitAnswerDetail `json:"answers" binding:"required,dive"`
}

type SubmitAnswerDetail struct {
	QuestionID       uuid.UUID       `json:"question_id" binding:"required"`
	SelectedOptionID *uuid.UUID      `json:"selected_option_id"`
	AnswerText       string          `json:"answer_text"`
	IsFlagged        bool            `json:"is_flagged"`
	MatchPairs       []MatchPairItem `json:"match_pairs,omitempty"`
}

type AutosaveAnswerRequest struct {
	QuestionID       uuid.UUID       `json:"question_id" binding:"required"`
	SelectedOptionID *uuid.UUID      `json:"selected_option_id"`
	AnswerText       string          `json:"answer_text"`
	IsFlagged        bool            `json:"is_flagged"`
	MatchPairs       []MatchPairItem `json:"match_pairs,omitempty"`
}

type AutosaveResponse struct {
	Success    bool      `json:"success"`
	Message    string    `json:"message"`
	QuestionID uuid.UUID `json:"question_id"`
	IsFlagged  bool      `json:"is_flagged"`
	SavedAt    time.Time `json:"saved_at"`
}

type TelemetryEventRequest struct {
	EventType            string  `json:"event_type" binding:"required"`
	EventMessage         *string `json:"event_message"`
	CurrentQuestionIndex int     `json:"current_question_index"`
	Metadata             *string `json:"metadata"`
}

type RestartStudentSessionRequest struct {
	WarningMessage string `json:"warning_message" binding:"required"`
}

type SessionQuestionItemDTO struct {
	QuestionID       uuid.UUID        `json:"question_id"`
	OrderIndex       int              `json:"order_index"`
	IsAnswered       bool             `json:"is_answered"`
	IsFlagged        bool             `json:"is_flagged"`
	SelectedOptionID *uuid.UUID       `json:"selected_option_id,omitempty"`
	AnswerText       string           `json:"answer_text,omitempty"`
	MatchPairs       []MatchPairItem  `json:"match_pairs,omitempty"`
}

type SessionStateDTO struct {
	ResponseID            uuid.UUID                `json:"response_id"`
	FormID                uuid.UUID                `json:"form_id"`
	Status                string                   `json:"status"`
	CurrentQuestionIndex  int                      `json:"current_question_index"`
	WarningMessage        *string                  `json:"warning_message,omitempty"`
	IsWarningAcknowledged bool                     `json:"is_warning_acknowledged"`
	StartedAt             time.Time                `json:"started_at"`
	DurationMinutes       *int                     `json:"duration_minutes,omitempty"`
	Questions             []SessionQuestionItemDTO `json:"questions"`
}

type SubmitResponseResult struct {
	ResponseID      uuid.UUID `json:"response_id"`
	TotalScore      float64   `json:"total_score"`
	IsAutoSubmitted bool      `json:"is_auto_submitted"`
	SubmittedAt     time.Time `json:"submitted_at"`
	Message         string    `json:"message"`
}

type GradeResponseRequest struct {
	TotalScore  float64            `json:"total_score" binding:"gte=0"`
	EssayScores map[string]float64 `json:"essay_scores,omitempty"`
}

type ResponseDetailDTO struct {
	ID              uuid.UUID         `json:"id"`
	FormID          uuid.UUID         `json:"form_id"`
	RespondentEmail string            `json:"respondent_email"`
	Status          string            `json:"status"`
	TotalScore      *float64          `json:"total_score,omitempty"`
	IsAutoSubmitted bool              `json:"is_auto_submitted"`
	DevicePlatform  string            `json:"device_platform"`
	StartedAt       time.Time         `json:"started_at"`
	SubmittedAt     time.Time         `json:"submitted_at"`
	Answers         []AnswerDetailDTO `json:"answers"`
}

type AnswerDetailDTO struct {
	ID                 uuid.UUID  `json:"id"`
	QuestionID         uuid.UUID  `json:"question_id"`
	QuestionText       string     `json:"question_text"`
	SelectedOptionID   *uuid.UUID `json:"selected_option_id,omitempty"`
	SelectedOption     string     `json:"selected_option,omitempty"`
	SelectedOptionText string     `json:"selected_option_text,omitempty"`
	AnswerText         string     `json:"answer_text,omitempty"`
	IsFlagged          bool       `json:"is_flagged"`
	MatchPairJSON      *string    `json:"match_pair_json,omitempty"`
	IsCorrect          *bool      `json:"is_correct,omitempty"`
	PointsEarned       float64    `json:"points_earned"`
	ScoreGiven         *float64   `json:"score_given,omitempty"`
}

// FIX: DTO baru untuk endpoint list responses yang sekarang paginated.
type PaginatedResponsesDTO struct {
	Items  []ResponseDetailDTO `json:"items"`
	Total  int64               `json:"total"`
	Limit  int                 `json:"limit"`
	Offset int                 `json:"offset"`
}

type LiveMonitoringStudentDTO struct {
	ResponseID           uuid.UUID `json:"response_id"`
	RespondentEmail      string    `json:"respondent_email"`
	Status               string    `json:"status"`
	CurrentQuestionIndex int       `json:"current_question_index"`
	TotalQuestions       int       `json:"total_questions"`
	AnsweredCount        int       `json:"answered_count"`
	FlaggedCount         int       `json:"flagged_count"`
	TabSwitchCount       int       `json:"tab_switch_count"`
	BlurCount            int       `json:"blur_count"`
	DevicePlatform       string    `json:"device_platform"`
	WarningMessage       *string   `json:"warning_message,omitempty"`
	StartedAt            time.Time `json:"started_at"`
	LastHeartbeat        time.Time `json:"last_heartbeat"`
	IsSuspicious         bool      `json:"is_suspicious"`
}
