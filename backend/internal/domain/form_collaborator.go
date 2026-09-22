package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type CollaboratorRole string

const (
	// Satu-satunya role saat ini: akses baca ke live-monitoring, daftar respons,
	// dan analytics sebuah form. TIDAK bisa edit soal, grading, atau hapus form.
	CollaboratorRoleMonitor CollaboratorRole = "MONITOR"
)

// FormCollaborator merepresentasikan guru lain (bukan pemilik form) yang diberi akses
// untuk memantau (monitoring) sebuah form/sesi ujian — dipakai untuk kasus "1 sekolah
// mengerjakan 1 mapel bersamaan", di mana lebih dari satu guru/pengawas perlu melihat
// dashboard monitoring form yang sama.
type FormCollaborator struct {
	ID        uuid.UUID        `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	FormID    uuid.UUID        `gorm:"type:uuid;not null;index:idx_form_collaborator,unique" json:"form_id"`
	UserID    uuid.UUID        `gorm:"type:uuid;not null;index:idx_form_collaborator,unique" json:"user_id"`
	Role      CollaboratorRole `gorm:"type:varchar(20);not null;default:'MONITOR'" json:"role"`
	InvitedBy uuid.UUID        `gorm:"type:uuid;not null" json:"invited_by"`
	CreatedAt time.Time        `gorm:"type:timestamp;not null;default:now()" json:"created_at"`

	Form *Form `gorm:"foreignKey:FormID;constraint:OnDelete:CASCADE" json:"-"`
	User *User `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user,omitempty"`
}

type CollaboratorRepository interface {
	Add(ctx context.Context, c *FormCollaborator) error
	ListByForm(ctx context.Context, formID uuid.UUID) ([]FormCollaborator, error)
	Remove(ctx context.Context, formID, userID uuid.UUID) error
	IsCollaborator(ctx context.Context, formID, userID uuid.UUID) (bool, error)
	// ListFormsSharedWithUser mengembalikan daftar form_id yang di-share ke user ini
	// (untuk tab "Dibagikan ke saya" di dashboard guru pengawas).
	ListFormsSharedWithUser(ctx context.Context, userID uuid.UUID) ([]uuid.UUID, error)
}
