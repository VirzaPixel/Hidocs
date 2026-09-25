package dto

import (
	"encoding/json"
	"testing"
)

func TestUpdateSettingsPayload(t *testing.T) {
	// Case 1: when token is disabled and exam_token is empty or null, identity_fields_json is present
	jsonStr := `{
		"duration_minutes": 60,
		"auto_active_days": 30,
		"is_active_immediately": false,
		"is_one_time_submission": false,
		"max_attempts": 0,
		"randomize_questions": false,
		"randomize_options": false,
		"start_time": null,
		"end_time": null,
		"theme_color": "#4F46E5",
		"font_family": "Inter",
		"cover_image_url": null,
		"logo_url": null,
		"allow_backtrack": true,
		"show_question_number": true,
		"fullscreen_mode": false,
		"exam_token": null,
		"is_token_protected": false,
		"identity_fields_json": "[{\"id\":\"field_name\"}]"
	}`

	var req UpdateFormSettingsRequest
	if err := json.Unmarshal([]byte(jsonStr), &req); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	t.Logf("Req: %+v", req)
}
