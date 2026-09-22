package handler

import (
	"backend/internal/application/dto"
	"backend/internal/application/service"
	"backend/internal/domain"
	"backend/internal/infrastructure/security"
	"backend/internal/interfaces/http/middleware"
	"backend/pkg/pagination"
	"backend/pkg/response"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type QuestionBankHandler struct {
	bankService service.QuestionBankService
}

func NewQuestionBankHandler(bankService service.QuestionBankService) *QuestionBankHandler {
	return &QuestionBankHandler{bankService: bankService}
}

// List godoc
// @Summary List questions in the bank
// @Tags QuestionBank
// @Produce json
// @Security BearerAuth
// @Param subject query string false "Filter by subject"
// @Param topic query string false "Filter by topic"
// @Param difficulty query string false "EASY|MEDIUM|HARD"
// @Param question_type query string false "Filter by question type"
// @Param limit query int false "default 25, max 100"
// @Param offset query int false "default 0"
// @Success 200 {object} response.APIResponse{data=dto.PaginatedBankQuestionsDTO}
// @Router /api/v1/question-bank [get]
func (h *QuestionBankHandler) List(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	filter := domain.BankQuestionFilter{
		Subject:      c.Query("subject"),
		Topic:        c.Query("topic"),
		Difficulty:   domain.QuestionDifficulty(c.Query("difficulty")),
		QuestionType: domain.QuestionType(c.Query("question_type")),
	}
	pg := pagination.FromQuery(c, 25, 100)

	result, err := h.bankService.List(c.Request.Context(), claims.UserID, filter, pg)
	if err != nil {
		response.InternalServerError(c, "Failed to retrieve question bank", err)
		return
	}
	response.OK(c, "Question bank retrieved successfully", result)
}

// Create godoc
// @Summary Add a new question directly to the bank
// @Tags QuestionBank
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 201 {object} response.APIResponse{data=dto.BankQuestionDTO}
// @Router /api/v1/question-bank [post]
func (h *QuestionBankHandler) Create(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	var req dto.CreateBankQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	item, err := h.bankService.Create(c.Request.Context(), claims.UserID, req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}
	response.Created(c, "Question saved to bank", item)
}

// Update godoc
// @Summary Update a bank question
// @Tags QuestionBank
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Bank Question ID"
// @Success 200 {object} response.APIResponse{data=dto.BankQuestionDTO}
// @Router /api/v1/question-bank/{id} [put]
func (h *QuestionBankHandler) Update(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid id", err)
		return
	}

	var req dto.UpdateBankQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	item, err := h.bankService.Update(c.Request.Context(), claims.UserID, id, req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}
	response.OK(c, "Bank question updated", item)
}

// Delete godoc
// @Summary Delete a bank question
// @Tags QuestionBank
// @Produce json
// @Security BearerAuth
// @Param id path string true "Bank Question ID"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/question-bank/{id} [delete]
func (h *QuestionBankHandler) Delete(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid id", err)
		return
	}

	if err := h.bankService.Delete(c.Request.Context(), claims.UserID, id); err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}
	response.OK(c, "Bank question deleted", nil)
}

// AddToForm godoc
// @Summary Copy a bank question into a form as a new Question
// @Tags QuestionBank
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Bank Question ID"
// @Success 201 {object} response.APIResponse{data=dto.QuestionDTO}
// @Router /api/v1/question-bank/{id}/add-to-form [post]
func (h *QuestionBankHandler) AddToForm(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "Invalid id", err)
		return
	}

	var req dto.AddBankQuestionToFormRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "form_id is required", err)
		return
	}

	q, err := h.bankService.AddToForm(c.Request.Context(), claims.UserID, id, req.FormID)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}
	response.Created(c, "Question copied to form", q)
}

// SaveFromQuestion godoc
// @Summary Save an existing form question into the bank
// @Tags QuestionBank
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param question_id path string true "Question ID"
// @Success 201 {object} response.APIResponse{data=dto.BankQuestionDTO}
// @Router /api/v1/questions/{question_id}/save-to-bank [post]
func (h *QuestionBankHandler) SaveFromQuestion(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	questionID, err := uuid.Parse(c.Param("question_id"))
	if err != nil {
		response.BadRequest(c, "Invalid question_id", err)
		return
	}

	var req dto.SaveQuestionToBankRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	item, err := h.bankService.SaveFromQuestion(c.Request.Context(), claims.UserID, questionID, req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}
	response.Created(c, "Question saved to bank", item)
}
