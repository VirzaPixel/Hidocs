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
	users  map[string]*domain.User
	resets map[string]*domain.PasswordReset
}

func newMockUserRepo() *mockUserRepo {
	return &mockUserRepo{users: make(map[string]*domain.User), resets: make(map[string]*domain.PasswordReset)}
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
	m.resets[reset.Token] = reset
	return nil
}

func (m *mockUserRepo) CreateRefreshToken(ctx context.Context, rt *domain.RefreshToken) error {
	return nil
}

func (m *mockUserRepo) GetRefreshToken(ctx context.Context, token string) (*domain.RefreshToken, error) {
	return nil, domain.ErrInvalidToken
}

func (m *mockUserRepo) DeleteRefreshToken(ctx context.Context, token string) error {
	return nil
}

func (m *mockUserRepo) DeleteUserRefreshTokens(ctx context.Context, userID uuid.UUID) error {
	return nil
}

func (m *mockUserRepo) GetPasswordResetByToken(ctx context.Context, token string) (*domain.PasswordReset, error) {
	r, ok := m.resets[token]
	if !ok {
		return nil, domain.ErrInvalidToken
	}
	return r, nil
}

func (m *mockUserRepo) DeletePasswordReset(ctx context.Context, email string) error {
	for tok, r := range m.resets {
		if r.Email == email {
			delete(m.resets, tok)
		}
	}
	return nil
}

type mockEmailSender struct{}

func (m *mockEmailSender) SendOTPEmail(toEmail, otpCode string) error {
	return nil
}

func (m *mockEmailSender) SendResetEmail(toEmail, resetToken string) error {
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

func TestAuthService_ForgotAndResetPassword(t *testing.T) {
	cfg := &config.Config{RedisHost: "localhost:9999"}
	userRepo := newMockUserRepo()
	hasher := security.NewBcryptHasher()
	jwtMgr := security.NewJWTManager("test-secret-key-12345678901234567890", 24)
	otpCache := cache.NewRedisClient(cfg)
	emailSender := &mockEmailSender{}
	authSvc := service.NewAuthService(userRepo, hasher, jwtMgr, otpCache, emailSender)
	ctx := context.Background()

	email := "resetuser@example.com"
	hash, _ := hasher.HashPassword("oldpass123")
	u := &domain.User{ID: uuid.New(), Name: "Reset User", Email: email, PasswordHash: hash, Role: domain.RoleUser, IsActive: true}
	if err := userRepo.Create(ctx, u); err != nil {
		t.Fatalf("seed user failed: %v", err)
	}

	// 1. ForgotPassword must return a usable token
	token, err := authSvc.ForgotPassword(ctx, dto.ForgotPasswordRequest{Email: email})
	if err != nil {
		t.Fatalf("ForgotPassword failed: %v", err)
	}
	if token == "" {
		t.Fatalf("ForgotPassword returned empty token (regression: token dibuang)")
	}

	// 2. Unknown email must NOT leak (empty token, nil error)
	ghost, err := authSvc.ForgotPassword(ctx, dto.ForgotPasswordRequest{Email: "ghost@example.com"})
	if err != nil || ghost != "" {
		t.Fatalf("expected generic empty response for unknown email, got token=%q err=%v", ghost, err)
	}

	// 3. ResetPassword with valid token works and invalidates token
	if err := authSvc.ResetPassword(ctx, dto.ResetPasswordRequest{Token: token, NewPassword: "newpass123"}); err != nil {
		t.Fatalf("ResetPassword failed: %v", err)
	}

	// 4. Login with new password works
	res, err := authSvc.Login(ctx, dto.LoginRequest{Email: email, Password: "newpass123"})
	if err != nil || res.Token == "" {
		t.Fatalf("login with new password failed: %v", err)
	}

	// 5. Reused token must be rejected
	if err := authSvc.ResetPassword(ctx, dto.ResetPasswordRequest{Token: token, NewPassword: "otherpass1"}); err == nil {
		t.Fatalf("expected error on token reuse, got nil")
	}

	// 6. Invalid token rejected
	if err := authSvc.ResetPassword(ctx, dto.ResetPasswordRequest{Token: "invalid", NewPassword: "otherpass1"}); err == nil {
		t.Fatalf("expected error on invalid token, got nil")
	}
}
