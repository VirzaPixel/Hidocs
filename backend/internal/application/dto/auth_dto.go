package dto

type RegisterRequest struct {
	Name     string `json:"name" binding:"required,min=2,max=100"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
}

type VerifyOTPRequest struct {
	Email   string `json:"email" binding:"required,email"`
	OTPCode string `json:"otp_code" binding:"required,len=6"`
}

type ResendOTPRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse dipakai endpoint login, verify-otp, dan refresh.
// Berisi sepasang token (Opsi A):
//   - Token / AccessToken : access token berumur pendek, dipakai sebagai
//     `Authorization: Bearer <token>` pada semua endpoint protected.
//   - RefreshToken        : token berumur panjang (default 14 hari) yang HANYA
//     boleh dikirim ke POST /api/v1/auth/refresh.
//
// Field `token` dipertahankan (legacy) berisi access token yang sama supaya
// klien web, aplikasi Android, dan load test k6 yang sudah ada tetap jalan.
type AuthResponse struct {
	Token        string       `json:"token"`
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
	TokenType    string       `json:"token_type"`
	ExpiresIn    int          `json:"expires_in"` // umur access token dalam detik
	User         UserResponse `json:"user"`
}

// RefreshRequest adalah payload POST /api/v1/auth/refresh.
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// LogoutRequest adalah payload POST /api/v1/auth/logout.
// RefreshToken bersifat opsional:
//   - diisi  -> hanya sesi/perangkat ini yang dicabut.
//   - kosong -> SEMUA sesi user dicabut (logout dari semua perangkat).
type LogoutRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type ResetPasswordRequest struct {
	Token       string `json:"token" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=6"`
}
