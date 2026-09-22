package repository

import (
	"context"

	"backend/internal/domain"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type bankQuestionRepository struct {
	db *gorm.DB
}

func NewBankQuestionRepository(db *gorm.DB) domain.BankQuestionRepository {
	return &bankQuestionRepository{db: db}
}

func (r *bankQuestionRepository) Create(ctx context.Context, q *domain.BankQuestion) error {
	return r.db.WithContext(ctx).Create(q).Error
}

func (r *bankQuestionRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.BankQuestion, error) {
	var q domain.BankQuestion
	if err := r.db.WithContext(ctx).Preload("Options").First(&q, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &q, nil
}

func (r *bankQuestionRepository) applyFilter(tx *gorm.DB, userID uuid.UUID, filter domain.BankQuestionFilter) *gorm.DB {
	tx = tx.Where("user_id = ?", userID)
	if filter.Subject != "" {
		tx = tx.Where("subject ILIKE ?", "%"+filter.Subject+"%")
	}
	if filter.Topic != "" {
		tx = tx.Where("topic ILIKE ?", "%"+filter.Topic+"%")
	}
	if filter.Difficulty != "" {
		tx = tx.Where("difficulty = ?", filter.Difficulty)
	}
	if filter.QuestionType != "" {
		tx = tx.Where("question_type = ?", filter.QuestionType)
	}
	return tx
}

func (r *bankQuestionRepository) ListByUser(ctx context.Context, userID uuid.UUID, filter domain.BankQuestionFilter, pg domain.Pagination) ([]domain.BankQuestion, int64, error) {
	var total int64
	countQuery := r.applyFilter(r.db.WithContext(ctx).Model(&domain.BankQuestion{}), userID, filter)
	if err := countQuery.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var items []domain.BankQuestion
	listQuery := r.applyFilter(r.db.WithContext(ctx).Model(&domain.BankQuestion{}), userID, filter)
	err := listQuery.
		Preload("Options").
		Order("created_at desc").
		Limit(pg.Limit).
		Offset(pg.Offset).
		Find(&items).Error

	return items, total, err
}

func (r *bankQuestionRepository) Update(ctx context.Context, q *domain.BankQuestion) error {
	if err := r.db.WithContext(ctx).Where("bank_question_id = ?", q.ID).Delete(&domain.BankQuestionOption{}).Error; err != nil {
		return err
	}
	return r.db.WithContext(ctx).Save(q).Error
}

func (r *bankQuestionRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&domain.BankQuestion{}, "id = ?", id).Error
}
