package ai

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// GeminiClient memanggil Google Generative Language API tanpa dependensi tambahan.
type GeminiClient struct {
	apiKey     string
	model      string
	httpClient *http.Client
	enabled    bool
}

func NewGeminiClient(apiKey, model string) *GeminiClient {
	if model == "" {
		model = "gemini-2.5-flash"
	}
	return &GeminiClient{
		apiKey:     strings.TrimSpace(apiKey),
		model:      model,
		httpClient: &http.Client{Timeout: 60 * time.Second},
		enabled:    strings.TrimSpace(apiKey) != "",
	}
}

func (c *GeminiClient) IsEnabled() bool { return c.enabled }

type geminiPart struct {
	Text       string            `json:"text,omitempty"`
	InlineData *geminiInlineData `json:"inlineData,omitempty"`
}

type geminiInlineData struct {
	MimeType string `json:"mimeType"`
	Data     string `json:"data"`
}

type geminiContent struct {
	Parts []geminiPart `json:"parts"`
}

type geminiRequest struct {
	Contents         []geminiContent `json:"contents"`
	GenerationConfig map[string]any  `json:"generationConfig,omitempty"`
}

type geminiResponse struct {
	Candidates []struct {
		Content struct {
			Parts []struct {
				Text string `json:"text"`
			} `json:"parts"`
		} `json:"content"`
	} `json:"candidates"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

// GenerateText mengirim prompt teks dan mengembalikan gabungan teks kandidat pertama.
func (c *GeminiClient) GenerateText(ctx context.Context, prompt string) (string, error) {
	return c.generate(ctx, []geminiPart{{Text: prompt}}, 0.7)
}

// GenerateJSON sama seperti GenerateText tapi dengan temperature rendah agar output deterministik.
func (c *GeminiClient) GenerateJSON(ctx context.Context, prompt string) (string, error) {
	return c.generate(ctx, []geminiPart{{Text: prompt}}, 0.2)
}

// TranscribeAudio mengirim audio base64 ke model multimodal dan meminta transkripsi Bahasa Indonesia.
func (c *GeminiClient) TranscribeAudio(ctx context.Context, audio []byte, mimeType string) (string, error) {
	if !c.enabled {
		return "", fmt.Errorf("gemini api key not configured")
	}
	if mimeType == "" {
		mimeType = "audio/webm"
	}
	prompt := "Transkripsikan audio berikut ke teks Bahasa Indonesia secara akurat. " +
		"Jika ada beberapa bahasa, utamakan Bahasa Indonesia. " +
		"Hanya keluarkan hasil transkripsi tanpa komentar tambahan."
	parts := []geminiPart{
		{Text: prompt},
		{InlineData: &geminiInlineData{MimeType: mimeType, Data: base64.StdEncoding.EncodeToString(audio)}},
	}
	return c.generate(ctx, parts, 0.1)
}

func (c *GeminiClient) generate(ctx context.Context, parts []geminiPart, temperature float64) (string, error) {
	if !c.enabled {
		return "", fmt.Errorf("gemini api key not configured")
	}
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", c.model, c.apiKey)
	genConfig := map[string]any{
		"temperature":     temperature,
		"maxOutputTokens": 8192,
	}
	// Jika temperature rendah (GenerateJSON), minta format JSON langsung
	if temperature <= 0.3 {
		genConfig["responseMimeType"] = "application/json"
	}
	reqBody := geminiRequest{
		Contents:         []geminiContent{{Parts: parts}},
		GenerationConfig: genConfig,
	}
	raw, err := json.Marshal(reqBody)
	if err != nil {
		return "", err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(raw))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return "", err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("gemini api error %d: %s", resp.StatusCode, truncate(string(data), 500))
	}
	var parsed geminiResponse
	if err := json.Unmarshal(data, &parsed); err != nil {
		return "", err
	}
	if parsed.Error != nil {
		return "", fmt.Errorf("gemini api error: %s", parsed.Error.Message)
	}
	if len(parsed.Candidates) == 0 || len(parsed.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("gemini returned empty response")
	}
	var sb strings.Builder
	for _, p := range parsed.Candidates[0].Content.Parts {
		sb.WriteString(p.Text)
	}
	return strings.TrimSpace(sb.String()), nil
}

// ExtractJSON memotong markdown fence ```json ... ``` jika ada dan mengekstrak objek JSON.
func ExtractJSON(s string) string {
	t := strings.TrimSpace(s)
	// Hapus backticks jika ada di mana saja
	if strings.Contains(t, "```") {
		firstBacktick := strings.Index(t, "```")
		lastBacktick := strings.LastIndex(t, "```")
		if firstBacktick >= 0 && lastBacktick > firstBacktick {
			inner := t[firstBacktick:lastBacktick]
			inner = strings.TrimPrefix(inner, "```json")
			inner = strings.TrimPrefix(inner, "```JSON")
			inner = strings.TrimPrefix(inner, "```")
			t = strings.TrimSpace(inner)
		}
	}
	// Cari blok JSON pertama {...} atau [...]
	startObj, startArr := strings.Index(t, "{"), strings.Index(t, "[")
	start := -1
	if startObj >= 0 && (startArr < 0 || startObj < startArr) {
		start = startObj
	} else if startArr >= 0 {
		start = startArr
	}
	if start >= 0 {
		t = t[start:]
	}
	endObj, endArr := strings.LastIndex(t, "}"), strings.LastIndex(t, "]")
	end := endObj
	if endArr > end {
		end = endArr
	}
	if start >= 0 && end >= 0 && end < len(t) {
		return strings.TrimSpace(t[:end+1])
	}
	return strings.TrimSpace(t)
}

// HealJSON tries to repair a truncated or malformed JSON string.
func HealJSON(s string) string {
	cleaned := strings.TrimSpace(ExtractJSON(s))
	if cleaned == "" {
		return "{}"
	}

	// If already valid, return as-is
	var js any
	if json.Unmarshal([]byte(cleaned), &js) == nil {
		return cleaned
	}

	// Try to close open brackets/braces
	healed := tryCloseJSON(cleaned)
	if json.Unmarshal([]byte(healed), &js) == nil {
		return healed
	}

	// Return empty object as last resort
	return "{}"
}

// tryCloseJSON attempts to close any open JSON structures.
func tryCloseJSON(s string) string {
	var stack []rune
	inString := false
	escaped := false

	for _, ch := range s {
		if escaped {
			escaped = false
			continue
		}
		if ch == '\\' && inString {
			escaped = true
			continue
		}
		if ch == '"' {
			inString = !inString
			continue
		}
		if inString {
			continue
		}
		switch ch {
		case '{', '[':
			stack = append(stack, ch)
		case '}':
			if len(stack) > 0 && stack[len(stack)-1] == '{' {
				stack = stack[:len(stack)-1]
			}
		case ']':
			if len(stack) > 0 && stack[len(stack)-1] == '[' {
				stack = stack[:len(stack)-1]
			}
		}
	}

	// Close any unclosed string
	result := s
	if inString {
		result += `"`
	}

	// Close unclosed structures in reverse order
	for i := len(stack) - 1; i >= 0; i-- {
		if stack[i] == '{' {
			result += "}"
		} else {
			result += "]"
		}
	}

	return result
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n]
}
