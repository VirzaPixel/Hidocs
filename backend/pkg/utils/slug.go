package utils

import (
	"regexp"
	"strings"
)

func GenerateSlug(title string) string {
	slug := strings.ToLower(title)
	re := regexp.MustCompile(`[^a-z0-9\s-]`)
	slug = re.ReplaceAllString(slug, "")
	reSpace := regexp.MustCompile(`[\s-]+`)
	slug = reSpace.ReplaceAllString(slug, "-")
	slug = strings.Trim(slug, "-")

	if slug == "" {
		return "form-" + RandomString(6)
	}
	const maxBaseLength = 90
	if len(slug) > maxBaseLength {
		slug = strings.Trim(slug[:maxBaseLength], "-")
	}
	return slug + "-" + RandomString(6)
}
