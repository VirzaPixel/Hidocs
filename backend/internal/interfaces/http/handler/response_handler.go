package handler

import (
	"fmt"
	"net/http"

	"backend/internal/application/dto"
	"backend/internal/application/service"
	"backend/internal/infrastructure/security"
	"backend/internal/interfaces/http/middleware"
	"backend/pkg/pagination"
	"backend/pkg/response"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ResponseHandler struct {
	responseService service.ResponseService
	exportService   service.ExportService
}

func NewResponseHandler(respService service.ResponseService, expService service.ExportService) *ResponseHandler {
	return &ResponseHandler{
		responseService: respService,
		exportService:   expService,
	}
}

// SubmitForm godoc
// @Summary Submit form / exam answers
// @Tags Responses
// @Accept json
// @Produce json
// @Param form_id path string true "Form ID"
// @Param request body dto.SubmitFormRequest true "Submit Form Payload"
// @Success 200 {object} response.APIResponse{data=dto.SubmitResponseResult}
// @Router /api/v1/forms/{form_id}/submit [post]
func (h *ResponseHandler) SubmitForm(c *gin.Context) {
	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID format", err)
		return
	}

	var req dto.SubmitFormRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	res, err := h.responseService.SubmitResponse(c.Request.Context(), formID, req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, res.Message, res)
}

// GetFormResponses godoc
// @Summary Get all responses for a form (paginated)
// @Tags Responses
// @Produce json
// @Security BearerAuth
// @Param form_id path string true "Form ID"
// @Param limit query int false "Items per page (default 25, max 100)"
// @Param offset query int false "Items to skip (default 0)"
// @Success 200 {object} response.APIResponse{data=dto.PaginatedResponsesDTO}
// @Router /api/v1/forms/{form_id}/responses [get]
func (h *ResponseHandler) GetFormResponses(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID format", err)
		return
	}

	// FIX: sebelumnya endpoint ini selalu menarik SEMUA response tanpa batas.
	// Default 25/halaman, maksimal 100/halaman supaya query tidak berat walau
	// form punya 800-1000 submission.
	pg := pagination.FromQuery(c, 25, 100)

	responses, total, err := h.responseService.GetFormResponses(c.Request.Context(), claims.UserID, formID, pg)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Responses retrieved successfully", dto.PaginatedResponsesDTO{
		Items:  responses,
		Total:  total,
		Limit:  pg.Limit,
		Offset: pg.Offset,
	})
}

// GetMySubmissions godoc
// @Summary Get current user's own form submissions
// @Tags Responses
// @Produce json
// @Security BearerAuth
// @Success 200 {object} response.APIResponse{data=[]dto.ResponseDetailDTO}
// @Router /api/v1/responses/me [get]
func (h *ResponseHandler) GetMySubmissions(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	submissions, err := h.responseService.GetMySubmissions(c.Request.Context(), claims.Email)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Submissions retrieved successfully", submissions)
}

// GetResponseByID godoc
// @Summary Get individual response details
// @Tags Responses
// @Produce json
// @Security BearerAuth
// @Param response_id path string true "Response ID"
// @Success 200 {object} response.APIResponse{data=dto.ResponseDetailDTO}
// @Router /api/v1/responses/{response_id} [get]
func (h *ResponseHandler) GetResponseByID(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	responseID, err := uuid.Parse(c.Param("response_id"))
	if err != nil {
		response.BadRequest(c, "Invalid response_id UUID format", err)
		return
	}

	resp, err := h.responseService.GetResponseByID(c.Request.Context(), claims.UserID, responseID)
	if err != nil {
		response.NotFound(c, err.Error(), err)
		return
	}

	response.OK(c, "Response detail retrieved successfully", resp)
}

// GradeResponse godoc
// @Summary Adjust score/grade manually for a response
// @Tags Responses
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param response_id path string true "Response ID"
// @Param request body dto.GradeResponseRequest true "Grade Payload"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/responses/{response_id}/grade [put]
func (h *ResponseHandler) GradeResponse(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	responseID, err := uuid.Parse(c.Param("response_id"))
	if err != nil {
		response.BadRequest(c, "Invalid response_id UUID format", err)
		return
	}

	var req dto.GradeResponseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	if err := h.responseService.GradeResponse(c.Request.Context(), claims.UserID, responseID, req); err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Grade updated successfully", nil)
}

// ExportResponses godoc
// @Summary Export form responses to Excel or CSV
// @Tags Responses
// @Security BearerAuth
// @Param form_id path string true "Form ID"
// @Param format query string false "Export format ('xlsx' or 'csv', default: 'xlsx')"
// @Success 200 {file} file
// @Router /api/v1/forms/{form_id}/export [get]
func (h *ResponseHandler) ExportResponses(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID format", err)
		return
	}

	format := c.DefaultQuery("format", "xlsx")

	if format == "csv" {
		data, filename, err := h.exportService.ExportCSV(c.Request.Context(), claims.UserID, formID)
		if err != nil {
			response.BadRequest(c, err.Error(), err)
			return
		}
		c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
		c.Data(http.StatusOK, "text/csv", data)
		return
	}

	data, filename, err := h.exportService.ExportExcel(c.Request.Context(), claims.UserID, formID)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
	c.Data(http.StatusOK, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", data)
}

// GetAnalytics godoc
// @Summary Get real-time analytics for charts (Pie Chart score distribution, Question accuracy bar charts)
// @Tags Analytics
// @Produce json
// @Security BearerAuth
// @Param form_id path string true "Form ID"
// @Success 200 {object} response.APIResponse{data=domain.FormAnalytics}
// @Router /api/v1/forms/{form_id}/analytics [get]
func (h *ResponseHandler) GetAnalytics(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID format", err)
		return
	}

	analytics, err := h.responseService.GetAnalytics(c.Request.Context(), claims.UserID, formID)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Analytics retrieved successfully", analytics)
}

// AutosaveAnswer godoc
// @Summary Autosave incremental student answer and flagged (ragu-ragu) state
// @Tags Public
// @Accept json
// @Produce json
// @Param response_id path string true "Response Session ID"
// @Param request body dto.AutosaveAnswerRequest true "Autosave Payload"
// @Success 200 {object} response.APIResponse{data=dto.AutosaveResponse}
// @Router /api/v1/public/responses/{response_id}/autosave [post]
func (h *ResponseHandler) AutosaveAnswer(c *gin.Context) {
	responseID, err := uuid.Parse(c.Param("response_id"))
	if err != nil {
		response.BadRequest(c, "Invalid response_id UUID format", err)
		return
	}

	var req dto.AutosaveAnswerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	res, err := h.responseService.AutosaveAnswer(c.Request.Context(), responseID, req)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Answer autosaved successfully", res)
}

// SendTelemetry godoc
// @Summary Send client telemetry events (tab switch, window blur, app background, screenshot, split screen)
// @Tags Public
// @Accept json
// @Produce json
// @Param response_id path string true "Response Session ID"
// @Param request body dto.TelemetryEventRequest true "Telemetry Event Payload"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/public/responses/{response_id}/telemetry [post]
func (h *ResponseHandler) SendTelemetry(c *gin.Context) {
	responseID, err := uuid.Parse(c.Param("response_id"))
	if err != nil {
		response.BadRequest(c, "Invalid response_id UUID format", err)
		return
	}

	var req dto.TelemetryEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	if err := h.responseService.SendTelemetry(c.Request.Context(), responseID, req); err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Telemetry event logged successfully", nil)
}

// GetSessionState godoc
// @Summary Get active exam session state and questions status (answered / flagged) for navigation
// @Tags Public
// @Produce json
// @Param response_id path string true "Response Session ID"
// @Success 200 {object} response.APIResponse{data=dto.SessionStateDTO}
// @Router /api/v1/public/responses/{response_id}/session [get]
func (h *ResponseHandler) GetSessionState(c *gin.Context) {
	responseID, err := uuid.Parse(c.Param("response_id"))
	if err != nil {
		response.BadRequest(c, "Invalid response_id UUID format", err)
		return
	}

	session, err := h.responseService.GetSessionState(c.Request.Context(), responseID)
	if err != nil {
		response.NotFound(c, err.Error(), err)
		return
	}

	response.OK(c, "Session state retrieved successfully", session)
}

// AcknowledgeWarning godoc
// @Summary Student acknowledges proctor warning after exam restart
// @Tags Public
// @Produce json
// @Param response_id path string true "Response Session ID"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/public/responses/{response_id}/acknowledge-warning [post]
func (h *ResponseHandler) AcknowledgeWarning(c *gin.Context) {
	responseID, err := uuid.Parse(c.Param("response_id"))
	if err != nil {
		response.BadRequest(c, "Invalid response_id UUID format", err)
		return
	}

	if err := h.responseService.AcknowledgeWarning(c.Request.Context(), responseID); err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Warning acknowledged. Exam resumed.", nil)
}

// GetLiveMonitoring godoc
// @Summary Creator live monitoring of active students taking the exam
// @Tags Live Monitoring
// @Produce json
// @Security BearerAuth
// @Param form_id path string true "Form ID"
// @Success 200 {object} response.APIResponse{data=[]dto.LiveMonitoringStudentDTO}
// @Router /api/v1/forms/{form_id}/live-monitoring [get]
func (h *ResponseHandler) GetLiveMonitoring(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID format", err)
		return
	}

	students, err := h.responseService.GetLiveMonitoring(c.Request.Context(), claims.UserID, formID)
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Live monitoring data retrieved successfully", students)
}

// RestartStudentSession godoc
// @Summary Creator restarts student exam attempt due to suspicious cheating behavior
// @Tags Live Monitoring
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param form_id path string true "Form ID"
// @Param response_id path string true "Response ID"
// @Param request body dto.RestartStudentSessionRequest true "Restart Reason Payload"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/forms/{form_id}/responses/{response_id}/restart [post]
func (h *ResponseHandler) RestartStudentSession(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)

	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID format", err)
		return
	}

	responseID, err := uuid.Parse(c.Param("response_id"))
	if err != nil {
		response.BadRequest(c, "Invalid response_id UUID format", err)
		return
	}

	var req dto.RestartStudentSessionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", err)
		return
	}

	if err := h.responseService.RestartStudentSession(c.Request.Context(), claims.UserID, formID, responseID, req); err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	response.OK(c, "Student exam attempt restarted successfully", nil)
}
