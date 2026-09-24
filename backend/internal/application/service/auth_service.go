package service

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"backend/internal/application/dto"
	"backend/internal/domain"
	"backend/internal/infrastructure/cache"
	"backend/internal/infrastructure/email"
	"backend/internal/infrastructure/security"
	"backend/pkg/utils"
	"github.com/google/uuid"
)

// rotationDetectionWindow adalah berapa lama penanda "sudah dirotasi" disimpan.
// Selama masa ini, bila token lama muncul lagi SETELAH jendela toleransi replay
// lewat, sistem menganggapnya indikasi pencurian token dan mencabut seluruh sesi
// user. Setelah jendela ini lewat, token lama dianggap sekadar kedaluwarsa
// (reject biasa, tanpa mencabut sesi lain).
const rotationDetectionWindow = 24 * time.Hour

// RotationReplayWindow adalah jendela toleransi pemakaian ulang refresh token
// TEPAT setelah rotasi. Alasannya: dua klien sah (dua tab browser, atau web +
// aplikasi HP) bisa memakai refresh token yang sama hampir bersamaan. Tanpa
// toleransi ini, panggilan kedua akan dianggap pencurian token dan seluruh sesi
// user tercabut padahal bukan serangan. Di dalam jendela ini token yang sudah
// dirotasi masih boleh ditukar dengan pasangan baru (tanpa mencabut sesi siapa
// pun); di luar jendela, pemakaian ulang tetap dianggap pencurian.
//
// Variabel (bukan const) supaya test bisa mempersempitnya. Nilai <= 0 mematikan
// toleransi (perilaku ketat: setiap pemakaian ulang = pencurian).
var RotationReplayWindow = 60 * time.Second

type AuthService interface {
	Register(ctx context.Context, req dto.RegisterRequest) (string, error)
	VerifyOTP(ctx context.Context, req dto.VerifyOTPRequest) (*dto.AuthResponse, error)
	ResendOTP(ctx context.Context, req dto.ResendOTPRequest) error
	Login(ctx context.Context, req dto.LoginRequest) (*dto.AuthResponse, error)
	// Refresh menerbitkan access token baru dari refresh token yang masih
	// valid, sekaligus memutar (rotate) refresh token lama menjadi yang baru.
	Refresh(ctx context.Context, req dto.RefreshRequest) (*dto.AuthResponse, error)
	// Logout mencabut refresh token. Bila refreshToken kosong, SELURUH sesi
	// user dicabut (logout dari semua perangkat).
	Logout(ctx context.Context, userID uuid.UUID, refreshToken string) error
	ForgotPassword(ctx context.Context, req dto.ForgotPasswordRequest) (string, error)
	ResetPassword(ctx context.Context, req dto.ResetPasswordRequest) error
}

type authService struct {
	userRepo       domain.UserRepository
	passwordHasher security.PasswordHasher
	jwtManager     *security.JWTManager
	otpCache       cache.OTPCache
	refreshStore   cache.RefreshTokenStore
	emailSender    email.EmailSender
}

func NewAuthService(
	userRepo domain.UserRepository,
	hasher security.PasswordHasher,
	jwt *security.JWTManager,
	otpCache cache.OTPCache,
	refreshStore cache.RefreshTokenStore,
	emailSender email.EmailSender,
) AuthService {
	return &authService{
		userRepo:       userRepo,
		passwordHasher: hasher,
		jwtManager:     jwt,
		otpCache:       otpCache,
		refreshStore:   refreshStore,
		emailSender:    emailSender,
	}
}

func (s *authService) Register(ctx context.Context, req dto.RegisterRequest) (string, error) {
	emailStr := strings.ToLower(strings.TrimSpace(req.Email))
	existing, _ := s.userRepo.GetByEmail(ctx, emailStr)
	if existing != nil {
		return "", domain.ErrUserAlreadyExists
	}

	hashedPassword, err := s.passwordHasher.HashPassword(req.Password)
	if err != nil {
		return "", err
	}

	// 1. Generate 6-digit OTP code
	otpCode := utils.RandomPin(6)

	// 2. Save OTP and pending user payload in Redis with 180-second TTL
	ttl := 180 * time.Second

	pendingData := map[string]string{
		"name":          req.Name,
		"email":         emailStr,
		"password_hash": hashedPassword,
	}
	jsonPayload, err := json.Marshal(pendingData)
	if err != nil {
		return "", err
	}

	if err := s.otpCache.SetOTP(ctx, emailStr, otpCode, ttl); err != nil {
		return "", err
	}
	if err := s.otpCache.SetPendingUser(ctx, emailStr, string(jsonPayload), ttl); err != nil {
		return "", err
	}

	// 3. Send OTP Code via SMTP
	go s.emailSender.SendOTPEmail(emailStr, otpCode)

	return "OTP code has been sent to your email. Valid for 180 seconds.", nil
}

func (s *authService) VerifyOTP(ctx context.Context, req dto.VerifyOTPRequest) (*dto.AuthResponse, error) {
	emailStr := strings.ToLower(strings.TrimSpace(req.Email))

	// 1. Fetch OTP from Redis
	storedOTP, err := s.otpCache.GetOTP(ctx, emailStr)
	if err != nil || storedOTP == "" {
		return nil, errors.New("OTP code has expired or is invalid. Please request a new OTP.")
	}

	// 2. Validate OTP code
	if storedOTP != req.OTPCode {
		return nil, errors.New("Invalid OTP code. Please check your email and try again.")
	}

	// 3. Fetch pending user payload from Redis
	pendingStr, err := s.otpCache.GetPendingUser(ctx, emailStr)
	if err != nil || pendingStr == "" {
		return nil, errors.New("Registration session expired. Please register again.")
	}

	var pendingData map[string]string
	if err := json.Unmarshal([]byte(pendingStr), &pendingData); err != nil {
		return nil, err
	}

	// 4. Create user in PostgreSQL DB
	user := &domain.User{
		ID:           uuid.New(),
		Name:         pendingData["name"],
		Email:        pendingData["email"],
		PasswordHash: pendingData["password_hash"],
		Role:         domain.RoleUser,
		IsActive:     true,
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}

	// 5. Delete OTP & pending data from Redis
	_ = s.otpCache.DeleteOTP(ctx, emailStr)

	// 6. Terbitkan sepasang token (access + refresh) dan simpan whitelist refresh
	return s.issueSession(ctx, user, user.AvatarURL)
}

// issueSession membuat access token + refresh token baru, menyimpan jti refresh
// token ke whitelist (Redis) dengan TTL seumur refresh token, lalu menyusun
// response. Dipakai oleh VerifyOTP, Login, dan Refresh supaya formatnya
// konsisten di semua endpoint.
func (s *authService) issueSession(ctx context.Context, user *domain.User, avatarURL string) (*dto.AuthResponse, error) {
	accessToken, err := s.jwtManager.GenerateAccessToken(user)
	if err != nil {
		return nil, err
	}

	refreshToken, jti, err := s.jwtManager.GenerateRefreshToken(user)
	if err != nil {
		return nil, err
	}

	// JWT bersifat stateless: tanpa langkah ini refresh token tetap valid
	// sampai exp-nya habis walau sudah di-logout, sehingga tidak bisa dicabut.
	if err := s.refreshStore.StoreRefreshToken(ctx, user.ID, jti, s.jwtManager.RefreshExpiresIn()); err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
		// Token = access token (kompatibel dengan klien lama yang baca `token`).
		Token:        accessToken,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    int(s.jwtManager.AccessExpiresIn().Seconds()),
		User: dto.UserResponse{
			ID:        user.ID,
			Name:      user.Name,
			Email:     user.Email,
			Role:      user.Role,
			AvatarURL: avatarURL,
			IsActive:  user.IsActive,
			CreatedAt: user.CreatedAt,
		},
	}, nil
}

// Refresh menukar refresh token yang valid dengan pasangan token baru.
//
// Alur (rotasi sekali pakai + deteksi pemakaian ulang):
//  1. Validasi signature, tipe token, dan masa berlaku refresh token.
//  2. Cek status jti di whitelist:
//     - active: lanjut rotasi.
//     - rotated_recently: baru saja dirotasi, masih di jendela toleransi replay. Ini yang terjadi saat dua klien sah memakai token sama hampir bersamaan, jadi permintaan tetap dilayani tanpa mencabut sesi siapa pun.
//     - rotated: sudah dirotasi dan jendela toleransi lewat = indikasi token dicuri, cabut SELURUH sesi user lalu tolak.
//     - unknown: sudah logout / dicabut / kedaluwarsa; tolak tanpa mengganggu sesi perangkat lain.
//  3. Rotasi: tandai token lama (penanda 24 jam + jendela grace), lalu terbitkan pasangan access + refresh baru.
func (s *authService) Refresh(ctx context.Context, req dto.RefreshRequest) (*dto.AuthResponse, error) {
	claims, err := s.jwtManager.ValidateRefreshToken(strings.TrimSpace(req.RefreshToken))
	if err != nil {
		return nil, domain.ErrInvalidRefreshToken
	}

	state, err := s.refreshStore.RefreshTokenState(ctx, claims.UserID, claims.ID)
	if err != nil {
		return nil, err
	}

	switch state {
	case cache.RefreshTokenRotated:
		// Token ini sudah dipakai sekali lalu dirotasi, dan jendela toleransi
		// sudah lewat — kemungkinan besar salinannya ada di tangan pihak lain.
		// Amankan akun dengan mencabut semua sesi.
		_ = s.refreshStore.RevokeAllRefreshTokens(ctx, claims.UserID)
		return nil, domain.ErrRefreshTokenRevoked
	case cache.RefreshTokenUnknown:
		// Sudah logout / dicabut / kedaluwarsa. Tidak perlu mencabut sesi lain
		// (perangkat lain milik user ini harus tetap bisa dipakai).
		return nil, domain.ErrInvalidRefreshToken
	case cache.RefreshTokenRotatedRecently:
		// Balapan antar-klien yang sah: lanjut menerbitkan pasangan token baru
		// tanpa mencabut apa pun. Tidak ada rotasi tambahan di sini supaya token
		// pengguna lain (yang sudah memegang hasil rotasi pertama) tetap valid.
		user, err := s.userRepo.GetByID(ctx, claims.UserID)
		if err != nil {
			return nil, domain.ErrUserNotFound
		}
		if !user.IsActive {
			_ = s.refreshStore.RevokeAllRefreshTokens(ctx, user.ID)
			return nil, domain.ErrForbidden
		}
		return s.issueSession(ctx, user, user.AvatarURL)
	}

	user, err := s.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		return nil, domain.ErrUserNotFound
	}
	if !user.IsActive {
		// Akun dinonaktifkan admin -> sesi tidak boleh diperpanjang lagi.
		_ = s.refreshStore.RevokeAllRefreshTokens(ctx, user.ID)
		return nil, domain.ErrForbidden
	}

	// Rotasi: token lama hangus dan ditandai supaya pemakaian ulangnya bisa
	// dibedakan antara "balapan antar-klien" dan "token dicuri".
	if err := s.refreshStore.MarkRefreshTokenRotated(
		ctx, claims.UserID, claims.ID, rotationDetectionWindow, RotationReplayWindow,
	); err != nil {
		return nil, err
	}

	return s.issueSession(ctx, user, user.AvatarURL)
}

// Logout mencabut sesi pengguna. Bila refreshToken diberikan, hanya perangkat
// itu yang logout; bila kosong, semua perangkat milik user tersebut logout.
func (s *authService) Logout(ctx context.Context, userID uuid.UUID, refreshToken string) error {
	refreshToken = strings.TrimSpace(refreshToken)

	// Tanpa refresh token: treat as "logout dari semua perangkat".
	if refreshToken == "" {
		return s.refreshStore.RevokeAllRefreshTokens(ctx, userID)
	}

	claims, err := s.jwtManager.ValidateRefreshToken(refreshToken)
	if err != nil {
		// Token yang dikirim sudah tidak bisa dibaca (kedaluwarsa / cacat).
		// Karena pemanggil sudah terautentikasi lewat access token, cara aman
		// adalah mencabut SEMUA sesi user: ini mencegah refresh token hasil
		// rotasi yang dicabut sebagian tetap hidup di server (token yatim).
		return s.refreshStore.RevokeAllRefreshTokens(ctx, userID)
	}

	// Jangan biarkan user A mencabut sesi user B dengan menebak token.
	if claims.UserID != userID {
		return domain.ErrForbidden
	}

	state, err := s.refreshStore.RefreshTokenState(ctx, userID, claims.ID)
	if err != nil {
		return err
	}
	if state != cache.RefreshTokenActive {
		// Token yang dikirim valid tapi bukan token yang sedang aktif (mis. sudah
		// dirotasi). Cabut semua sesi user supaya tidak ada token yatim yang
		// tertinggal hidup di server.
		return s.refreshStore.RevokeAllRefreshTokens(ctx, userID)
	}

	return s.refreshStore.RevokeRefreshToken(ctx, userID, claims.ID)
}

func (s *authService) ResendOTP(ctx context.Context, req dto.ResendOTPRequest) error {
	emailStr := strings.ToLower(strings.TrimSpace(req.Email))

	pendingStr, err := s.otpCache.GetPendingUser(ctx, emailStr)
	if err != nil || pendingStr == "" {
		existing, _ := s.userRepo.GetByEmail(ctx, emailStr)
		if existing != nil {
			return errors.New("User is already registered and verified. Please login.")
		}
		return errors.New("No pending registration found for this email")
	}

	otpCode := utils.RandomPin(6)
	ttl := 180 * time.Second

	if err := s.otpCache.SetOTP(ctx, emailStr, otpCode, ttl); err != nil {
		return err
	}
	if err := s.otpCache.SetPendingUser(ctx, emailStr, pendingStr, ttl); err != nil {
		return err
	}

	go s.emailSender.SendOTPEmail(emailStr, otpCode)
	return nil
}

func (s *authService) Login(ctx context.Context, req dto.LoginRequest) (*dto.AuthResponse, error) {
	emailStr := strings.ToLower(strings.TrimSpace(req.Email))
	user, err := s.userRepo.GetByEmail(ctx, emailStr)
	if err != nil {
		return nil, domain.ErrInvalidCredentials
	}

	if !user.IsActive {
		return nil, domain.ErrForbidden
	}

	if !s.passwordHasher.ComparePassword(user.PasswordHash, req.Password) {
		return nil, domain.ErrInvalidCredentials
	}

	// Terbitkan access token (umur pendek) + refresh token (umur panjang) baru.
	return s.issueSession(ctx, user, user.AvatarURL)
}

func (s *authService) ForgotPassword(ctx context.Context, req dto.ForgotPasswordRequest) (string, error) {
	emailStr := strings.ToLower(strings.TrimSpace(req.Email))
	user, err := s.userRepo.GetByEmail(ctx, emailStr)
	if err != nil {
		return "", domain.ErrUserNotFound
	}

	token := utils.RandomString(32)
	reset := &domain.PasswordReset{
		ID:        uuid.New(),
		Email:     user.Email,
		Token:     token,
		ExpiresAt: time.Now().Add(1 * time.Hour),
	}

	_ = s.userRepo.DeletePasswordReset(ctx, user.Email)
	if err := s.userRepo.CreatePasswordReset(ctx, reset); err != nil {
		return "", err
	}

	return token, nil
}

func (s *authService) ResetPassword(ctx context.Context, req dto.ResetPasswordRequest) error {
	reset, err := s.userRepo.GetPasswordResetByToken(ctx, req.Token)
	if err != nil {
		return domain.ErrInvalidToken
	}

	user, err := s.userRepo.GetByEmail(ctx, reset.Email)
	if err != nil {
		return domain.ErrUserNotFound
	}

	hashedPassword, err := s.passwordHasher.HashPassword(req.NewPassword)
	if err != nil {
		return err
	}

	user.PasswordHash = hashedPassword
	if err := s.userRepo.Update(ctx, user); err != nil {
		return err
	}

	// Keamanan: ganti password = semua sesi lama (token di HP/browser lain)
	// langsung dicabut supaya tidak tetap bisa dipakai.
	_ = s.refreshStore.RevokeAllRefreshTokens(ctx, user.ID)

	_ = s.userRepo.DeletePasswordReset(ctx, user.Email)
	return nil
}
