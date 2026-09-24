package service

import (
	"context"
	"encoding/json"
	"fmt"
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
	sb.WriteString("2. Skema JSON:\n")
	sb.WriteString("{\n")
	sb.WriteString("  \"title\": \"Judul Form Yang Menarik & Profesional\",\n")
	sb.WriteString("  \"description\": \"Deskripsi / Petunjuk Pengerjaan Ujian\",\n")
	sb.WriteString("  \"questions\": [\n")
	sb.WriteString("    {\n")
	sb.WriteString("      \"question_text\": \"Teks Soal / Pertanyaan\",\n")
	sb.WriteString("      \"question_type\": \"MULTIPLE_CHOICE|CHECKBOXES|DROPDOWN|YES_NO|SHORT_TEXT|LONG_TEXT|MATCHING|MATH|CODE|RATING\",\n")
	sb.WriteString("      \"points\": 10,\n")
	sb.WriteString("      \"code_language\": \"javascript|python|java|cpp|sql|css|html (wajib jika type=CODE)\",\n")
	sb.WriteString("      \"img_url\": \"...\", \"audio_url\": \"...\", \"video_url\": \"...\",\n")
	sb.WriteString("      \"options\": [\n")
	sb.WriteString("        {\"option_text\": \"Opsi A\", \"is_correct\": true, \"match_key\": \"K1\", \"match_target_text\": \"Target K1\"}\n")
	sb.WriteString("      ],\n")
	sb.WriteString("      \"answer_key_text\": \"Kunci jawaban / pembahasan lengkap\"\n")
	sb.WriteString("    }\n")
	sb.WriteString("  ]\n")
	sb.WriteString("}\n\n")
	sb.WriteString("ATURAN KHUSUS TIPE SOAL & KONTEN:\n")
	sb.WriteString("1. SOAL MATEMATIKA (MATH):\n")
	sb.WriteString("   - Tulis rumus Matematika/Fisika/Kimia menggunakan sintaks LaTeX standar `\\(...\\)` atau `$$...$$` pada `question_text`, `option_text`, maupun `answer_key_text`.\n")
	sb.WriteString("   - Contoh: \"Hitunglah nilai dari \\(f(x) = x^2 + 3x - 5\\) untuk \\(x = 4\\)\".\n")
	sb.WriteString("2. SOAL KODING PROGRAM (CODE):\n")
	sb.WriteString("   - Tulis potongan kode program yang rapi di `question_text` atau `option_text` menggunakan blok kode ```language ... ```.\n")
	sb.WriteString("   - Isi field `code_language` dengan bahasa pemrogramannya (misal: `python`, `javascript`, `cpp`, `sql`).\n")
	sb.WriteString("3. PENGATURAN PILIHAN JAWABAN (OPTIONS):\n")
	sb.WriteString("   - MULTIPLE_CHOICE / DROPDOWN / YES_NO: Wajib ada options, TEPAT 1 opsi `is_correct = true`, sisanya pengecoh (distractor) yang realistis.\n")
	sb.WriteString("   - CHECKBOXES: Wajib ada options, MINIMAL 1 (bisa lebih) `is_correct = true`.\n")
	sb.WriteString("   - MATCHING: Wajib ada options, sertakan `match_key` (misal K1, K2) dan `match_target_text` sebagai pasangan yang tepat.\n")
	sb.WriteString("   - SHORT_TEXT / LONG_TEXT / MATH / CODE: Tanpa `options`, WAJIB isi `answer_key_text` dengan penjelasan & jawaban acuan.\n")
	sb.WriteString("   - RATING: Tanpa options.\n")
	sb.WriteString("4. SKALABILITAS (HINGGA 50 SOAL):\n")
	sb.WriteString("   - Jika diminta hingga 50 soal, buat SELURUH 50 soal secara lancar, konsisten, berurutan dari nomor 1 sampai 50, dan pastikan JSON tidak terpotong di tengah jalan.\n\n")

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
	preview, err := parsePreview(infraAI.HealJSON(raw))
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
		dq := domain.Question{
			ID: qID, FormID: form.ID, QuestionText: q.QuestionText,
			QuestionType: q.QuestionType, CodeLanguage: q.CodeLanguage,
			ImgURL: q.ImgURL, AudioURL: strPtr(q.AudioURL), VideoURL: strPtr(q.VideoURL),
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
	if !s.gemini.IsEnabled() {
		return nil, fmt.Errorf("GEMINI_API_KEY belum diisi — grading tidak tersedia")
	}
	prompt := fmt.Sprintf(`Kamu adalah penilai essay yang adil. Nilai jawaban murid terhadap kunci jawaban secara semantik (makna sama dengan susunan kata berbeda tetap dinilai tinggi).
Kunci jawaban: %s
Jawaban murid: %s
Rubrik (opsional): %s
Skor maksimum: %.2f
Keluarkan HANYA JSON: {"score": <0..maks>, "similarity": <0..1>, "feedback": "<1-2 kalimat bahasa Indonesia>"}.
Aturan: semakin dekat makna dengan kunci, semakin mendekati skor penuh. Jawaban kosong => score 0.`,
		req.AnswerKey, req.AnswerText, req.Rubric, req.MaxPoints)
	raw, err := s.gemini.GenerateJSON(ctx, prompt)
	if err != nil {
		return nil, err
	}
	var parsed struct {
		Score      float64 `json:"score"`
		Similarity float64 `json:"similarity"`
		Feedback   string  `json:"feedback"`
	}
	if err := json.Unmarshal([]byte(infraAI.HealJSON(raw)), &parsed); err != nil {
		// Fallback to mock evaluation instead of erroring
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
		if req.AnswerKeys != nil {
			key = req.AnswerKeys[ans.QuestionID]
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
				AnswerKey: key, MaxPoints: max,
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
	var p dto.AIGenerateFormPreview
	if err := json.Unmarshal([]byte(raw), &p); err != nil {
		return nil, err
	}
	if strings.TrimSpace(p.Title) == "" {
		p.Title = "Form Buatan AI"
	}
	return &p, nil
}

func normalizePreview(p *dto.AIGenerateFormPreview, req dto.AIGenerateFormRequest) {
	attachImg, attachAud, attachVid := collectAttachments(req.Attachments)
	for i := range p.Questions {
		q := &p.Questions[i]
		if !validQuestionType(q.QuestionType) {
			q.QuestionType = domain.TypeMultipleChoice
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
