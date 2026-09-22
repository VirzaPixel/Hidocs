package dto

import (
	"time"

	"github.com/google/uuid"
)

type AddCollaboratorRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type CollaboratorDTO struct {
	UserID    uuid.UUID `json:"user_id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	Role      string    `json:"role"`
	CreatedAt time.Time `json:"created_at"`
}
