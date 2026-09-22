package domain

import (
	"time"

	"github.com/google/uuid"
)

type UserRole string

const (
	RoleSuperAdmin UserRole = "superadmin"
	RoleAdmin      UserRole = "admin"
	RoleUser       UserRole = "user"
)

type User struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name         string    `gorm:"type:varchar(100);not null" json:"name"`
	Email        string    `gorm:"type:varchar(100);uniqueIndex;not null" json:"email"`
	PasswordHash string    `gorm:"type:varchar(255);not null" json:"-"`
	Role         UserRole  `gorm:"type:varchar(20);not null;default:'user'" json:"role"`
	AvatarURL    string    `gorm:"type:varchar(255)" json:"avatar_url,omitempty"`
	IsActive     bool      `gorm:"type:boolean;default:true" json:"is_active"`
	CreatedAt    time.Time `gorm:"type:timestamp;not null;default:now()" json:"created_at"`
	UpdatedAt    time.Time `gorm:"type:timestamp;not null;default:now()" json:"updated_at"`
}

type PasswordReset struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Email     string    `gorm:"type:varchar(100);not null;index" json:"email"`
	Token     string    `gorm:"type:varchar(255);not null;uniqueIndex" json:"token"`
	ExpiresAt time.Time `gorm:"type:timestamp;not null" json:"expires_at"`
	CreatedAt time.Time `gorm:"type:timestamp;not null;default:now()" json:"created_at"`
}
