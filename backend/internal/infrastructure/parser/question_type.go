package parser

import (
	"regexp"
	"strings"

	"backend/internal/domain"
)

func normalizeQuestionType(raw string) (domain.QuestionType, bool) {
	value := strings.ToUpper(strings.TrimSpace(raw))
	value = strings.NewReplacer("-", "_", " ", "_", "/", "_").Replace(value)

	if strings.Contains(value, "ESAI") || strings.Contains(value, "ESSAI") || strings.Contains(value, "ESSAY") || strings.Contains(value, "LONG_TEXT") || strings.Contains(value, "PARAGRAF") {
		return domain.TypeLongText, false
	}
	if strings.Contains(value, "MATCH") || strings.Contains(value, "MENJODOHKAN") {
		return domain.TypeMatching, true
	}
	if strings.Contains(value, "GAMBAR") || strings.Contains(value, "IMAGE") {
		return domain.TypeImage, false
	}
	if strings.Contains(value, "CHECKBOX") || strings.Contains(value, "KOTAK_CENTANG") {
		return domain.TypeCheckboxes, true
	}
	if strings.Contains(value, "DROPDOWN") {
		return domain.TypeDropdown, true
	}
	if strings.Contains(value, "YA_TIDAK") || strings.Contains(value, "YES_NO") || strings.Contains(value, "TRUE_FALSE") || strings.Contains(value, "BOOLEAN") {
		return domain.TypeYesNo, true
	}
	if strings.Contains(value, "RATING") || strings.Contains(value, "STAR") {
		return domain.TypeRating, false
	}
	if strings.Contains(value, "MATH") || strings.Contains(value, "MATEMATIKA") {
		return domain.TypeMath, true
	}
	if strings.Contains(value, "CODE") || strings.Contains(value, "KODE") {
		return domain.TypeCode, false
	}
	if strings.Contains(value, "SHORT_TEXT") || strings.Contains(value, "JAWABAN_SINGKAT") {
		return domain.TypeShortText, true
	}
	return domain.TypeMultipleChoice, true
}

var questionMarkerPattern = regexp.MustCompile(`(?i)\[(esai|essay|long_text|matching|menjodohkan|gambar|image|checkboxes|dropdown|ya_tidak|rating|math|code|short_text)\]`)

func stripQuestionMarkers(text string) string {
	return strings.TrimSpace(questionMarkerPattern.ReplaceAllString(text, ""))
}