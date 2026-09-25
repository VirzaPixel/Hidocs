package domain

import (
	"time"

	"github.com/google/uuid"
)

type QuestionType string

const (
	TypeShortText      QuestionType = "SHORT_TEXT"
	TypeLongText       QuestionType = "LONG_TEXT"
	TypeMultipleChoice QuestionType = "MULTIPLE_CHOICE"
	TypeCheckboxes     QuestionType = "CHECKBOXES"
	TypeDropdown       QuestionType = "DROPDOWN"
	TypeRating         QuestionType = "RATING"
	TypeYesNo          QuestionType = "YES_NO"
	TypeMath           QuestionType = "MATH"
	TypeCode           QuestionType = "CODE"
	TypeImage          QuestionType = "IMAGE"
	TypeMatching       QuestionType = "MATCHING"
)

type Question struct {
	ID            uuid.UUID        `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FormID        uuid.UUID        `gorm:"type:uuid;not null;index" json:"form_id"`
	QuestionText  string           `gorm:"type:text;not null" json:"question_text"`
	QuestionType  QuestionType     `gorm:"type:varchar(30);not null" json:"question_type"`
	CodeLanguage  string           `gorm:"type:varchar(30)" json:"code_language,omitempty"`
	ImgURL        string           `gorm:"type:varchar(255)" json:"img_url,omitempty"`
	AudioURL      *string          `gorm:"type:varchar(255)" json:"audio_url,omitempty"`
	VideoURL      *string          `gorm:"type:varchar(255)" json:"video_url,omitempty"`
	AnswerKey     *string          `gorm:"type:text" json:"answer_key,omitempty"`
	Rubric        *string          `gorm:"type:text" json:"rubric,omitempty"`
	IsAutoScored  bool             `gorm:"type:boolean;default:true" json:"is_auto_scored"`
	Points        int              `gorm:"type:int;default:1" json:"points"`
	OrderIndex    int              `gorm:"type:int;not null;default:0" json:"order_index"`
	IsRequired    bool             `gorm:"type:boolean;default:false" json:"is_required"`
	CorrectRating *int             `gorm:"type:int" json:"correct_rating,omitempty"`
	IsAutosavedAt *time.Time       `gorm:"type:timestamp" json:"is_autosaved_at,omitempty"`
	
	// Relations
	Options       []QuestionOption `gorm:"foreignKey:QuestionID;constraint:OnDelete:CASCADE" json:"options,omitempty"`
}

type QuestionOption struct {
	ID              uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	QuestionID      uuid.UUID `gorm:"type:uuid;not null;index" json:"question_id"`
	OptionText      string    `gorm:"type:text;not null" json:"option_text"`
	ImgURL          *string   `gorm:"type:varchar(255)" json:"img_url,omitempty"`
	AudioURL        *string   `gorm:"type:varchar(255)" json:"audio_url,omitempty"`
	VideoURL        *string   `gorm:"type:varchar(255)" json:"video_url,omitempty"`
	MatchKey        *string   `gorm:"type:varchar(255)" json:"match_key,omitempty"`
	MatchTargetText *string   `gorm:"type:varchar(255)" json:"match_target_text,omitempty"`
	IsCorrect       bool      `gorm:"type:boolean;default:false" json:"is_correct"`
	OrderIndex      int       `gorm:"type:int;not null;default:0" json:"order_index"`
}
