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

	"google.golang.org/genai"
)

func base64Encode(data []byte) string { return base64.StdEncoding.EncodeToString(data) }

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
		httpClient: &http.Client{Timeout: 90 * time.Second},
		enabled:    strings.TrimSpace(apiKey) != "",
	}
}

func (c *GeminiClient) IsEnabled() bool { return c.enabled }

func (c *GeminiClient) GenerateText(ctx context.Context, prompt string) (string, error) {
	return c.generateWithSDK(ctx, prompt, 0.7)
}

func (c *GeminiClient) GenerateJSON(ctx context.Context, prompt string) (string, error) {
	return c.generateWithSDK(ctx, prompt, 0.2)
}

func (c *GeminiClient) TranscribeAudio(ctx context.Context, audio []byte, mimeType string) (string, error) {
	if !c.enabled {
		return "", fmt.Errorf("gemini api key not configured")
	}
	if mimeType == "" {
		mimeType = "audio/webm"
	}
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  c.apiKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		return "", err
	}
	audioPrompt := "Transkripsikan audio berikut ke teks Bahasa Indonesia. Hanya keluarkan transkripsi."
	cached := &genai.Content{Parts: []*genai.Part{{Text: audioPrompt}, {InlineData: &genai.Blob{Data: audio, MIMEType: mimeType}}}}
	result, err := client.Models.GenerateContent(ctx, c.model, []*genai.Content{cached}, &genai.GenerateContentConfig{Temperature: genai.Ptr(float32(0.1))})
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(result.Text()), nil
}

func (c *GeminiClient) generateWithSDK(ctx context.Context, prompt string, temperature float64) (string, error) {
	if !c.enabled {
		return "", fmt.Errorf("gemini api key not configured")
	}
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  c.apiKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		return "", err
	}
	temp := float32(temperature)
	cfg := genai.GenerateContentConfig{Temperature: &temp}
	if temperature <= 0.3 {
		cfg.ResponseMIMEType = "application/json"
	}
	result, err := client.Models.GenerateContent(ctx, c.model, genai.Text(prompt), &cfg)
	if err != nil {
		return c.generateHTTP(ctx, prompt, temperature)
	}
	return strings.TrimSpace(result.Text()), nil
}

func (c *GeminiClient) generateHTTP(ctx context.Context, prompt string, temperature float64) (string, error) {
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", c.model, c.apiKey)
	genConfig := map[string]any{"temperature": temperature, "maxOutputTokens": 8192}
	if temperature <= 0.3 {
		genConfig["responseMimeType"] = "application/json"
	}
	body, _ := json.Marshal(map[string]any{
		"contents":         []map[string]any{{"parts": []map[string]string{{"text": prompt}}}},
		"generationConfig": genConfig,
	})
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("gemini %s http %d: %s", c.model, resp.StatusCode, truncate(string(data), 500))
	}
	var parsed struct {
		Candidates []struct {
			Content struct {
				Parts []struct{ Text string `json:"text"` } `json:"parts"`
			} `json:"content"`
		} `json:"candidates"`
	}
	if err := json.Unmarshal(data, &parsed); err != nil {
		return "", err
	}
	if len(parsed.Candidates) == 0 || len(parsed.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("gemini %s empty response", c.model)
	}
	var sb strings.Builder
	for _, p := range parsed.Candidates[0].Content.Parts {
		sb.WriteString(p.Text)
	}
	return strings.TrimSpace(sb.String()), nil
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n]
}

func ExtractJSON(s string) string {
	t := strings.TrimSpace(s)
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

func HealJSON(s string) string {
	cleaned := strings.TrimSpace(ExtractJSON(s))
	if cleaned == "" {
		return "{}"
	}
	var js any
	if json.Unmarshal([]byte(cleaned), &js) == nil {
		return cleaned
	}
	healed := tryCloseJSON(cleaned)
	if json.Unmarshal([]byte(healed), &js) == nil {
		return healed
	}
	return "{}"
}

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
	result := s
	if inString {
		result += `"`
	}
	for i := len(stack) - 1; i >= 0; i-- {
		if stack[i] == '{' {
			result += "}"
		} else {
			result += "]"
		}
	}
	return result
}
