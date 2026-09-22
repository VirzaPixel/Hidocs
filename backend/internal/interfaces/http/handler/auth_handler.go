package handler

import (
	"backend/internal/application/dto"
	"backend/internal/application/service"
	"backend/pkg/response"
	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService service.AuthService
}

func NewAuthHandler(authService service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// Register godoc
// @Summary Register user & send 6-digit OTP code to email
// @Description Register a new user account. Generates a 6-digit OTP stored in Redis for 180 seconds.
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body dto.RegisterRequest true "Register Payload"
// @Success 200 {object} response.APIResponse
// @Failure 400 {object} response.APIResponse
// @Router /api/v1/auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	msg, err := h.authService.Register(c.Request.Context(), req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, msg, gin.H{"email": req.Email, "otp_expires_in_seconds": 180})
}

// VerifyOTP godoc
// @Summary Verify OTP code and activate registration
// @Description Validate 6-digit OTP code stored in Redis and return JWT Token
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body dto.VerifyOTPRequest true "Verify OTP Payload"
// @Success 200 {object} response.APIResponse{data=dto.AuthResponse}
// @Failure 400 {object} response.APIResponse
// @Router /api/v1/auth/verify-otp [post]
func (h *AuthHandler) VerifyOTP(c *gin.Context) {
	var req dto.VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	res, err := h.authService.VerifyOTP(c.Request.Context(), req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "OTP verification successful. Welcome to HiDocs!", res)
}

// ResendOTP godoc
// @Summary Resend 6-digit OTP code
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body dto.ResendOTPRequest true "Resend OTP Payload"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/auth/resend-otp [post]
func (h *AuthHandler) ResendOTP(c *gin.Context) {
	var req dto.ResendOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	if err := h.authService.ResendOTP(c.Request.Context(), req); err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "A new OTP code has been sent to your email.", gin.H{"email": req.Email, "otp_expires_in_seconds": 180})
}

// Login godoc
// @Summary Login user
// @Description Authenticate user and return JWT token
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body dto.LoginRequest true "Login Payload"
// @Success 200 {object} response.APIResponse{data=dto.AuthResponse}
// @Failure 401 {object} response.APIResponse
// @Router /api/v1/auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	res, err := h.authService.Login(c.Request.Context(), req)
	if err != nil {
		response.Unauthorized(c, err.Error(), err)
		return
	}

	response.OK(c, "Login successful", res)
}

// ForgotPassword godoc
// @Summary Request password reset
// @Description Generate password reset token
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body dto.ForgotPasswordRequest true "Forgot Password Payload"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/auth/forgot-password [post]
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	var req dto.ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	token, err := h.authService.ForgotPassword(c.Request.Context(), req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Password reset token generated successfully", gin.H{"reset_token": token})
}

// ResetPassword godoc
// @Summary Reset password
// @Description Reset user password using token
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body dto.ResetPasswordRequest true "Reset Password Payload"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/auth/reset-password [post]
func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var req dto.ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	if err := h.authService.ResetPassword(c.Request.Context(), req); err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Password has been reset successfully", nil)
}
