package service

import (
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"strings"
	"time"

	"backend/config"
	"backend/internal/application/dto"
	"backend/internal/domain"
	infraAI "backend/internal/infrastructure/ai"
	"backend/pkg/utils"
	"github.com/google/uuid"
)

type AIService interface {
	TemplatePrompt() string
	GeneratePreview(ctx context.Context, req dto.AIGenerateFormRequest) (*dto.AIGenerateFormPreview, error)
	CreateFormFromAI(ctx context.Context, userID uuid.UUID, req dto.AIGenerateFormRequest) (*dto.AIGenerateFormResponse, error)
	GradeEssay(ctx context.Context, req dto.AIGradeEssayRequest) (*dto.AIGradeEssayResponse, error)
	GradeResponseEssays(ctx context.Context, userID uuid.UUID, req dto.AIGradeResponseRequest) (*dto.AIGradeResponseResult, error)
	Transcribe(ctx context.Context, audio []byte, mimeType string) (string, error)
}

type aiService struct {
	cfg          *config.Config
	gemini       *infraAI.GeminiClient
	formRepo     domain.FormRepository
	questionRepo domain.QuestionRepository
	responseRepo domain.ResponseRepository
}

func NewAIService(cfg *config.Config, formRepo domain.FormRepository, questionRepo domain.QuestionRepository, responseRepo domain.ResponseRepository) AIService {
	var gKey, gModel string
	if cfg != nil {
		gKey, gModel = cfg.GeminiAPIKey, cfg.GeminiModel
	}
	return &aiService{
		cfg:          cfg,
		gemini:       infraAI.NewGeminiClient(gKey, gModel),
		formRepo:     formRepo,
		questionRepo: questionRepo,
		responseRepo: responseRepo,
	}
}

// TemplatePrompt adalah patokan yang bisa disesuaikan user di frontend.
func (s *aiService) TemplatePrompt() string {
	return `Buatkan form/kuis dengan ketentuan berikut:

Materi: [contoh: Sistem Pernapasan Manusia kelas 8]
Jumlah soal: [contoh: 10]
Jenis soal:
- PG (MULTIPLE_CHOICE): [contoh: 5 soal, 4 opsi jawaban A-D, 10 poin per soal]
- Essay (LONG_TEXT): [contoh: 3 soal, 20 poin per soal + kunci jawaban]
- Checkbox (CHECKBOXES): [contoh: 1 soal, 4 opsi, bisa lebih dari 1 benar]
- Menjodohkan (MATCHING): [contoh: 1 soal, 4 pasangan]
Tingkat kesulitan: [Mudah/Sedang/Sulit/Campuran]
Bahasa: [Indonesia]
Durasi: [contoh: 60 menit]

Ketentuan khusus:
- Untuk PG: sertakan 1 jawaban benar (is_correct=true) dan pengecoh yang masuk akal.
- Untuk essay: sertakan answer_key_text (kunci jawaban) yang lengkap.
- Untuk menjodohkan: tiap opsi punya match_key dan match_target_text.
- Jika saya melampirkan gambar/audio/video, sematkan URL-nya ke ImgURL/AudioURL/VideoURL soal atau opsi yang relevan.

Contoh attachment:
- IMAGE https://.../diagram.png : "Diagram paru-paru, pakai untuk soal PG no 1-2"
- AUDIO https://.../instruksi.mp3 : "Instruksi listening untuk soal essay no 8"

Keluarkan HANYA JSON valid tanpa penjelasan, dengan skema:
{"title":"...","description":"...","questions":[{"question_text":"...","question_type":"MULTIPLE_CHOICE|CHECKBOXES|DROPDOWN|YES_NO|SHORT_TEXT|LONG_TEXT|MATCHING|MATH|CODE|RATING","points":10,"options":[{"option_text":"...","is_correct":true}],"answer_key_text":"..."}]}`
}

func (s *aiService) buildPrompt(req dto.AIGenerateFormRequest) string {
	var sb strings.Builder
	sb.WriteString("Kamu adalah HiDocs Master Assessment Generator AI, sistem pembuat kuis, soal ujian, dan form evaluasi berstandar tinggi.\n")
	sb.WriteString("Tugas utama Anda adalah membuat form ujian yang SANGAT AKURAT, BERKUALITAS TINGGI, LENGKAP, dan PRESISI sesuai dengan spesifikasi dan materi yang diminta user.\n\n")
	sb.WriteString("PERATURAN UTAMA KELUARAN (STRICT JSON ONLY):\n")
	sb.WriteString("1. Keluarkan HANYA JSON valid yang memenuhi skema tanpa teks pembuka, penjelasan, atau markdown tambahan di luar JSON.\n")
	sb.WriteString("2. Pastikan karakter khusus di dalam string JSON di-escape dengan benar (misal `\\n` untuk baris baru, `\\\"` untuk tanda kutip dua, terutama pada potongan kode program).\n")
	sb.WriteString("3. Skema JSON:\n")
	sb.WriteString("{\n")
	sb.WriteString("  \"title\": \"Judul Form Yang Menarik & Profesional\",\n")
	sb.WriteString("  \"description\": \"Deskripsi / Petunjuk Pengerjaan Ujian\",\n")
	sb.WriteString("  \"questions\": [\n")
	sb.WriteString("    {\n")
	sb.WriteString("      \"question_text\": \"Teks Soal / Pertanyaan\",\n")
	sb.WriteString("      \"question_type\": \"MULTIPLE_CHOICE|CHECKBOXES|DROPDOWN|YES_NO|SHORT_TEXT|LONG_TEXT|MATCHING|RATING\",\n")
	sb.WriteString("      \"points\": 10,\n")
	sb.WriteString("      \"code_language\": \"javascript|python|java|cpp|sql|css|html (opsional, jika mengandung kode)\",\n")
	sb.WriteString("      \"img_url\": \"...\", \"audio_url\": \"...\", \"video_url\": \"...\",\n")
	sb.WriteString("      \"options\": [\n")
	sb.WriteString("        {\"option_text\": \"Opsi A\", \"is_correct\": true, \"match_key\": \"K1\", \"match_target_text\": \"Target K1\"}\n")
	sb.WriteString("      ],\n")
	sb.WriteString("      \"answer_key_text\": \"Kunci jawaban / pembahasan lengkap (wajib untuk LONG_TEXT/SHORT_TEXT)\"\n")
	sb.WriteString("    }\n")
	sb.WriteString("  ]\n")
	sb.WriteString("}\n\n")
	sb.WriteString("ATURAN STRICT TIPE SOAL (QUESTION_TYPE):\n")
	sb.WriteString("1. PILIHAN GANDA (PG / Multiple Choice, termasuk soal Matematika PG & Koding PG):\n")
	sb.WriteString("   - WAJIB gunakan question_type=\"MULTIPLE_CHOICE\".\n")
	sb.WriteString("   - WAJIB sertakan 4 opsi jawaban di array options (A, B, C, D) dengan TEPAT 1 opsi is_correct=true.\n")
	sb.WriteString("2. ESAI / URAIAN (Essay, termasuk soal Matematika Esai & Koding Esai):\n")
	sb.WriteString("   - WAJIB gunakan question_type=\"LONG_TEXT\".\n")
	sb.WriteString("   - array options WAJIB kosong [].\n")
	sb.WriteString("   - WAJIB isi answer_key_text dengan pembahasan dan kunci jawaban yang lengkap.\n")
	sb.WriteString("3. ISIAN SINGKAT:\n")
	sb.WriteString("   - gunakan question_type=\"SHORT_TEXT\", options kosong [], isi answer_key_text.\n")
	sb.WriteString("4. KOTAK CENTANG (CHECKBOXES):\n")
	sb.WriteString("   - gunakan question_type=\"CHECKBOXES\", sertakan options dengan >= 1 is_correct=true.\n")
	sb.WriteString("5. MENJODOHKAN (MATCHING):\n")
	sb.WriteString("   - gunakan question_type=\"MATCHING\", sertakan options dengan match_key dan match_target_text.\n")
	sb.WriteString("6. SOAL MATEMATIKA:\n")
	sb.WriteString("   - Tulis rumus Matematika menggunakan sintaks LaTeX standar `\\(...\\)` atau `$$...$$` pada `question_text`, `option_text`, maupun `answer_key_text`.\n")
	sb.WriteString("7. SOAL KODING:\n")
	sb.WriteString("   - Tulis potongan kode program yang rapi di `question_text` menggunakan blok kode ```language ... ``` dan set code_language.\n")
	sb.WriteString("8. EFISIENSI OUTPUT UNTUK JUMLAH SOAL BANYAK:\n")
	sb.WriteString("   - Jika diminta membuat banyak soal (misal 20-50 soal), buat teks soal, opsi jawaban, dan penjelasan secara to the point, padat, dan jelas agar seluruh butir soal selesai lengkap dalam batas token.\n\n")

	if req.Subject != "" || req.Topic != "" {
		fmt.Fprintf(&sb, "MATERI & METADATA UJIAN:\n- Mata Pelajaran: %s\n- Topik/Bab: %s\n- Jenjang/Kelas: %s\n- Bahasa: %s\n- Tingkat Kesulitan: %s\n\n",
			req.Subject, req.Topic, req.GradeLevel, defaultStr(req.Language, "Indonesia"), defaultStr(req.Difficulty, "Campuran"))
	}
	if len(req.Specs) > 0 {
		sb.WriteString("KOMPOSISI & SPESIFIKASI SOAL:\n")
		for _, sp := range req.Specs {
			fmt.Fprintf(&sb, "- Tipe %s: %d soal, %d poin per soal", sp.QuestionType, sp.Count, sp.PointsEach)
			if sp.OptionCount > 0 {
				fmt.Fprintf(&sb, ", %d opsi per soal", sp.OptionCount)
			}
			sb.WriteString("\n")
		}
		sb.WriteString("\n")
	}
	if len(req.Attachments) > 0 {
		sb.WriteString("ATTACHMENT MEDIA (Sematkan URL persis ke `img_url`/`audio_url`/`video_url` soal/opsi yang relevan):\n")
		for _, a := range req.Attachments {
			fmt.Fprintf(&sb, "- %s %s (%s) target=%s\n", a.MediaType, a.URL, a.Description, a.Target)
		}
		sb.WriteString("\n")
	}
	if strings.TrimSpace(req.RawPrompt) != "" {
		sb.WriteString("INSTRUKSI KHUSUS & MATERI USER:\n" + strings.TrimSpace(req.RawPrompt) + "\n\n")
	}

	sb.WriteString("SEKARANG, HASILKAN JSON UTUH DAN VALID TERSEBUT:")
	return sb.String()
}

func defaultStr(s, fb string) string {
	if strings.TrimSpace(s) == "" {
		return fb
	}
	return s
}

func (s *aiService) GeneratePreview(ctx context.Context, req dto.AIGenerateFormRequest) (*dto.AIGenerateFormPreview, error) {
	if strings.TrimSpace(req.RawPrompt) == "" && strings.TrimSpace(req.Subject) == "" && strings.TrimSpace(req.Topic) == "" && len(req.Specs) == 0 {
		return nil, fmt.Errorf("subject/topic/specs atau raw_prompt wajib diisi")
	}
	for _, sp := range req.Specs {
		if !validQuestionType(sp.QuestionType) {
			return nil, fmt.Errorf("invalid question_type: %s", sp.QuestionType)
		}
	}
	if !s.gemini.IsEnabled() {
		return nil, fmt.Errorf("GEMINI_API_KEY belum diisi — generate AI tidak tersedia")
	}
	prompt := s.buildPrompt(req)
	var raw string
	var generateErr error
	for attempt := 0; attempt < 3; attempt++ {
		raw, generateErr = s.gemini.GenerateJSON(ctx, prompt)
		if generateErr == nil && strings.TrimSpace(raw) != "" {
			break
		}
		if attempt < 2 {
			select {
			case <-ctx.Done():
				break
			case <-time.After(500 * time.Millisecond):
			}
		}
	}
	if generateErr != nil || strings.TrimSpace(raw) == "" {
		return nil, fmt.Errorf("gagal generate AI (gemini): %v", generateErr)
	}
	preview, err := parsePreview(raw)
	if err != nil {
		return nil, fmt.Errorf("gagal memparse output AI (%v). Raw: %q", err, truncateAI(raw, 700))
	}
	normalizePreview(preview, req)
	if len(preview.Questions) == 0 {
		return nil, fmt.Errorf("output AI valid tapi tidak ada soal (questions kosong). Raw: %q", truncateAI(raw, 700))
	}
	return preview, nil
}

func (s *aiService) CreateFormFromAI(ctx context.Context, userID uuid.UUID, req dto.AIGenerateFormRequest) (*dto.AIGenerateFormResponse, error) {
	preview, err := s.GeneratePreview(ctx, req)
	if err != nil {
		return nil, err
	}
	category := req.Category
	if category == "" {
		category = "AI Generated"
	}
	form := &domain.Form{
		ID:          uuid.New(),
		UserID:      userID,
		Title:       preview.Title,
		Description: preview.Description,
		Category:    category,
		Type:        domain.TypeExam,
		CustomURL:   utils.GenerateSlug(preview.Title),
		Status:      domain.StatusDraft,
	}
	if err := s.formRepo.Create(ctx, form); err != nil {
		return nil, err
	}
	duration := req.TotalTime
	if duration <= 0 {
		duration = 60
	}
	_ = s.formRepo.UpsertFormSettings(ctx, &domain.FormSettings{
		ID: uuid.New(), FormID: form.ID, DurationMinutes: &duration,
		AutoActiveDays: 30, ThemeColor: "#4F46E5", FontFamily: "Inter",
		AllowBacktrack: true, ShowQuestionNumber: true,
	})

	var questions []domain.Question
	for i, q := range preview.Questions {
		qID := uuid.New()
		var answerKey *string
		if strings.TrimSpace(q.AnswerKeyText) != "" {
			ak := strings.TrimSpace(q.AnswerKeyText)
			answerKey = &ak
		}
		dq := domain.Question{
			ID: qID, FormID: form.ID, QuestionText: q.QuestionText,
			QuestionType: q.QuestionType, CodeLanguage: q.CodeLanguage,
			ImgURL: q.ImgURL, AudioURL: strPtr(q.AudioURL), VideoURL: strPtr(q.VideoURL),
			AnswerKey:    answerKey,
			IsAutoScored: q.QuestionType != domain.TypeLongText && q.QuestionType != domain.TypeShortText &&
				q.QuestionType != domain.TypeCode && q.QuestionType != domain.TypeMath,
			Points: q.Points, OrderIndex: i + 1, IsRequired: true,
		}
		for j, o := range q.Options {
			dq.Options = append(dq.Options, domain.QuestionOption{
				ID: uuid.New(), QuestionID: qID, OptionText: o.OptionText, IsCorrect: o.IsCorrect,
				ImgURL: strPtr(o.ImgURL), AudioURL: strPtr(o.AudioURL), VideoURL: strPtr(o.VideoURL),
				OrderIndex: j + 1,
			})
		}
		// MATCHING: pastikan match_key terisi agar bisa dinilai proporsional.
		if q.QuestionType == domain.TypeMatching {
			for j := range dq.Options {
				if dq.Options[j].MatchKey == nil || *dq.Options[j].MatchKey == "" {
					k := fmt.Sprintf("K%d", j+1)
					dq.Options[j].MatchKey = &k
					t := dq.Options[j].OptionText
					dq.Options[j].MatchTargetText = &t
				}
			}
		}
		questions = append(questions, dq)
	}
	if len(questions) > 0 {
		if err := s.questionRepo.CreateBatchQuestions(ctx, questions); err != nil {
			return nil, err
		}
	}
	formID := form.ID
	return &dto.AIGenerateFormResponse{Preview: *preview, FormID: &formID}, nil
}

func (s *aiService) GradeEssay(ctx context.Context, req dto.AIGradeEssayRequest) (*dto.AIGradeEssayResponse, error) {
	if req.MaxPoints < 0 {
		return nil, fmt.Errorf("max_points must be >= 0")
	}

	ansText := strings.TrimSpace(req.AnswerText)
	ansKey := strings.TrimSpace(req.AnswerKey)

	// TOKEN SAVING 1: Jawaban kosong langsung 0 tanpa panggil API AI
	if ansText == "" {
		res := &dto.AIGradeEssayResponse{
			Score:      0,
			MaxPoints:  req.MaxPoints,
			Similarity: 0,
			Feedback:   "Jawaban tidak diisi / kosong.",
		}
		if req.AutoPersist && req.ResponseID != nil {
			_ = s.persistEssayScore(ctx, *req.ResponseID, req.QuestionID, 0)
		}
		return res, nil
	}

	// TOKEN SAVING 2: Jawaban persis sama dengan kunci langsung poin penuh tanpa panggil API AI
	if ansKey != "" && strings.EqualFold(ansKey, ansText) {
		res := &dto.AIGradeEssayResponse{
			Score:      req.MaxPoints,
			MaxPoints:  req.MaxPoints,
			Similarity: 1.0,
			Feedback:   "Jawaban tepat dan sangat lengkap sesuai kunci jawaban.",
		}
		if req.AutoPersist && req.ResponseID != nil {
			_ = s.persistEssayScore(ctx, *req.ResponseID, req.QuestionID, req.MaxPoints)
		}
		return res, nil
	}

	if !s.gemini.IsEnabled() {
		return s.mockGrade(req)
	}

	prompt := fmt.Sprintf(`Peran: Penilai esai akademik yang adil, proporsional, dan bijaksana.
Tugas: Evaluasi kemiripan makna (semantik) antara Jawaban Murid dengan Kunci Jawaban & Rubrik acuan.

Kunci Jawaban: %s
Rubrik (Opsional): %s
Jawaban Murid: %s
Skor Maksimal: %.1f

Pedoman Penilaian:
- Nilai kesesuaian makna & konsep inti, jangan terpaku pada urutan kata.
- Berikan nilai proporsional / parsial (misal 50%%-85%%) jika murid menjawab sebagian poin penting dengan benar.
- Hanya berikan 0 jika jawaban murid benar-benar ngawur, menyimpang total, atau tidak relevan.
- Feedback maksimal 1 kalimat bahasa Indonesia yang ramah dan konstruktif.

Keluarkan HANYA JSON: {"score": <angka 0..%.1f>, "similarity": <0.0..1.0>, "feedback": "<penjelasan 1 kalimat>"}`,
		ansKey, req.Rubric, ansText, req.MaxPoints, req.MaxPoints)

	raw, err := s.gemini.GenerateJSON(ctx, prompt)
	if err != nil {
		return s.mockGrade(req)
	}

	var parsed struct {
		Score      float64 `json:"score"`
		Similarity float64 `json:"similarity"`
		Feedback   string  `json:"feedback"`
	}
	if err := json.Unmarshal([]byte(infraAI.HealJSON(raw)), &parsed); err != nil {
		return s.mockGrade(req)
	}
	if parsed.Score < 0 {
		parsed.Score = 0
	}
	if parsed.Score > req.MaxPoints {
		parsed.Score = req.MaxPoints
	}
	if parsed.Similarity < 0 {
		parsed.Similarity = 0
	}
	if parsed.Similarity > 1 {
		parsed.Similarity = 1
	}

	res := &dto.AIGradeEssayResponse{Score: parsed.Score, MaxPoints: req.MaxPoints, Similarity: parsed.Similarity, Feedback: parsed.Feedback}
	if req.AutoPersist && req.ResponseID != nil {
		_ = s.persistEssayScore(ctx, *req.ResponseID, req.QuestionID, parsed.Score)
	}
	return res, nil
}

func (s *aiService) GradeResponseEssays(ctx context.Context, userID uuid.UUID, req dto.AIGradeResponseRequest) (*dto.AIGradeResponseResult, error) {
	resp, err := s.responseRepo.GetResponseByID(ctx, req.ResponseID)
	if err != nil {
		return nil, err
	}
	if resp.Form != nil && resp.Form.UserID != userID {
		return nil, fmt.Errorf("access forbidden")
	}
	// Index jawaban per question.
	ansByQ := map[uuid.UUID]*domain.ResponseAnswer{}
	for i := range resp.Answers {
		qid := resp.Answers[i].QuestionID
		a := resp.Answers[i]
		ansByQ[qid] = &a
	}
	result := &dto.AIGradeResponseResult{}
	var totalAdded float64
	for _, ans := range resp.Answers {
		q := ans.Question
		if q == nil {
			continue
		}
		if q.QuestionType != domain.TypeLongText && q.QuestionType != domain.TypeShortText &&
			q.QuestionType != domain.TypeCode && q.QuestionType != domain.TypeMath {
			continue
		}
		key := ""
		if req.AnswerKeys != nil && strings.TrimSpace(req.AnswerKeys[ans.QuestionID]) != "" {
			key = strings.TrimSpace(req.AnswerKeys[ans.QuestionID])
		} else if q.AnswerKey != nil && strings.TrimSpace(*q.AnswerKey) != "" {
			key = strings.TrimSpace(*q.AnswerKey)
		}
		rubric := ""
		if q.Rubric != nil && strings.TrimSpace(*q.Rubric) != "" {
			rubric = strings.TrimSpace(*q.Rubric)
		}
		if strings.TrimSpace(ans.AnswerText) == "" {
			continue
		}
		max := float64(q.Points)
		var score float64
		var feedback string
		if s.gemini.IsEnabled() && strings.TrimSpace(key) != "" {
			g, err := s.GradeEssay(ctx, dto.AIGradeEssayRequest{
				QuestionID: ans.QuestionID, AnswerText: ans.AnswerText,
				AnswerKey: key, Rubric: rubric, MaxPoints: max,
			})
			if err == nil {
				score, feedback = g.Score, g.Feedback
			}
		} else {
			feedback = "Belum dinilai AI (kunci jawaban kosong atau GEMINI_API_KEY belum diisi). Perlu grading manual."
		}
		result.Items = append(result.Items, dto.AIGradeResponseItem{
			QuestionID: ans.QuestionID, Score: score, MaxPoints: max, Feedback: feedback,
		})
		totalAdded += score
		if req.AutoPersist {
			_ = s.persistEssayScore(ctx, req.ResponseID, ans.QuestionID, score)
		}
	}
	result.TotalAdded = totalAdded
	return result, nil
}

func (s *aiService) persistEssayScore(ctx context.Context, responseID, questionID uuid.UUID, score float64) error {
	// Ambil jawaban existing agar field lain tidak hilang, lalu upsert dengan ScoreGiven baru.
	existing, err := s.responseRepo.GetResponseByID(ctx, responseID)
	if err != nil {
		return err
	}
	var base *domain.ResponseAnswer
	for i := range existing.Answers {
		if existing.Answers[i].QuestionID == questionID {
			b := existing.Answers[i]
			base = &b
			break
		}
	}
	ans := &domain.ResponseAnswer{
		ID: uuid.New(), ResponseID: responseID, QuestionID: questionID, ScoreGiven: &score,
	}
	if base != nil {
		ans.ID = base.ID
		ans.SelectedOptionID = base.SelectedOptionID
		ans.AnswerText = base.AnswerText
		ans.IsFlagged = base.IsFlagged
		ans.MatchPairJSON = base.MatchPairJSON
	}
	return s.responseRepo.UpsertAnswer(ctx, ans)
}

func (s *aiService) Transcribe(ctx context.Context, audio []byte, mimeType string) (string, error) {
	if len(audio) == 0 {
		return "", fmt.Errorf("audio kosong")
	}
	if len(audio) > 25<<20 {
		return "", fmt.Errorf("audio terlalu besar: max 25 MB")
	}
	if !s.gemini.IsEnabled() {
		return "", fmt.Errorf("gemini api key not configured")
	}
	return s.gemini.TranscribeAudio(ctx, audio, mimeType)
}

// --- helpers ---

func validQuestionType(t domain.QuestionType) bool {
	switch t {
	case domain.TypeShortText, domain.TypeLongText, domain.TypeMultipleChoice,
		domain.TypeCheckboxes, domain.TypeDropdown, domain.TypeRating,
		domain.TypeYesNo, domain.TypeMath, domain.TypeCode,
		domain.TypeImage, domain.TypeMatching:
		return true
	}
	return false
}

func parsePreview(raw string) (*dto.AIGenerateFormPreview, error) {
	t := strings.TrimSpace(raw)
	if t == "" {
		return nil, fmt.Errorf("output AI kosong")
	}

	// 1. Coba unmarshal langsung
	var p dto.AIGenerateFormPreview
	if err := json.Unmarshal([]byte(t), &p); err == nil && len(p.Questions) > 0 {
		ensurePreviewDefaults(&p)
		return &p, nil
	}

	// 2. Coba sanitize dan heal JSON
	sanitized := infraAI.SanitizeJSON(t)
	healed := infraAI.HealJSON(sanitized)
	if err := json.Unmarshal([]byte(healed), &p); err == nil && len(p.Questions) > 0 {
		ensurePreviewDefaults(&p)
		return &p, nil
	}

	// 3. Coba unmarshal ke dynamic generic map / slice
	if dynPreview := parseDynamicPreview(healed); dynPreview != nil && len(dynPreview.Questions) > 0 {
		ensurePreviewDefaults(dynPreview)
		return dynPreview, nil
	}
	if dynPreview := parseDynamicPreview(sanitized); dynPreview != nil && len(dynPreview.Questions) > 0 {
		ensurePreviewDefaults(dynPreview)
		return dynPreview, nil
	}

	// 4. Fallback: Ekstraksi blok soal satu per satu (Question Block Scanner)
	// Jika JSON terpotong di tengah atau memiliki error sintaks lokal, strategi ini menyelamatkan semua soal yang valid
	if extractedPreview := extractQuestionsFromRaw(raw); extractedPreview != nil && len(extractedPreview.Questions) > 0 {
		ensurePreviewDefaults(extractedPreview)
		return extractedPreview, nil
	}

	if p.Title != "" || p.Description != "" {
		return &p, nil
	}

	return nil, fmt.Errorf("tidak dapat memparse struktur JSON soal")
}

func ensurePreviewDefaults(p *dto.AIGenerateFormPreview) {
	if strings.TrimSpace(p.Title) == "" {
		p.Title = "Asesmen Hasil AI"
	}
	if strings.TrimSpace(p.Description) == "" {
		p.Description = "Form evaluasi yang dibuat secara otomatis oleh AIDoc."
	}
}

func parseDynamicPreview(jsonStr string) *dto.AIGenerateFormPreview {
	var root any
	if err := json.Unmarshal([]byte(jsonStr), &root); err != nil {
		return nil
	}

	p := &dto.AIGenerateFormPreview{}

	switch v := root.(type) {
	case []any:
		for _, item := range v {
			if qMap, ok := item.(map[string]any); ok {
				if q := parseDynamicQuestion(qMap); q != nil {
					p.Questions = append(p.Questions, *q)
				}
			}
		}
	case map[string]any:
		p.Title = anyToString(v["title"], anyToString(v["judul"], "Asesmen Hasil AI"))
		p.Description = anyToString(v["description"], anyToString(v["deskripsi"], ""))

		var rawQuestions []any
		for _, k := range []string{"questions", "soal", "items", "data", "quiz", "daftar_soal", "pertanyaan"} {
			if arr, ok := v[k].([]any); ok && len(arr) > 0 {
				rawQuestions = arr
				break
			}
		}

		if len(rawQuestions) == 0 {
			if fMap, ok := v["form"].(map[string]any); ok {
				if arr, ok := fMap["questions"].([]any); ok {
					rawQuestions = arr
				}
			}
		}

		for _, item := range rawQuestions {
			if qMap, ok := item.(map[string]any); ok {
				if q := parseDynamicQuestion(qMap); q != nil {
					p.Questions = append(p.Questions, *q)
				}
			}
		}
	}

	if len(p.Questions) > 0 {
		return p
	}
	return nil
}

func parseDynamicQuestion(m map[string]any) *dto.AIGeneratedQuestion {
	qText := anyToString(m["question_text"], anyToString(m["soal"], anyToString(m["pertanyaan"], anyToString(m["text"], ""))))
	if strings.TrimSpace(qText) == "" {
		return nil
	}

	qTypeStr := strings.ToUpper(strings.TrimSpace(anyToString(m["question_type"], anyToString(m["tipe"], "MULTIPLE_CHOICE"))))
	points := anyToInt(m["points"], anyToInt(m["poin"], anyToInt(m["score"], 10)))
	if points <= 0 {
		points = 10
	}

	q := &dto.AIGeneratedQuestion{
		QuestionText:  qText,
		QuestionType:  domain.QuestionType(qTypeStr),
		Points:        points,
		CodeLanguage:  anyToString(m["code_language"], anyToString(m["language"], "")),
		ImgURL:        anyToString(m["img_url"], ""),
		AudioURL:      anyToString(m["audio_url"], ""),
		VideoURL:      anyToString(m["video_url"], ""),
		AnswerKeyText: anyToString(m["answer_key_text"], anyToString(m["kunci_jawaban"], anyToString(m["explanation"], anyToString(m["pembahasan"], "")))),
	}

	var rawOpts []any
	for _, k := range []string{"options", "opsi", "pilihan", "choices", "answers"} {
		if arr, ok := m[k].([]any); ok && len(arr) > 0 {
			rawOpts = arr
			break
		}
	}

	for _, optItem := range rawOpts {
		switch opt := optItem.(type) {
		case string:
			if strings.TrimSpace(opt) != "" {
				q.Options = append(q.Options, dto.AIGeneratedOption{
					OptionText: strings.TrimSpace(opt),
					IsCorrect:  false,
				})
			}
		case map[string]any:
			optText := anyToString(opt["option_text"], anyToString(opt["text"], anyToString(opt["jawaban"], anyToString(opt["opsi"], ""))))
			isCorrect := anyToBool(opt["is_correct"], anyToBool(opt["benar"], false))
			if strings.TrimSpace(optText) != "" {
				q.Options = append(q.Options, dto.AIGeneratedOption{
					OptionText: optText,
					IsCorrect:  isCorrect,
					ImgURL:     anyToString(opt["img_url"], ""),
					AudioURL:   anyToString(opt["audio_url"], ""),
					VideoURL:   anyToString(opt["video_url"], ""),
				})
			}
		}
	}

	return q
}

func anyToString(val any, fallback string) string {
	if val == nil {
		return fallback
	}
	switch v := val.(type) {
	case string:
		return v
	case fmt.Stringer:
		return v.String()
	default:
		s := fmt.Sprintf("%v", v)
		if s == "" {
			return fallback
		}
		return s
	}
}

func anyToInt(val any, fallback int) int {
	if val == nil {
		return fallback
	}
	switch v := val.(type) {
	case float64:
		return int(v)
	case int:
		return v
	case int64:
		return int(v)
	case string:
		var i int
		if _, err := fmt.Sscanf(v, "%d", &i); err == nil {
			return i
		}
	}
	return fallback
}

func anyToBool(val any, fallback bool) bool {
	if val == nil {
		return fallback
	}
	switch v := val.(type) {
	case bool:
		return v
	case string:
		s := strings.ToLower(strings.TrimSpace(v))
		return s == "true" || s == "1" || s == "yes" || s == "benar"
	case float64:
		return v != 0
	case int:
		return v != 0
	}
	return fallback
}

func extractQuestionsFromRaw(raw string) *dto.AIGenerateFormPreview {
	p := &dto.AIGenerateFormPreview{
		Title: "Asesmen Hasil AI",
	}

	if titleMatch := regexp.MustCompile(`"(?:title|judul)"\s*:\s*"([^"]+)"`).FindStringSubmatch(raw); len(titleMatch) > 1 {
		p.Title = strings.TrimSpace(titleMatch[1])
	}
	if descMatch := regexp.MustCompile(`"(?:description|deskripsi)"\s*:\s*"([^"]+)"`).FindStringSubmatch(raw); len(descMatch) > 1 {
		p.Description = strings.TrimSpace(descMatch[1])
	}

	target := `"question_text"`
	altTarget := `"pertanyaan"`
	idx := 0
	for {
		pos := strings.Index(raw[idx:], target)
		if pos < 0 {
			pos = strings.Index(raw[idx:], altTarget)
			if pos < 0 {
				break
			}
		}
		absPos := idx + pos

		openBrace := strings.LastIndex(raw[:absPos], "{")
		if openBrace >= 0 {
			closeBrace := findMatchingBrace(raw[openBrace:])
			if closeBrace > 0 {
				block := raw[openBrace : openBrace+closeBrace+1]
				sanitizedBlock := infraAI.SanitizeJSON(block)
				var q dto.AIGeneratedQuestion
				if err := json.Unmarshal([]byte(sanitizedBlock), &q); err == nil && strings.TrimSpace(q.QuestionText) != "" {
					p.Questions = append(p.Questions, q)
				} else {
					var qMap map[string]any
					if err := json.Unmarshal([]byte(sanitizedBlock), &qMap); err == nil {
						if dq := parseDynamicQuestion(qMap); dq != nil {
							p.Questions = append(p.Questions, *dq)
						}
					}
				}
				idx = openBrace + closeBrace + 1
				continue
			}
		}
		idx = absPos + len(target)
	}

	if len(p.Questions) > 0 {
		return p
	}
	return nil
}

func findMatchingBrace(s string) int {
	if len(s) == 0 || s[0] != '{' {
		return -1
	}
	depth := 0
	inString := false
	escaped := false

	for i := 0; i < len(s); i++ {
		ch := s[i]
		if escaped {
			escaped = false
			continue
		}
		if ch == '\\' {
			if inString {
				escaped = true
			}
			continue
		}
		if ch == '"' {
			inString = !inString
			continue
		}
		if inString {
			continue
		}
		if ch == '{' {
			depth++
		} else if ch == '}' {
			depth--
			if depth == 0 {
				return i
			}
		}
	}
	return -1
}

func normalizePreview(p *dto.AIGenerateFormPreview, req dto.AIGenerateFormRequest) {
	attachImg, attachAud, attachVid := collectAttachments(req.Attachments)
	for i := range p.Questions {
		q := &p.Questions[i]
		if q.QuestionType == "MATH" || q.QuestionType == "CODE" || !validQuestionType(q.QuestionType) {
			if len(q.Options) > 0 {
				q.QuestionType = domain.TypeMultipleChoice
			} else {
				q.QuestionType = domain.TypeLongText
			}
		}
		if q.Points <= 0 {
			q.Points = 10
		}
		// Distribusikan attachment yang belum tertarget ke soal berurutan.
		if q.ImgURL == "" && len(attachImg) > 0 && i < len(attachImg) {
			q.ImgURL = attachImg[i%len(attachImg)]
		}
		if q.AudioURL == "" && len(attachAud) > 0 && i < len(attachAud) {
			q.AudioURL = attachAud[i%len(attachAud)]
		}
		if q.VideoURL == "" && len(attachVid) > 0 && i < len(attachVid) {
			q.VideoURL = attachVid[i%len(attachVid)]
		}
	}
}

func collectAttachments(list []dto.AIAttachment) (imgs, auds, vids []string) {
	for _, a := range list {
		switch a.MediaType {
		case "IMAGE":
			imgs = append(imgs, a.URL)
		case "AUDIO":
			auds = append(auds, a.URL)
		case "VIDEO":
			vids = append(vids, a.URL)
		}
	}
	return
}

func strPtr(s string) *string {
	if strings.TrimSpace(s) == "" {
		return nil
	}
	return &s
}

// mockPreview agar alur frontend bisa diuji tanpa API key / kuota.
func (s *aiService) mockPreview(req dto.AIGenerateFormRequest) *dto.AIGenerateFormPreview {
	title := "Form Latihan " + defaultStr(req.Topic, defaultStr(req.Subject, "Umum"))
	if strings.TrimSpace(req.RawPrompt) != "" {
		title = "Form dari Instruksi Suara/Teks"
	}
	p := &dto.AIGenerateFormPreview{
		Title: title, Description: "Preview mock (GEMINI_API_KEY belum diisi). Isi API key untuk hasil AI asli.",
		Mock: true,
	}
	addSpec := func(qt domain.QuestionType, n, points, opts int) {
		for i := 0; i < n; i++ {
			q := dto.AIGeneratedQuestion{
				QuestionText:  fmt.Sprintf("Contoh soal %s %d (mock) — %s", qt, i+1, defaultStr(req.Topic, "materi")),
				QuestionType:  qt,
				Points:        points,
			}
			if q.Points <= 0 {
				q.Points = 10
			}
			switch qt {
			case domain.TypeMultipleChoice, domain.TypeDropdown, domain.TypeYesNo, domain.TypeCheckboxes:
				m := opts
				if m <= 0 {
					m = 4
				}
				for o := 0; o < m; o++ {
					q.Options = append(q.Options, dto.AIGeneratedOption{
						OptionText: fmt.Sprintf("Opsi %c", 'A'+o), IsCorrect: o == 0,
					})
				}
			case domain.TypeMatching:
				for o := 0; o < 4; o++ {
					q.Options = append(q.Options, dto.AIGeneratedOption{
						OptionText: fmt.Sprintf("Item %d", o+1),
					})
				}
			default:
				q.AnswerKeyText = "Kunci jawaban contoh (mock)."
			}
			p.Questions = append(p.Questions, q)
		}
	}
	if len(req.Specs) == 0 {
		addSpec(domain.TypeMultipleChoice, 3, 10, 4)
		addSpec(domain.TypeLongText, 2, 20, 0)
	} else {
		for _, sp := range req.Specs {
			addSpec(sp.QuestionType, sp.Count, sp.PointsEach, sp.OptionCount)
		}
	}
	normalizePreview(p, req)
	return p
}

func (s *aiService) mockGrade(req dto.AIGradeEssayRequest) (*dto.AIGradeEssayResponse, error) {
	// Heuristik lokal: kata kunci overlap sebagai proxy kemiripan.
	keyWords := wordSet(req.AnswerKey)
	ansWords := wordSet(req.AnswerText)
	hit := 0
	for w := range ansWords {
		if keyWords[w] {
			hit++
		}
	}
	var sim float64
	if len(keyWords) > 0 {
		sim = float64(hit) / float64(len(keyWords))
		if sim > 1 {
			sim = 1
		}
	}
	score := sim * req.MaxPoints
	return &dto.AIGradeEssayResponse{
		Score: score, MaxPoints: req.MaxPoints, Similarity: sim,
		Feedback: "Penilaian mock (AI nonaktif): skor dari overlap kata kunci. Isi GEMINI_API_KEY untuk penilaian semantik.",
		Mock:     true,
	}, nil
}

func wordSet(s string) map[string]bool {
	out := map[string]bool{}
	for _, w := range strings.Fields(strings.ToLower(s)) {
		w = strings.Trim(w, ".,;:!?\"'()[]{}")
		if len(w) > 2 {
			out[w] = true
		}
	}
	return out
}

func truncateAI(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n]
}
