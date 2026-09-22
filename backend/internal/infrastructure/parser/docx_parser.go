package parser

import (
	"archive/zip"
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"backend/internal/domain"
	"github.com/google/uuid"
)

type ExtractedForm struct {
	Title       string
	Description string
	Questions   []domain.Question
}

type DocxParser struct{}

func NewDocxParser() *DocxParser {
	return &DocxParser{}
}

// XML structures for word/_rels/document.xml.rels
type relationshipsXML struct {
	XMLName       xml.Name          `xml:"Relationships"`
	Relationships []relationshipXML `xml:"Relationship"`
}

type relationshipXML struct {
	ID     string `xml:"Id,attr"`
	Type   string `xml:"Type,attr"`
	Target string `xml:"Target,attr"`
}

// XML structures for word/document.xml parsing
type documentXML struct {
	XMLName xml.Name `xml:"document"`
	Body    bodyXML  `xml:"body"`
}

type bodyXML struct {
	Paragraphs []paragraphXML `xml:"p"`
}

type paragraphXML struct {
	InnerXML string `xml:",innerxml"`
}

type parsedParagraph struct {
	Text     string
	ImageURL string
}

// FIX: baru — ExtractRawText mengekstrak teks polos dari .docx (dipakai untuk
// fitur "lampirkan materi PDF/Word ke AI"), TANPA mencoba mem-parsing jadi
// struktur soal (beda dari ParseDocx di atas). Memakai ulang logic parsing
// word/document.xml yang sama supaya konsisten.
func (p *DocxParser) ExtractRawText(fileBytes []byte) (string, error) {
	reader, err := zip.NewReader(bytes.NewReader(fileBytes), int64(len(fileBytes)))
	if err != nil {
		return "", fmt.Errorf("failed to open docx as zip archive: %w", err)
	}

	var documentFile *zip.File
	for _, f := range reader.File {
		cleanName := strings.TrimPrefix(f.Name, "/")
		if cleanName == "word/document.xml" {
			documentFile = f
			break
		}
	}
	if documentFile == nil {
		return "", fmt.Errorf("invalid docx file: missing word/document.xml")
	}

	rc, err := documentFile.Open()
	if err != nil {
		return "", fmt.Errorf("failed to open document.xml: %w", err)
	}
	defer rc.Close()

	xmlData, err := io.ReadAll(rc)
	if err != nil {
		return "", fmt.Errorf("failed to read document.xml: %w", err)
	}

	var doc documentXML
	if err := xml.Unmarshal(xmlData, &doc); err != nil {
		return "", fmt.Errorf("failed to parse document.xml: %w", err)
	}

	textTagRegex := regexp.MustCompile(`(?s)<(?:[a-zA-Z0-9_-]+:)?t(?:\s+[^>]*)?>([^<]*)</(?:[a-zA-Z0-9_-]+:)?t>`)

	var lines []string
	for _, para := range doc.Body.Paragraphs {
		var textBuilder strings.Builder
		for _, tm := range textTagRegex.FindAllStringSubmatch(para.InnerXML, -1) {
			if len(tm) > 1 {
				textBuilder.WriteString(tm[1])
			}
		}
		line := strings.TrimSpace(textBuilder.String())
		if line != "" {
			lines = append(lines, line)
		}
	}

	return strings.Join(lines, "\n"), nil
}

func (p *DocxParser) ParseDocx(fileBytes []byte, formID uuid.UUID) (*ExtractedForm, error) {
	reader, err := zip.NewReader(bytes.NewReader(fileBytes), int64(len(fileBytes)))
	if err != nil {
		return nil, fmt.Errorf("failed to open docx as zip archive: %w", err)
	}

	// 1. Parse Relationships (word/_rels/document.xml.rels)
	relMap := make(map[string]string)
	for _, f := range reader.File {
		cleanName := strings.TrimPrefix(f.Name, "/")
		if cleanName == "word/_rels/document.xml.rels" {
			rc, err := f.Open()
			if err == nil {
				data, _ := io.ReadAll(rc)
				rc.Close()
				var rels relationshipsXML
				if xml.Unmarshal(data, &rels) == nil {
					for _, r := range rels.Relationships {
						relMap[r.ID] = r.Target
					}
				}
			}
			break
		}
	}

	// Map to access zip files quickly
	zipFileMap := make(map[string]*zip.File)
	for _, f := range reader.File {
		cleanName := strings.TrimPrefix(f.Name, "/")
		zipFileMap[f.Name] = f
		zipFileMap[cleanName] = f
	}

	// Helper to extract image by relationship ID or target
	embedRegex := regexp.MustCompile(`(?i)(?:r:embed|r:id|embed|id|src)="([^"]+)"`)
	imageExts := map[string]bool{
		".png": true, ".jpg": true, ".jpeg": true, ".gif": true,
		".webp": true, ".bmp": true, ".svg": true, ".emf": true, ".wmf": true,
	}

	extractImageFromXML := func(rawXML string) string {
		matches := embedRegex.FindAllStringSubmatch(rawXML, -1)
		for _, m := range matches {
			if len(m) < 2 {
				continue
			}
			relID := m[1]
			targetPath, exists := relMap[relID]
			if !exists {
				// Maybe relID is direct path
				targetPath = relID
			}

			ext := strings.ToLower(filepath.Ext(targetPath))
			if !imageExts[ext] {
				continue
			}

			// Normalize target path
			fullPath := targetPath
			if !strings.HasPrefix(fullPath, "word/") {
				fullPath = "word/" + strings.TrimPrefix(targetPath, "/")
			}

			zf, found := zipFileMap[fullPath]
			if !found {
				// Try without word/
				zf, found = zipFileMap[strings.TrimPrefix(fullPath, "word/")]
			}
			if !found {
				continue
			}

			imgRc, err := zf.Open()
			if err != nil {
				continue
			}

			imgBytes, err := io.ReadAll(imgRc)
			imgRc.Close()
			if err != nil || len(imgBytes) == 0 {
				continue
			}

			// Save image to ./uploads/questions/
			uploadDir := "./uploads/questions"
			_ = os.MkdirAll(uploadDir, 0755)

			if ext == "" {
				ext = ".png"
			}
			fileName := fmt.Sprintf("%s%s", uuid.New().String(), ext)
			destPath := filepath.Join(uploadDir, fileName)

			if err := os.WriteFile(destPath, imgBytes, 0644); err != nil {
				continue
			}

			return fmt.Sprintf("/uploads/questions/%s", fileName)
		}
		return ""
	}

	// 2. Parse word/document.xml
	var documentFile *zip.File
	for _, f := range reader.File {
		cleanName := strings.TrimPrefix(f.Name, "/")
		if cleanName == "word/document.xml" {
			documentFile = f
			break
		}
	}

	if documentFile == nil {
		return nil, fmt.Errorf("invalid docx file: missing word/document.xml")
	}

	rc, err := documentFile.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open document.xml: %w", err)
	}
	defer rc.Close()

	xmlData, err := io.ReadAll(rc)
	if err != nil {
		return nil, fmt.Errorf("failed to read document.xml: %w", err)
	}

	var doc documentXML
	if err := xml.Unmarshal(xmlData, &doc); err != nil {
		return nil, fmt.Errorf("failed to parse document.xml: %w", err)
	}

	textTagRegex := regexp.MustCompile(`(?s)<(?:[a-zA-Z0-9_-]+:)?t(?:\s+[^>]*)?>([^<]*)</(?:[a-zA-Z0-9_-]+:)?t>`)

	var paragraphs []parsedParagraph
	for _, p := range doc.Body.Paragraphs {
		var textBuilder strings.Builder
		textMatches := textTagRegex.FindAllStringSubmatch(p.InnerXML, -1)
		for _, tm := range textMatches {
			if len(tm) > 1 {
				textBuilder.WriteString(tm[1])
			}
		}

		line := strings.TrimSpace(textBuilder.String())
		imgURL := extractImageFromXML(p.InnerXML)

		if line != "" || imgURL != "" {
			paragraphs = append(paragraphs, parsedParagraph{
				Text:     line,
				ImageURL: imgURL,
			})
		}
	}

	return parseParagraphsToForm(paragraphs, formID)
}

func parseLinesToForm(lines []string, formID uuid.UUID) (*ExtractedForm, error) {
	var paragraphs []parsedParagraph
	for _, l := range lines {
		paragraphs = append(paragraphs, parsedParagraph{Text: l})
	}
	return parseParagraphsToForm(paragraphs, formID)
}

func parseParagraphsToForm(paragraphs []parsedParagraph, formID uuid.UUID) (*ExtractedForm, error) {
	extracted := &ExtractedForm{
		Title:       "Dokumen Soal Import Docx",
		Description: "Form ujian diimport secara otomatis dari dokumen Word",
		Questions:   []domain.Question{},
	}

	if len(paragraphs) == 0 {
		return extracted, nil
	}

	qNumRegex := regexp.MustCompile(`(?i)^(?:(?:Soal|Question|Q)\s*#?\s*\d+[\.\):]?|\d+[\.\)]|\(\d+\)|\[\d+\])\s*(.*)`)
	optionRegex := regexp.MustCompile(`(?i)^(\*?\s*)(?:[\(\[]?([A-Ea-e])[\.\)\]]|\b([A-Ea-e])[\.\)])(?:\s*(.*))`)
	answerKeyRegex := regexp.MustCompile(`(?i)^(?:Kunci\s*Jawaban|Kunci|Jawaban|Answer|Key)\s*[:=]?\s*[\(\[]?([A-Ea-e])[\.\)\]]?`)
	separatorRegex := regexp.MustCompile(`^[\_\-\*\=\#\s]{3,}$`)

	startIndex := 0

	// Check if document starts directly with a question
	firstIsQuestion := qNumRegex.MatchString(paragraphs[0].Text) || optionRegex.MatchString(paragraphs[0].Text)

	if !firstIsQuestion {
		extracted.Title = paragraphs[0].Text
		startIndex = 1
		if len(paragraphs) > 1 && !qNumRegex.MatchString(paragraphs[1].Text) && !optionRegex.MatchString(paragraphs[1].Text) {
			extracted.Description = paragraphs[1].Text
			startIndex = 2
		}
	}

	var currentQuestion *domain.Question
	var currentOptions []domain.QuestionOption
	var pendingCorrectLetter string
	var pendingImage string
	orderIdx := 1

	for i := startIndex; i < len(paragraphs); i++ {
		para := paragraphs[i]
		line := strings.TrimSpace(para.Text)

		// Skip separator / divider lines
		if separatorRegex.MatchString(line) {
			continue
		}

		// 1. Check if it's a question number line
		if match := qNumRegex.FindStringSubmatch(line); len(match) > 0 {
			if currentQuestion != nil {
				currentQuestion.Options = currentOptions
				extracted.Questions = append(extracted.Questions, *currentQuestion)
			}

			qText := strings.TrimSpace(match[1])
			qID := uuid.New()
			currentQuestion = &domain.Question{
				ID:           qID,
				FormID:       formID,
				QuestionText: qText,
				QuestionType: domain.TypeMultipleChoice,
				ImgURL:       para.ImageURL,
				IsAutoScored: true,
				Points:       10,
				OrderIndex:   orderIdx,
				IsRequired:   true,
			}
			orderIdx++
			currentOptions = []domain.QuestionOption{}
			pendingCorrectLetter = ""
			pendingImage = ""
			continue
		}

		// 2. Check if it's an Answer Key line (e.g. Kunci Jawaban: B)
		if match := answerKeyRegex.FindStringSubmatch(line); len(match) > 1 && currentQuestion != nil {
			correctLetter := strings.ToUpper(strings.TrimSpace(match[1]))
			pendingCorrectLetter = correctLetter

			// Apply correct status to already parsed option if available
			letterIdx := int(correctLetter[0] - 'A')
			if letterIdx >= 0 && letterIdx < len(currentOptions) {
				currentOptions[letterIdx].IsCorrect = true
			} else {
				for idx := range currentOptions {
					optL := strings.TrimPrefix(currentOptions[idx].OptionText, "(")
					if strings.HasPrefix(strings.ToUpper(optL), correctLetter) {
						currentOptions[idx].IsCorrect = true
					}
				}
			}
			continue
		}

		// 3. Check if it's an Option line (e.g. (a) text, A. text, *A. text, or standalone A.)
		if match := optionRegex.FindStringSubmatch(line); len(match) > 0 && currentQuestion != nil {
			prefixAsterisk := match[1]
			optLetter := match[2]
			if optLetter == "" {
				optLetter = match[3]
			}
			optText := strings.TrimSpace(match[4])
			if optText == "" {
				optText = fmt.Sprintf("Opsi %s", strings.ToUpper(optLetter))
			}

			lowerLine := strings.ToLower(line)
			isCorrect := strings.Contains(prefixAsterisk, "*") ||
				strings.Contains(lowerLine, "[correct]") ||
				strings.Contains(lowerLine, "(correct)") ||
				strings.Contains(lowerLine, "(v)") ||
				strings.Contains(lowerLine, "(benar)") ||
				strings.Contains(lowerLine, "[benar]")

			if pendingCorrectLetter != "" && strings.ToUpper(optLetter) == pendingCorrectLetter {
				isCorrect = true
			}

			// Clean option text from markers
			optText = strings.ReplaceAll(optText, "[correct]", "")
			optText = strings.ReplaceAll(optText, "(correct)", "")
			optText = strings.ReplaceAll(optText, "(v)", "")
			optText = strings.ReplaceAll(optText, "(benar)", "")
			optText = strings.ReplaceAll(optText, "[benar]", "")
			optText = strings.TrimSpace(optText)

			var optImg *string
			if para.ImageURL != "" {
				optImg = &para.ImageURL
			} else if pendingImage != "" {
				// Image was placed immediately above this option label
				optImg = &pendingImage
				if currentQuestion.ImgURL == pendingImage {
					currentQuestion.ImgURL = ""
				}
				pendingImage = ""
			}

			currentOptions = append(currentOptions, domain.QuestionOption{
				ID:         uuid.New(),
				QuestionID: currentQuestion.ID,
				OptionText: optText,
				ImgURL:     optImg,
				IsCorrect:  isCorrect,
				OrderIndex: len(currentOptions) + 1,
			})
			continue
		}

		// 4. Multi-line body text / standalone image for question or option
		if currentQuestion != nil {
			if para.ImageURL != "" {
				if len(currentOptions) == 0 {
					// Image below question before any options
					if currentQuestion.ImgURL == "" {
						currentQuestion.ImgURL = para.ImageURL
					}
					pendingImage = para.ImageURL
				} else {
					// Image below the last option
					lastIdx := len(currentOptions) - 1
					if currentOptions[lastIdx].ImgURL == nil {
						currentOptions[lastIdx].ImgURL = &para.ImageURL
					}
					pendingImage = para.ImageURL
				}
			}

			if line != "" {
				if len(currentOptions) == 0 {
					if currentQuestion.QuestionText != "" {
						currentQuestion.QuestionText += "\n" + line
					} else {
						currentQuestion.QuestionText = line
					}
				} else {
					lastIdx := len(currentOptions) - 1
					currentOptions[lastIdx].OptionText += " " + line
				}
			}
		}
	}

	if currentQuestion != nil {
		currentQuestion.Options = currentOptions
		extracted.Questions = append(extracted.Questions, *currentQuestion)
	}

	return extracted, nil
}
