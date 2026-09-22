package service_test

import (
	"context"
	"testing"

	"backend/config"
	"backend/internal/application/dto"
	"backend/internal/application/service"
	"backend/internal/domain"
	"backend/internal/infrastructure/cache"
	"backend/internal/infrastructure/security"
	"github.com/google/uuid"
)

type mockUserRepo struct {
	users map[string]*domain.User
}

func newMockUserRepo() *mockUserRepo {
	return &mockUserRepo{users: make(map[string]*domain.User)}
}

func (m *mockUserRepo) Create(ctx context.Context, user *domain.User) error {
	m.users[user.Email] = user
	return nil
}

func (m *mockUserRepo) CreateBatch(ctx context.Context, users []domain.User) error {
	for i := range users {
		m.users[users[i].Email] = &users[i]
	}
	return nil
}

func (m *mockUserRepo) GetExistingEmails(ctx context.Context, emails []string) (map[string]bool, error) {
	res := make(map[string]bool)
	for _, e := range emails {
		if _, ok := m.users[e]; ok {
			res[e] = true
		}
	}
	return res, nil
}

func (m *mockUserRepo) GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	for _, u := range m.users {
		if u.ID == id {
			return u, nil
		}
	}
	return nil, domain.ErrUserNotFound
}

func (m *mockUserRepo) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	u, ok := m.users[email]
	if !ok {
		return nil, domain.ErrUserNotFound
	}
	return u, nil
}

func (m *mockUserRepo) Update(ctx context.Context, user *domain.User) error {
	m.users[user.Email] = user
	return nil
}

func (m *mockUserRepo) Delete(ctx context.Context, id uuid.UUID) error {
	return nil
}

func (m *mockUserRepo) ListAll(ctx context.Context, offset, limit int) ([]domain.User, int64, error) {
	return nil, 0, nil
}

func (m *mockUserRepo) CreatePasswordReset(ctx context.Context, reset *domain.PasswordReset) error {
	return nil
}

func (m *mockUserRepo) GetPasswordResetByToken(ctx context.Context, token string) (*domain.PasswordReset, error) {
	return nil, nil
}

func (m *mockUserRepo) DeletePasswordReset(ctx context.Context, email string) error {
	return nil
}

type mockEmailSender struct{}

func (m *mockEmailSender) SendOTPEmail(toEmail, otpCode string) error {
	return nil
}

func TestAuthService_RegisterAndResendOTP(t *testing.T) {
	cfg := &config.Config{
		RedisHost: "localhost:9999", // Trigger fallback in-memory cache
	}

	userRepo := newMockUserRepo()
	hasher := security.NewBcryptHasher()
	jwtMgr := security.NewJWTManager("test-secret-key-12345678901234567890", 24)
	otpCache := cache.NewRedisClient(cfg) // fallback in-memory mode
	emailSender := &mockEmailSender{}

	authSvc := service.NewAuthService(userRepo, hasher, jwtMgr, otpCache, emailSender)
	ctx := context.Background()

	email := "testuser@example.com"

	// 1. Test ResendOTP before Register
	err := authSvc.ResendOTP(ctx, dto.ResendOTPRequest{Email: email})
	if err == nil {
		t.Fatalf("expected error when calling ResendOTP for unregistered email, got nil")
	}

	// 2. Register user
	msg, err := authSvc.Register(ctx, dto.RegisterRequest{
		Name:     "Test User",
		Email:    email,
		Password: "password123",
	})
	if err != nil {
		t.Fatalf("Register failed: %v", err)
	}
	if msg == "" {
		t.Fatalf("Register returned empty message")
	}

	// Verify pending payload exists in OTP cache
	pendingPayload, err := otpCache.GetPendingUser(ctx, email)
	if err != nil || pendingPayload == "" {
		t.Fatalf("Pending user payload not found in cache after registration")
	}

	// Get OTP code from cache
	otpCode, err := otpCache.GetOTP(ctx, email)
	if err != nil || otpCode == "" {
		t.Fatalf("OTP code not found in cache after registration")
	}
	if len(otpCode) != 6 {
		t.Fatalf("Expected 6-digit OTP, got %s", otpCode)
	}

	// 3. Test ResendOTP after Register (valid pending registration in Redis)
	err = authSvc.ResendOTP(ctx, dto.ResendOTPRequest{Email: email})
	if err != nil {
		t.Fatalf("ResendOTP failed for pending user: %v", err)
	}

	// Check if new OTP was generated
	newOTP, err := otpCache.GetOTP(ctx, email)
	if err != nil || newOTP == "" {
		t.Fatalf("New OTP code not found after ResendOTP")
	}

	// 4. Verify OTP
	res, err := authSvc.VerifyOTP(ctx, dto.VerifyOTPRequest{
		Email:   email,
		OTPCode: newOTP,
	})
	if err != nil {
		t.Fatalf("VerifyOTP failed: %v", err)
	}
	if res.Token == "" {
		t.Fatalf("Token is empty")
	}
	if res.User.Email != email {
		t.Fatalf("User email mismatch, expected %s got %s", email, res.User.Email)
	}

	// 5. Test ResendOTP after user is verified in DB
	err = authSvc.ResendOTP(ctx, dto.ResendOTPRequest{Email: email})
	if err == nil {
		t.Fatalf("Expected error when calling ResendOTP for verified user, got nil")
	}
	if err.Error() != "User is already registered and verified. Please login." {
		t.Fatalf("Unexpected error message: %v", err)
	}
}
