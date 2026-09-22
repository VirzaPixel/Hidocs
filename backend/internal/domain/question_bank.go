package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type QuestionDifficulty string

const (
	DifficultyEasy   QuestionDifficulty = "EASY"
	DifficultyMedium QuestionDifficulty = "MEDIUM"
	DifficultyHard   QuestionDifficulty = "HARD"
)

// BankQuestion adalah soal yang tersimpan lepas dari form manapun (milik guru, bukan
// milik satu form), supaya bisa dipakai ulang lintas form (mis. tiap semester).
// Menyalin BankQuestion ke sebuah form akan membuat Question baru (lihat
// QuestionBankService.AddToForm) — bukan referensi live, jadi form tetap independen
// kalau BankQuestion aslinya diedit/dihapus belakangan.
type BankQuestion struct {
	ID           uuid.UUID          `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID       uuid.UUID          `gorm:"type:uuid;not null;index" json:"user_id"`
	Subject      string             `gorm:"type:varchar(100);index" json:"subject"`
	Topic        string             `gorm:"type:varchar(100);index" json:"topic"`
	Difficulty   QuestionDifficulty `gorm:"type:varchar(20);not null;default:'MEDIUM';index" json:"difficulty"`
	QuestionText string             `gorm:"type:text;not null" json:"question_text"`
	QuestionType QuestionType       `gorm:"type:varchar(30);not null;index" json:"question_type"`
	CodeLanguage string             `gorm:"type:varchar(30)" json:"code_language,omitempty"`
	ImgURL       string             `gorm:"type:varchar(255)" json:"img_url,omitempty"`
	AudioURL     *string            `gorm:"type:varchar(255)" json:"audio_url,omitempty"`
	VideoURL     *string            `gorm:"type:varchar(255)" json:"video_url,omitempty"`
	Points       int                `gorm:"type:int;default:10" json:"points"`
	CreatedAt    time.Time          `gorm:"type:timestamp;not null;default:now()" json:"created_at"`
	UpdatedAt    time.Time          `gorm:"type:timestamp;not null;default:now()" json:"updated_at"`

	Options []BankQuestionOption `gorm:"foreignKey:BankQuestionID;constraint:OnDelete:CASCADE" json:"options,omitempty"`
}

type BankQuestionOption struct {
	ID              uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	BankQuestionID  uuid.UUID `gorm:"type:uuid;not null;index" json:"bank_question_id"`
	OptionText      string    `gorm:"type:text;not null" json:"option_text"`
	ImgURL          *string   `gorm:"type:varchar(255)" json:"img_url,omitempty"`
	AudioURL        *string   `gorm:"type:varchar(255)" json:"audio_url,omitempty"`
	VideoURL        *string   `gorm:"type:varchar(255)" json:"video_url,omitempty"`
	MatchKey        *string   `gorm:"type:varchar(255)" json:"match_key,omitempty"`
	MatchTargetText *string   `gorm:"type:varchar(255)" json:"match_target_text,omitempty"`
	IsCorrect       bool      `gorm:"type:boolean;default:false" json:"is_correct"`
	OrderIndex      int       `gorm:"type:int;not null;default:0" json:"order_index"`
}

type BankQuestionFilter struct {
	Subject      string
	Topic        string
	Difficulty   QuestionDifficulty
	QuestionType QuestionType
}

type BankQuestionRepository interface {
	Create(ctx context.Context, q *BankQuestion) error
	GetByID(ctx context.Context, id uuid.UUID) (*BankQuestion, error)
	ListByUser(ctx context.Context, userID uuid.UUID, filter BankQuestionFilter, pg Pagination) ([]BankQuestion, int64, error)
	Update(ctx context.Context, q *BankQuestion) error
	Delete(ctx context.Context, id uuid.UUID) error
}
