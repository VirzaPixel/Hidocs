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

type AuthService interface {
	Register(ctx context.Context, req dto.RegisterRequest) (string, error)
	VerifyOTP(ctx context.Context, req dto.VerifyOTPRequest) (*dto.AuthResponse, error)
	ResendOTP(ctx context.Context, req dto.ResendOTPRequest) error
	Login(ctx context.Context, req dto.LoginRequest) (*dto.AuthResponse, error)
	ForgotPassword(ctx context.Context, req dto.ForgotPasswordRequest) (string, error)
	ResetPassword(ctx context.Context, req dto.ResetPasswordRequest) error
}

type authService struct {
	userRepo       domain.UserRepository
	passwordHasher security.PasswordHasher
	jwtManager     *security.JWTManager
	otpCache       cache.OTPCache
	emailSender    email.EmailSender
}

func NewAuthService(
	userRepo domain.UserRepository,
	hasher security.PasswordHasher,
	jwt *security.JWTManager,
	otpCache cache.OTPCache,
	emailSender email.EmailSender,
) AuthService {
	return &authService{
		userRepo:       userRepo,
		passwordHasher: hasher,
		jwtManager:     jwt,
		otpCache:       otpCache,
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

	// 6. Generate JWT Session Token
	token, err := s.jwtManager.GenerateToken(user)
	if err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
		Token: token,
		User: dto.UserResponse{
			ID:        user.ID,
			Name:      user.Name,
			Email:     user.Email,
			Role:      user.Role,
			IsActive:  user.IsActive,
			CreatedAt: user.CreatedAt,
		},
	}, nil
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

	token, err := s.jwtManager.GenerateToken(user)
	if err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
		Token: token,
		User: dto.UserResponse{
			ID:        user.ID,
			Name:      user.Name,
			Email:     user.Email,
			Role:      user.Role,
			AvatarURL: user.AvatarURL,
			IsActive:  user.IsActive,
			CreatedAt: user.CreatedAt,
		},
	}, nil
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

	_ = s.userRepo.DeletePasswordReset(ctx, user.Email)
	return nil
}
