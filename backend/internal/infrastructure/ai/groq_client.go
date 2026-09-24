package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

type GroqClient struct {
	apiKey     string
	model      string
	httpClient *http.Client
	enabled    bool
}

func NewGroqClient(apiKey, model string) *GroqClient {
	if model == "" {
		model = "llama-3.1-8b-instant"
	}
	return &GroqClient{
		apiKey:     strings.TrimSpace(apiKey),
		model:      model,
		httpClient: &http.Client{Timeout: 300 * time.Second},
		enabled:    strings.TrimSpace(apiKey) != "",
	}
}

func (c *GroqClient) IsEnabled() bool { return c.enabled }

func (c *GroqClient) GenerateJSON(ctx context.Context, prompt string) (string, error) {
	return c.generate(ctx, prompt, 0.2)
}

func (c *GroqClient) GenerateText(ctx context.Context, prompt string) (string, error) {
	return c.generate(ctx, prompt, 0.7)
}

func (c *GroqClient) generate(ctx context.Context, prompt string, temperature float64) (string, error) {
	if !c.enabled {
		return "", fmt.Errorf("groq api key not configured")
	}
	body := map[string]any{
		"model": c.model,
		"messages": []map[string]string{
			{"role": "system", "content": "Kamu adalah generator soal ujian. Keluarankan HANYA JSON valid sesuai instruksi, tanpa markdown fence."},
			{"role": "user", "content": prompt},
		},
		"temperature":     temperature,
		"max_tokens":      8192,
		"response_format": map[string]string{"type": "json_object"},
	}
	rawBody, _ := json.Marshal(body)
	req, _ := http.NewRequestWithContext(ctx, "POST", "https://api.groq.com/openai/v1/chat/completions", bytes.NewReader(rawBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("groq %s error %d: %s", c.model, resp.StatusCode, truncate(string(data), 500))
	}
	var parsed struct {
		Choices []struct {
			Message struct{ Content string `json:"content"`} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(data, &parsed); err != nil {
		return "", err
	}
	if len(parsed.Choices) == 0 {
		return "", fmt.Errorf("groq returned empty choices")
	}
	return strings.TrimSpace(parsed.Choices[0].Message.Content), nil
}
