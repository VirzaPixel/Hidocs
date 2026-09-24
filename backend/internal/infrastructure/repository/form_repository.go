package repository

import (
	"context"
	"errors"

	"backend/internal/domain"
	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type formRepository struct {
	db *gorm.DB
}

func NewFormRepository(db *gorm.DB) domain.FormRepository {
	return &formRepository{db: db}
}

func (r *formRepository) Create(ctx context.Context, form *domain.Form) error {
	return r.db.WithContext(ctx).Create(form).Error
}

func (r *formRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.Form, error) {
	var form domain.Form
	err := r.db.WithContext(ctx).
		Preload("FormSettings").
		Preload("Questions", func(db *gorm.DB) *gorm.DB {
			return db.Order("order_index asc")
		}).
		Preload("Questions.Options", func(db *gorm.DB) *gorm.DB {
			return db.Order("order_index asc")
		}).
		First(&form, "id = ?", id).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrFormNotFound
		}
		return nil, err
	}
	return &form, nil
}

func (r *formRepository) GetByCustomURL(ctx context.Context, customURL string) (*domain.Form, error) {
	var form domain.Form
	err := r.db.WithContext(ctx).
		Preload("FormSettings").
		Preload("Questions", func(db *gorm.DB) *gorm.DB {
			return db.Order("order_index asc")
		}).
		Preload("Questions.Options", func(db *gorm.DB) *gorm.DB {
			return db.Order("order_index asc")
		}).
		First(&form, "custom_url = ?", customURL).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrFormNotFound
		}
		return nil, err
	}
	return &form, nil
}

func (r *formRepository) GetByUserID(ctx context.Context, userID uuid.UUID, status domain.FormStatus, category string) ([]domain.Form, error) {
	var forms []domain.Form
	query := r.db.WithContext(ctx).
		Preload("FormSettings").
		Preload("Questions").
		Where("user_id = ? OR id IN (SELECT form_id FROM form_collaborators WHERE user_id = ?)", userID, userID)

	if status != "" {
		query = query.Where("status = ?", status)
	}
	if category != "" {
		query = query.Where("category = ?", category)
	}

	err := query.Order("created_at desc").Find(&forms).Error
	return forms, err
}

func (r *formRepository) GetByUserIDWithCounts(ctx context.Context, userID uuid.UUID, status domain.FormStatus, category string) ([]domain.FormWithCount, error) {
	var forms []domain.Form
	query := r.db.WithContext(ctx).
		Preload("FormSettings").
		Preload("Questions").
		Where("user_id = ? OR id IN (SELECT form_id FROM form_collaborators WHERE user_id = ?)", userID, userID)

	if status != "" {
		query = query.Where("status = ?", status)
	}
	if category != "" {
		query = query.Where("category = ?", category)
	}

	if err := query.Order("created_at desc").Find(&forms).Error; err != nil {
		return nil, err
	}

	if len(forms) == 0 {
		return []domain.FormWithCount{}, nil
	}

	var formIDs []uuid.UUID
	for _, f := range forms {
		formIDs = append(formIDs, f.ID)
	}

	type countResult struct {
		FormID uuid.UUID `gorm:"column:form_id"`
		Count  int64     `gorm:"column:count"`
	}
	var counts []countResult
	_ = r.db.WithContext(ctx).
		Table("form_responses").
		Select("form_id, count(*) as count").
		Where("form_id IN ?", formIDs).
		Group("form_id").
		Scan(&counts).Error

	countMap := make(map[uuid.UUID]int64)
	for _, c := range counts {
		countMap[c.FormID] = c.Count
	}

	var result []domain.FormWithCount
	for _, f := range forms {
		result = append(result, domain.FormWithCount{
			Form:          f,
			ResponseCount: countMap[f.ID],
		})
	}

	return result, nil
}

func (r *formRepository) GetCategoriesByUserID(ctx context.Context, userID uuid.UUID) ([]string, error) {
	var categories []string
	err := r.db.WithContext(ctx).Model(&domain.Form{}).
		Where("user_id = ? OR id IN (SELECT form_id FROM form_collaborators WHERE user_id = ?)", userID, userID).
		Distinct("category").
		Pluck("category", &categories).Error
	return categories, err
}

func (r *formRepository) Update(ctx context.Context, form *domain.Form) error {
	return r.db.WithContext(ctx).Save(form).Error
}

func (r *formRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&domain.Form{}, "id = ?", id).Error
}

func (r *formRepository) UpsertFormSettings(ctx context.Context, settings *domain.FormSettings) error {
	return r.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "form_id"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"duration_minutes", "auto_active_days", "is_active_immediately",
			"is_one_time_submission", "randomize_questions", "randomize_options",
			"start_time", "end_time", "theme_color", "cover_image_url", "logo_url",
			"font_family", "allow_backtrack", "show_question_number", "fullscreen_mode",
			"exam_token", "is_token_protected", "result_visibility", "identity_fields_json",
		}),
	}).Create(settings).Error
}

func (r *formRepository) GetFormSettingsByFormID(ctx context.Context, formID uuid.UUID) (*domain.FormSettings, error) {
	var settings domain.FormSettings
	if err := r.db.WithContext(ctx).First(&settings, "form_id = ?", formID).Error; err != nil {
		return nil, err
	}
	return &settings, nil
}

func (r *formRepository) GetFormResponseCount(ctx context.Context, formID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&domain.FormResponse{}).Where("form_id = ?", formID).Count(&count).Error
	return count, err
}
