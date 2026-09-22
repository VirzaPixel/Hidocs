package repository

import (
	"context"
	"errors"

	"backend/internal/domain"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type questionRepository struct {
	db *gorm.DB
}

func NewQuestionRepository(db *gorm.DB) domain.QuestionRepository {
	return &questionRepository{db: db}
}

func (r *questionRepository) CreateQuestion(ctx context.Context, q *domain.Question) error {
	return r.db.WithContext(ctx).Create(q).Error
}

func (r *questionRepository) CreateBatchQuestions(ctx context.Context, questions []domain.Question) error {
	return r.db.WithContext(ctx).Create(&questions).Error
}

func (r *questionRepository) GetQuestionByID(ctx context.Context, id uuid.UUID) (*domain.Question, error) {
	var q domain.Question
	err := r.db.WithContext(ctx).Preload("Options").First(&q, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrQuestionNotFound
		}
		return nil, err
	}
	return &q, nil
}

func (r *questionRepository) GetQuestionsByFormID(ctx context.Context, formID uuid.UUID) ([]domain.Question, error) {
	var questions []domain.Question
	err := r.db.WithContext(ctx).
		Preload("Options", func(db *gorm.DB) *gorm.DB {
			return db.Order("order_index asc")
		}).
		Where("form_id = ?", formID).
		Order("order_index asc").
		Find(&questions).Error
	return questions, err
}

func (r *questionRepository) UpdateQuestion(ctx context.Context, q *domain.Question) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		updates := map[string]interface{}{
			"question_text":   q.QuestionText,
			"question_type":   q.QuestionType,
			"code_language":   q.CodeLanguage,
			"img_url":         q.ImgURL,
			"audio_url":       q.AudioURL,
			"video_url":       q.VideoURL,
			"is_auto_scored":  q.IsAutoScored,
			"points":          q.Points,
			"order_index":     q.OrderIndex,
			"is_required":     q.IsRequired,
			"is_autosaved_at": q.IsAutosavedAt,
		}
		if err := tx.Model(&domain.Question{}).Where("id = ?", q.ID).Updates(updates).Error; err != nil {
			return err
		}
		if err := tx.Where("question_id = ?", q.ID).Delete(&domain.QuestionOption{}).Error; err != nil {
			return err
		}
		if len(q.Options) > 0 {
			if err := tx.Create(&q.Options).Error; err != nil {
				return err
			}
		}
		return nil
	})
}

func (r *questionRepository) DeleteQuestion(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&domain.Question{}, "id = ?", id).Error
}

func (r *questionRepository) CreateOption(ctx context.Context, opt *domain.QuestionOption) error {
	return r.db.WithContext(ctx).Create(opt).Error
}

func (r *questionRepository) UpdateOption(ctx context.Context, opt *domain.QuestionOption) error {
	return r.db.WithContext(ctx).Save(opt).Error
}

func (r *questionRepository) DeleteOption(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&domain.QuestionOption{}, "id = ?", id).Error
}

func (r *questionRepository) GetOptionByID(ctx context.Context, id uuid.UUID) (*domain.QuestionOption, error) {
	var opt domain.QuestionOption
	if err := r.db.WithContext(ctx).First(&opt, "id = ?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrOptionNotFound
		}
		return nil, err
	}
	return &opt, nil
}
