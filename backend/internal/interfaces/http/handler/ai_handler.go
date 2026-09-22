package handler

import (
	"io"
	"strings"

	"backend/internal/application/dto"
	"backend/internal/application/service"
	"backend/internal/domain"
	"backend/internal/infrastructure/parser"
	"backend/internal/infrastructure/security"
	"backend/internal/interfaces/http/middleware"
	"backend/pkg/response"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AIHandler struct {
	ai         service.AIService
	docxParser *parser.DocxParser
	pdfParser  *parser.PDFParser
}

func NewAIHandler(ai service.AIService) *AIHandler {
	return &AIHandler{
		ai:         ai,
		docxParser: parser.NewDocxParser(),
		pdfParser:  parser.NewPDFParser(),
	}
}

// TemplatePrompt godoc
// @Summary Ambil template prompt pembuatan form dengan AI
// @Tags AI
// @Produce json
// @Security BearerAuth
// @Success 200 {object} response.APIResponse
// @Router /api/v1/ai/template-prompt [get]
func (h *AIHandler) TemplatePrompt(c *gin.Context) {
	response.OK(c, "AI prompt template", gin.H{"template": h.ai.TemplatePrompt()})
}

// GeneratePreview godoc
// @Summary Generate preview form dengan AI (tanpa simpan)
// @Tags AI
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body dto.AIGenerateFormRequest true "AI Generate Payload"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/ai/generate-preview [post]
func (h *AIHandler) GeneratePreview(c *gin.Context) {
	var req dto.AIGenerateFormRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", nil)
		return
	}
	preview, err := h.ai.GeneratePreview(c.Request.Context(), req)
	if err != nil {
		response.BadRequest(c, err.Error(), nil)
		return
	}
	response.OK(c, "AI preview generated", preview)
}

// CreateForm godoc
// @Summary Generate + simpan form dengan AI
// @Tags AI
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body dto.AIGenerateFormRequest true "AI Generate Payload"
// @Success 201 {object} response.APIResponse
// @Router /api/v1/ai/generate-form [post]
func (h *AIHandler) CreateForm(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)
	var req dto.AIGenerateFormRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", nil)
		return
	}
	res, err := h.ai.CreateFormFromAI(c.Request.Context(), claims.UserID, req)
	if err != nil {
		response.BadRequest(c, err.Error(), nil)
		return
	}
	response.Created(c, "AI form created as DRAFT", res)
}

// GradeEssay godoc
// @Summary Nilai satu jawaban essay dengan AI (semantik)
// @Tags AI
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body dto.AIGradeEssayRequest true "Grade Essay Payload"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/ai/grade-essay [post]
func (h *AIHandler) GradeEssay(c *gin.Context) {
	var req dto.AIGradeEssayRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", nil)
		return
	}
	res, err := h.ai.GradeEssay(c.Request.Context(), req)
	if err != nil {
		response.BadRequest(c, err.Error(), nil)
		return
	}
	response.OK(c, "Essay graded", res)
}

// GradeResponse godoc
// @Summary Nilai semua essay dalam satu response (milik creator)
// @Tags AI
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body dto.AIGradeResponseRequest true "Grade Response Payload"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/ai/grade-response [post]
func (h *AIHandler) GradeResponse(c *gin.Context) {
	claims := c.MustGet(middleware.UserContextKey).(*security.JWTClaims)
	var req dto.AIGradeResponseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request payload", nil)
		return
	}
	// Owner check dilakukan di service via userID.
	_ = domain.ErrForbidden
	res, err := h.ai.GradeResponseEssays(c.Request.Context(), claims.UserID, req)
	if err != nil {
		if err.Error() == "access forbidden" {
			response.Forbidden(c, "You do not have permission", nil)
			return
		}
		response.BadRequest(c, err.Error(), nil)
		return
	}
	response.OK(c, "Response essays graded", res)
}

// Transcribe godoc
// @Summary Speech-to-text: ubah audio menjadi prompt pembuatan form
// @Tags AI
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param audio formData file true "Audio (webm/mp3/wav/m4a, max 25MB)"
// @Success 200 {object} response.APIResponse
// @Router /api/v1/ai/transcribe [post]
func (h *AIHandler) Transcribe(c *gin.Context) {
	fileHeader, err := c.FormFile("audio")
	if err != nil {
		// Kompatibilitas: izinkan field "file" juga.
		fileHeader, err = c.FormFile("file")
	}
	if err != nil {
		response.BadRequest(c, "Audio file is required (field: audio)", nil)
		return
	}
	if fileHeader.Size > 25<<20 {
		response.BadRequest(c, "Audio too large: max 25 MB", nil)
		return
	}
	f, err := fileHeader.Open()
	if err != nil {
		response.BadRequest(c, "Failed to open audio", nil)
		return
	}
	defer f.Close()
	data, err := io.ReadAll(io.LimitReader(f, (25<<20)+1))
	if err != nil {
		response.BadRequest(c, "Failed to read audio", nil)
		return
	}
	mime := fileHeader.Header.Get("Content-Type")
	text, err := h.ai.Transcribe(c.Request.Context(), data, mime)
	if err != nil {
		response.BadRequest(c, err.Error(), nil)
		return
	}
	response.OK(c, "Audio transcribed. Gunakan 'transcript' sebagai raw_prompt ke /ai/generate-preview.", gin.H{
		"transcript": text,
		"next_step":  "POST /api/v1/ai/generate-preview dengan {\"raw_prompt\": \"<transcript>\"}",
		"response_id_hint": uuid.Nil.String(),
	})
}

// ExtractMaterial godoc
// @Summary Ekstrak teks mentah dari PDF/Word untuk dipakai sebagai materi AI
// @Description Dipakai fitur "lampirkan materi" di form AI generate — BEDA dari
// /forms/import-docx|import-pdf yang langsung mem-parsing jadi struktur soal.
// Endpoint ini cuma mengembalikan teks mentahnya, supaya frontend bisa
// menggabungkannya ke raw_prompt sebelum generate-preview/generate-form.
// @Tags AI
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param file formData file true "PDF atau Word (.pdf/.docx)"
// @Success 200 {object} response.APIResponse{data=object{text=string}}
// @Router /api/v1/ai/extract-material [post]
func (h *AIHandler) ExtractMaterial(c *gin.Context) {
	fileHeader, err := c.FormFile("file")
	if err != nil {
		response.BadRequest(c, "File is required", err)
		return
	}

	file, err := fileHeader.Open()
	if err != nil {
		response.BadRequest(c, "Failed to open file", err)
		return
	}
	defer file.Close()

	fileBytes, err := io.ReadAll(file)
	if err != nil {
		response.BadRequest(c, "Failed to read file", err)
		return
	}

	filename := strings.ToLower(fileHeader.Filename)
	var text string
	switch {
	case strings.HasSuffix(filename, ".pdf"):
		text, err = h.pdfParser.ExtractRawText(fileBytes)
	case strings.HasSuffix(filename, ".docx"):
		text, err = h.docxParser.ExtractRawText(fileBytes)
	default:
		response.BadRequest(c, "Format file tidak didukung untuk lampiran materi. Pakai .pdf atau .docx", nil)
		return
	}
	if err != nil {
		response.BadRequest(c, err.Error(), err)
		return
	}

	// Batasi panjang teks yang dikirim ke Gemini supaya tidak melebihi context
	// window / bikin prompt kemahalan. ~12000 karakter cukup untuk beberapa
	// halaman materi, cukup untuk generate soal darinya.
	const maxChars = 12000
	truncated := false
	if len(text) > maxChars {
		text = text[:maxChars]
		truncated = true
	}

	response.OK(c, "Materi berhasil diekstrak", gin.H{
		"text":      text,
		"truncated": truncated,
		"filename":  fileHeader.Filename,
	})
}
