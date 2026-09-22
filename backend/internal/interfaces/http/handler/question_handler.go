package handler

import (
	"backend/internal/application/dto"
	"backend/internal/application/service"
	"backend/internal/infrastructure/security"
	"backend/internal/interfaces/http/middleware"
	"backend/pkg/response"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type QuestionHandler struct {
	questionService service.QuestionService
	formService     service.FormService
}

func NewQuestionHandler(qService service.QuestionService, fService service.FormService) *QuestionHandler {
	return &QuestionHandler{
		questionService: qService,
		formService:     fService,
	}
}

// GetQuestionsByFormID godoc
// @Summary List questions for a form
// @Tags Questions
// @Produce json
// @Security BearerAuth
// @Param form_id path string true "Form ID"
// @Success 200 {object} response.APIResponse{data=[]dto.QuestionDTO}
// @Router /api/v1/forms/{form_id}/questions [get]
func (h *QuestionHandler) GetQuestionsByFormID(c *gin.Context) {
	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID format", err)
		return
	}

	form, err := h.formService.GetFormByID(c.Request.Context(), formID)
	if err != nil {
		response.NotFound(c, err.Error(), err)
		return
	}

	response.OK(c, "Questions retrieved successfully", form.Questions)
}

// AddQuestion godoc
// @Summary Add a question to a form
// @Tags Questions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param form_id path string true "Form ID"
// @Param request body dto.CreateQuestionRequest true "Create Question Payload"
// @Success 201 {object} response.APIResponse{data=dto.QuestionDTO}
// @Router /api/v1/forms/{form_id}/questions [post]
func (h *QuestionHandler) AddQuestion(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID format", err)
		return
	}

	var req dto.CreateQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	q, err := h.questionService.AddQuestion(c.Request.Context(), claims.UserID, formID, req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.Created(c, "Question added successfully", q)
}

// UpdateQuestion godoc
// @Summary Update a question
// @Tags Questions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param question_id path string true "Question ID"
// @Param request body dto.UpdateQuestionRequest true "Update Question Payload"
// @Success 200 {object} response.APIResponse{data=dto.QuestionDTO}
// @Router /api/v1/questions/{question_id} [put]
func (h *QuestionHandler) UpdateQuestion(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	questionID, err := uuid.Parse(c.Param("question_id"))
	if err != nil {
		response.BadRequest(c, "Invalid question_id UUID format", err)
		return
	}

	var req dto.UpdateQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	q, err := h.questionService.UpdateQuestion(c.Request.Context(), claims.UserID, questionID, req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Question updated successfully", q)
}

// DeleteQuestion godoc
// @Summary Delete a question
// @Tags Questions
// @Security BearerAuth
// @Param question_id path string true "Question ID"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/questions/{question_id} [delete]
func (h *QuestionHandler) DeleteQuestion(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	questionID, err := uuid.Parse(c.Param("question_id"))
	if err != nil {
		response.BadRequest(c, "Invalid question_id UUID format", err)
		return
	}

	if err := h.questionService.DeleteQuestion(c.Request.Context(), claims.UserID, questionID); err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Question deleted successfully", nil)
}

// DeleteOption godoc
// @Summary Delete a question option
// @Tags Questions
// @Security BearerAuth
// @Param option_id path string true "Option ID"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/options/{option_id} [delete]
func (h *QuestionHandler) DeleteOption(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	optionID, err := uuid.Parse(c.Param("option_id"))
	if err != nil {
		response.BadRequest(c, "Invalid option_id UUID format", err)
		return
	}

	if err := h.questionService.DeleteOption(c.Request.Context(), claims.UserID, optionID); err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Question option deleted successfully", nil)
}

// UploadImage godoc
// @Summary Upload image attachment for questions
// @Tags Questions
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param image formData file true "Image File (JPG, PNG, GIF)"
// @Success 200 {object} response.APIResponse{data=dto.UploadImageResponse}
// @Router /api/v1/questions/upload-image [post]
func (h *QuestionHandler) UploadImage(c *gin.Context) {
	fileHeader, err := c.FormFile("image")
	if err != nil {
		response.BadRequest(c, "Image file is required", err)
		return
	}

	res, err := h.questionService.UploadQuestionImage(c.Request.Context(), fileHeader)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Image uploaded successfully to local storage", res)
}

// UploadMedia godoc
// @Summary Upload media attachment (Image, Audio, Video) for questions and options
// @Tags Questions
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param file formData file true "Media File (PNG, JPG, MP3, WAV, MP4, WEBM)"
// @Success 200 {object} response.APIResponse{data=dto.UploadMediaResponse}
// @Router /api/v1/questions/upload-media [post]
func (h *QuestionHandler) UploadMedia(c *gin.Context) {
	fileHeader, err := c.FormFile("file")
	if err != nil {
		// fallback to check 'media' or 'image' field
		var fileErr error
		fileHeader, fileErr = c.FormFile("media")
		if fileErr != nil {
			fileHeader, fileErr = c.FormFile("image")
			if fileErr != nil {
				response.BadRequest(c, "Media file is required (form-data field: 'file', 'media', or 'image')", err)
				return
			}
		}
	}

	res, err := h.questionService.UploadMedia(c.Request.Context(), fileHeader)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Media file uploaded successfully", res)
}
