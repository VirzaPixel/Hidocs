package repository

import (
	"context"

	"backend/internal/domain"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type collaboratorRepository struct {
	db *gorm.DB
}

func NewCollaboratorRepository(db *gorm.DB) domain.CollaboratorRepository {
	return &collaboratorRepository{db: db}
}

func (r *collaboratorRepository) Add(ctx context.Context, c *domain.FormCollaborator) error {
	return r.db.WithContext(ctx).Create(c).Error
}

func (r *collaboratorRepository) ListByForm(ctx context.Context, formID uuid.UUID) ([]domain.FormCollaborator, error) {
	var items []domain.FormCollaborator
	err := r.db.WithContext(ctx).
		Preload("User").
		Where("form_id = ?", formID).
		Order("created_at asc").
		Find(&items).Error
	return items, err
}

func (r *collaboratorRepository) Remove(ctx context.Context, formID, userID uuid.UUID) error {
	return r.db.WithContext(ctx).
		Where("form_id = ? AND user_id = ?", formID, userID).
		Delete(&domain.FormCollaborator{}).Error
}

func (r *collaboratorRepository) IsCollaborator(ctx context.Context, formID, userID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&domain.FormCollaborator{}).
		Where("form_id = ? AND user_id = ?", formID, userID).
		Count(&count).Error
	return count > 0, err
}

func (r *collaboratorRepository) ListFormsSharedWithUser(ctx context.Context, userID uuid.UUID) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := r.db.WithContext(ctx).
		Model(&domain.FormCollaborator{}).
		Where("user_id = ?", userID).
		Pluck("form_id", &ids).Error
	return ids, err
}
