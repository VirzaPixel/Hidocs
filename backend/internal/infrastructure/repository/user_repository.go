package repository

import (
	"context"
	"errors"

	"backend/internal/domain"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type userRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) domain.UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(ctx context.Context, user *domain.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *userRepository) CreateBatch(ctx context.Context, users []domain.User) error {
	if len(users) == 0 {
		return nil
	}
	return r.db.WithContext(ctx).CreateInBatches(&users, 100).Error
}

func (r *userRepository) GetExistingEmails(ctx context.Context, emails []string) (map[string]bool, error) {
	if len(emails) == 0 {
		return make(map[string]bool), nil
	}
	var existing []string
	err := r.db.WithContext(ctx).Model(&domain.User{}).Where("email IN ?", emails).Pluck("email", &existing).Error
	if err != nil {
		return nil, err
	}
	res := make(map[string]bool, len(existing))
	for _, e := range existing {
		res[e] = true
	}
	return res, nil
}

func (r *userRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	var user domain.User
	if err := r.db.WithContext(ctx).First(&user, "id = ?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrUserNotFound
		}
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	var user domain.User
	if err := r.db.WithContext(ctx).First(&user, "email = ?", email).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrUserNotFound
		}
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) Update(ctx context.Context, user *domain.User) error {
	return r.db.WithContext(ctx).Save(user).Error
}

func (r *userRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Delete(&domain.User{}, "id = ?", id).Error
}

func (r *userRepository) ListAll(ctx context.Context, offset, limit int) ([]domain.User, int64, error) {
	var users []domain.User
	var total int64
	
	if err := r.db.WithContext(ctx).Model(&domain.User{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := r.db.WithContext(ctx).Offset(offset).Limit(limit).Order("created_at desc").Find(&users).Error
	return users, total, err
}

func (r *userRepository) CreatePasswordReset(ctx context.Context, reset *domain.PasswordReset) error {
	return r.db.WithContext(ctx).Create(reset).Error
}

func (r *userRepository) GetPasswordResetByToken(ctx context.Context, token string) (*domain.PasswordReset, error) {
	var reset domain.PasswordReset
	if err := r.db.WithContext(ctx).First(&reset, "token = ? AND expires_at > NOW()", token).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrInvalidToken
		}
		return nil, err
	}
	return &reset, nil
}

func (r *userRepository) DeletePasswordReset(ctx context.Context, email string) error {
	return r.db.WithContext(ctx).Delete(&domain.PasswordReset{}, "email = ?", email).Error
}
