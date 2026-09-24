package service_test

import (
	"context"
	"errors"
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
	jwtMgr := security.NewJWTManager("test-secret-key-12345678901234567890", security.DefaultAccessExpireMinutes, security.DefaultRefreshExpireHours)
	otpCache := cache.NewRedisClient(cfg) // fallback in-memory mode
	emailSender := &mockEmailSender{}

	authSvc := service.NewAuthService(userRepo, hasher, jwtMgr, otpCache, otpCache, emailSender)
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
	// Opsi A: login harus mengembalikan sepasang token.
	if res.AccessToken == "" {
		t.Fatalf("AccessToken is empty")
	}
	if res.RefreshToken == "" {
		t.Fatalf("RefreshToken is empty")
	}
	if res.Token != res.AccessToken {
		t.Fatalf("legacy token field must mirror access_token")
	}
	if res.ExpiresIn != int(security.DefaultAccessExpireMinutes*60) {
		t.Fatalf("unexpected expires_in: %d", res.ExpiresIn)
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

// TestAuthService_RefreshAndLogout menguji siklus hidup refresh token (Opsi A):
// rotasi sekali pakai, deteksi pemakaian ulang, logout per perangkat, dan
// logout semua perangkat.
func TestAuthService_RefreshAndLogout(t *testing.T) {
	// Perilaku ketat: setiap pemakaian ulang token yang sudah dirotasi langsung
	// dianggap pencurian (jendela toleransi replay dimatikan).
	previousWindow := service.RotationReplayWindow
	service.RotationReplayWindow = 0
	defer func() { service.RotationReplayWindow = previousWindow }()

	cfg := &config.Config{
		RedisHost: "localhost:9999", // Trigger fallback in-memory cache
	}

	userRepo := newMockUserRepo()
	hasher := security.NewBcryptHasher()
	jwtMgr := security.NewJWTManager(
		"test-secret-key-12345678901234567890",
		security.DefaultAccessExpireMinutes,
		security.DefaultRefreshExpireHours,
	)
	store := cache.NewRedisClient(cfg) // whitelist refresh token (fallback in-memory)
	authSvc := service.NewAuthService(userRepo, hasher, jwtMgr, store, store, &mockEmailSender{})
	ctx := context.Background()

	password := "password123"
	passwordHash, err := hasher.HashPassword(password)
	if err != nil {
		t.Fatalf("HashPassword failed: %v", err)
	}

	user := &domain.User{
		ID:           uuid.New(),
		Name:         "Refresh User",
		Email:        "refresh@example.com",
		PasswordHash: passwordHash,
		Role:         domain.RoleUser,
		IsActive:     true,
	}
	if err := userRepo.Create(ctx, user); err != nil {
		t.Fatalf("Create user failed: %v", err)
	}

	// 1. Login -> access token + refresh token berumur 14 hari
	session, err := authSvc.Login(ctx, dto.LoginRequest{Email: user.Email, Password: password})
	if err != nil {
		t.Fatalf("Login failed: %v", err)
	}
	if session.AccessToken == "" || session.RefreshToken == "" {
		t.Fatalf("Login must return both access and refresh token")
	}
	if session.ExpiresIn != int(security.DefaultAccessExpireMinutes*60) {
		t.Fatalf("unexpected access token lifetime: %d seconds", session.ExpiresIn)
	}

	refreshClaims, err := jwtMgr.ValidateRefreshToken(session.RefreshToken)
	if err != nil {
		t.Fatalf("refresh token should be valid: %v", err)
	}
	if got := refreshClaims.ExpiresAt.Time.Sub(refreshClaims.IssuedAt.Time).Hours(); got < 335 || got > 337 {
		t.Fatalf("refresh token lifetime should be ~336h (14 days), got %.1fh", got)
	}

	// 2. Refresh token TIDAK boleh dipakai mengakses endpoint protected
	if _, err := jwtMgr.ValidateAccessToken(session.RefreshToken); err == nil {
		t.Fatalf("refresh token must not be accepted as an access token")
	}

	// 3. Refresh -> dapat pasangan token baru, refresh token lama dirotasi
	refreshed, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: session.RefreshToken})
	if err != nil {
		t.Fatalf("Refresh failed: %v", err)
	}
	if refreshed.AccessToken == "" || refreshed.RefreshToken == "" {
		t.Fatalf("Refresh must return a new token pair")
	}
	if refreshed.RefreshToken == session.RefreshToken {
		t.Fatalf("refresh token must be rotated on every refresh")
	}

	// 4. Pemakaian ulang refresh token lama harus ditolak (reuse detection)
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: session.RefreshToken}); !errors.Is(err, domain.ErrRefreshTokenRevoked) {
		t.Fatalf("expected ErrRefreshTokenRevoked on reuse, got %v", err)
	}

	// 5. Deteksi reuse mencabut SEMUA sesi -> refresh token hasil rotasi juga mati
	//    (statusnya kini "unknown" karena dicabut semua, bukan tombstone rotasi).
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: refreshed.RefreshToken}); !errors.Is(err, domain.ErrInvalidRefreshToken) && !errors.Is(err, domain.ErrRefreshTokenRevoked) {
		t.Fatalf("all sessions must be revoked after reuse detection, got %v", err)
	}

	// 6. Logout satu perangkat hanya mencabut token itu
	session, err = authSvc.Login(ctx, dto.LoginRequest{Email: user.Email, Password: password})
	if err != nil {
		t.Fatalf("second Login failed: %v", err)
	}
	otherSession, err := authSvc.Login(ctx, dto.LoginRequest{Email: user.Email, Password: password})
	if err != nil {
		t.Fatalf("third Login failed: %v", err)
	}

	if err := authSvc.Logout(ctx, user.ID, session.RefreshToken); err != nil {
		t.Fatalf("Logout failed: %v", err)
	}
	// Token yang sudah di-logout hanya ditolak biasa (bukan indikasi pencurian),
	// jadi perangkat lain TIDAK ikut tercabut.
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: session.RefreshToken}); !errors.Is(err, domain.ErrInvalidRefreshToken) {
		t.Fatalf("logged-out refresh token must be rejected, got %v", err)
	}
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: otherSession.RefreshToken}); err != nil {
		t.Fatalf("logout on one device must not revoke other sessions: %v", err)
	}

	// 7. Logout dengan refresh token ngawur (sudah tidak valid) harus tetap
	//    mencabut semua sesi supaya tidak ada token yatim di server.
	session, err = authSvc.Login(ctx, dto.LoginRequest{Email: user.Email, Password: password})
	if err != nil {
		t.Fatalf("Login before invalid logout failed: %v", err)
	}
	if err := authSvc.Logout(ctx, user.ID, "bukan-refresh-token"); err != nil {
		t.Fatalf("Logout with invalid token should succeed: %v", err)
	}
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: session.RefreshToken}); err == nil {
		t.Fatalf("logout with invalid token must revoke all sessions")
	}

	// 8. Logout tanpa refresh token = cabut semua sesi
	session, err = authSvc.Login(ctx, dto.LoginRequest{Email: user.Email, Password: password})
	if err != nil {
		t.Fatalf("Login after logout failed: %v", err)
	}
	if err := authSvc.Logout(ctx, user.ID, ""); err != nil {
		t.Fatalf("Logout all devices failed: %v", err)
	}
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: session.RefreshToken}); !errors.Is(err, domain.ErrInvalidRefreshToken) {
		t.Fatalf("logout all must revoke every session, got %v", err)
	}

	// 9. Token ngawur harus ditolak sebagai refresh token tidak valid
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: "bukan-jwt"}); !errors.Is(err, domain.ErrInvalidRefreshToken) {
		t.Fatalf("expected ErrInvalidRefreshToken for garbage token, got %v", err)
	}
}

// TestAuthService_RefreshReplayWithinGraceWindow memastikan balapan antar-klien
// (dua tab browser / web + HP memakai refresh token yang sama hampir bersamaan)
// TIDAK mencabut sesi siapa pun — bug yang muncul kalau jendela toleransi replay
// tidak ada.
func TestAuthService_RefreshReplayWithinGraceWindow(t *testing.T) {
	cfg := &config.Config{
		RedisHost: "localhost:9999", // Trigger fallback in-memory cache
	}

	userRepo := newMockUserRepo()
	hasher := security.NewBcryptHasher()
	jwtMgr := security.NewJWTManager(
		"test-secret-key-12345678901234567890",
		security.DefaultAccessExpireMinutes,
		security.DefaultRefreshExpireHours,
	)
	store := cache.NewRedisClient(cfg)
	authSvc := service.NewAuthService(userRepo, hasher, jwtMgr, store, store, &mockEmailSender{})
	ctx := context.Background()

	password := "password123"
	passwordHash, _ := hasher.HashPassword(password)
	user := &domain.User{
		ID:           uuid.New(),
		Name:         "Race User",
		Email:        "race@example.com",
		PasswordHash: passwordHash,
		Role:         domain.RoleUser,
		IsActive:     true,
	}
	if err := userRepo.Create(ctx, user); err != nil {
		t.Fatalf("Create user failed: %v", err)
	}

	if service.RotationReplayWindow <= 0 {
		t.Skip("jendela toleransi replay dimatikan, tes balapan tidak berlaku")
	}

	// Sesi perangkat lain yang TIDAK boleh ikut tercabut.
	otherSession, err := authSvc.Login(ctx, dto.LoginRequest{Email: user.Email, Password: password})
	if err != nil {
		t.Fatalf("Login failed: %v", err)
	}
	session, err := authSvc.Login(ctx, dto.LoginRequest{Email: user.Email, Password: password})
	if err != nil {
		t.Fatalf("second Login failed: %v", err)
	}

	// Klien A memakai refresh token -> token itu dirotasi.
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: session.RefreshToken}); err != nil {
		t.Fatalf("first refresh failed: %v", err)
	}

	// Klien B (balapan) memakai refresh token yang SAMA sesaat setelahnya.
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: session.RefreshToken}); err != nil {
		t.Fatalf("replay inside grace window must be tolerated, got %v", err)
	}

	// Tidak boleh ada pencabutan massal: sesi perangkat lain tetap hidup.
	if _, err := authSvc.Refresh(ctx, dto.RefreshRequest{RefreshToken: otherSession.RefreshToken}); err != nil {
		t.Fatalf("grace window replay must not revoke other sessions: %v", err)
	}
}
