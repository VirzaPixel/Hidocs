package handler

import (
	"backend/internal/application/dto"
	"backend/internal/application/service"
	"backend/pkg/response"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type PublicHandler struct {
	formService service.FormService
}

func NewPublicHandler(formService service.FormService) *PublicHandler {
	return &PublicHandler{formService: formService}
}

// GetPublicForm godoc
// @Summary Access public form by custom URL slug or short code
// @Tags Public
// @Produce json
// @Param short_code path string true "Custom URL Slug or Form ID"
// @Success 200 {object} response.APIResponse{data=dto.PublicFormDTO}
// @Router /api/v1/public/forms/{short_code} [get]
func (h *PublicHandler) GetPublicForm(c *gin.Context) {
	shortCode := c.Param("short_code")
	if shortCode == "" {
		response.BadRequest(c, "Short code or custom URL is required", nil)
		return
	}

	formDTO, err := h.formService.GetPublicForm(c.Request.Context(), shortCode)
	if err != nil {
		response.NotFound(c, err.Error(), err)
		return
	}

	response.OK(c, "Public form retrieved successfully", formDTO)
}

// GetFormQRCode godoc
// @Summary Generate QR Code URL for public form access
// @Tags Public
// @Produce json
// @Param short_code path string true "Custom URL Slug or Form ID"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/public/forms/{short_code}/qr [get]
func (h *PublicHandler) GetFormQRCode(c *gin.Context) {
	shortCode := c.Param("short_code")
	if shortCode == "" {
		response.BadRequest(c, "Short code or custom URL is required", nil)
		return
	}

	qrURL, err := h.formService.GetFormQRCode(c.Request.Context(), shortCode)
	if err != nil {
		response.NotFound(c, err.Error(), err)
		return
	}

	response.OK(c, "QR code generated successfully", gin.H{
		"short_code":  shortCode,
		"qr_code_url": qrURL,
	})
}

// VerifyExamToken godoc
// @Summary Verify exam passcode token and start/resume exam session
// @Tags Public
// @Accept json
// @Produce json
// @Param form_id path string true "Form ID"
// @Param request body dto.VerifyExamTokenRequest true "Verify Token Payload"
// @Success 200 {object} response.APIResponse{data=dto.VerifyExamTokenResponse}
// @Router /api/v1/public/forms/{form_id}/verify-token [post]
func (h *PublicHandler) VerifyExamToken(c *gin.Context) {
	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID format", err)
		return
	}

	var req dto.VerifyExamTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	res, err := h.formService.VerifyExamToken(c.Request.Context(), formID, req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Exam token verified successfully. You may begin the exam.", res)
}
