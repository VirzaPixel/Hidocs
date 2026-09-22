package parser

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"strconv"
	"strings"

	"backend/internal/domain"
	"github.com/google/uuid"
	"github.com/xuri/excelize/v2"
)

type ExcelParser struct{}

func NewExcelParser() *ExcelParser {
	return &ExcelParser{}
}

func (p *ExcelParser) ParseExcel(fileBytes []byte, formID uuid.UUID) (*ExtractedForm, error) {
	// Try reading as XLSX first
	xlFile, err := excelize.OpenReader(bytes.NewReader(fileBytes))
	if err == nil {
		defer xlFile.Close()
		sheets := xlFile.GetSheetList()
		if len(sheets) == 0 {
			return nil, fmt.Errorf("file excel tidak memiliki sheet")
		}
		rows, err := xlFile.GetRows(sheets[0])
		if err != nil {
			return nil, fmt.Errorf("gagal membaca sheet excel: %w", err)
		}
		return parseMatrixToForm(rows, formID)
	}

	// Fallback to CSV format
	csvReader := csv.NewReader(bytes.NewReader(fileBytes))
	csvReader.LazyQuotes = true
	csvReader.FieldsPerRecord = -1
	rows, err := csvReader.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("gagal membaca file spreadsheet (.xlsx / .csv): %w", err)
	}

	return parseMatrixToForm(rows, formID)
}

func parseMatrixToForm(matrix [][]string, formID uuid.UUID) (*ExtractedForm, error) {
	extracted := &ExtractedForm{
		Title:       "Dokumen Soal Import Excel",
		Description: "Form ujian diimport secara otomatis dari spreadsheet Excel",
		Questions:   []domain.Question{},
	}

	if len(matrix) == 0 {
		return extracted, nil
	}

	// Determine header row index
	headerIdx := -1
	for idx, row := range matrix {
		for _, cell := range row {
			lower := strings.ToLower(strings.TrimSpace(cell))
			if lower == "soal" || lower == "pertanyaan" || lower == "question" {
				headerIdx = idx
				break
			}
		}
		if headerIdx != -1 {
			break
		}
	}

	// If no header found, assume row 0 is header if len > 1, else process row 0
	startRow := 0
	if headerIdx != -1 {
		startRow = headerIdx + 1
	} else if len(matrix) > 1 {
		startRow = 1
	}

	// Map column names if header found
	colMap := map[string]int{
		"no":       0,
		"soal":     1,
		"tipe":     2,
		"opsi a":   3,
		"opsi b":   4,
		"opsi c":   5,
		"opsi d":   6,
		"kunci":    7,
		"poin":     8,
	}

	if headerIdx != -1 {
		for colIdx, cell := range matrix[headerIdx] {
			cleanCell := strings.ToLower(strings.TrimSpace(cell))
			if strings.Contains(cleanCell, "soal") || strings.Contains(cleanCell, "question") {
				colMap["soal"] = colIdx
			} else if strings.Contains(cleanCell, "tipe") || strings.Contains(cleanCell, "type") {
				colMap["tipe"] = colIdx
			} else if strings.Contains(cleanCell, "opsi a") || cleanCell == "a" {
				colMap["opsi a"] = colIdx
			} else if strings.Contains(cleanCell, "opsi b") || cleanCell == "b" {
				colMap["opsi b"] = colIdx
			} else if strings.Contains(cleanCell, "opsi c") || cleanCell == "c" {
				colMap["opsi c"] = colIdx
			} else if strings.Contains(cleanCell, "opsi d") || cleanCell == "d" {
				colMap["opsi d"] = colIdx
			} else if strings.Contains(cleanCell, "kunci") || strings.Contains(cleanCell, "jawaban") || strings.Contains(cleanCell, "key") {
				colMap["kunci"] = colIdx
			} else if strings.Contains(cleanCell, "poin") || strings.Contains(cleanCell, "point") || strings.Contains(cleanCell, "score") {
				colMap["poin"] = colIdx
			}
		}
	}

	getCell := func(row []string, colIndex int) string {
		if colIndex >= 0 && colIndex < len(row) {
			return strings.TrimSpace(row[colIndex])
		}
		return ""
	}

	orderIdx := 1

	for i := startRow; i < len(matrix); i++ {
		row := matrix[i]
		if len(row) == 0 {
			continue
		}

		// Check if entire row text was pasted into Column A (single cell containing commas)
		if len(row) == 1 || (len(row) > 1 && getCell(row, 1) == "" && strings.Contains(row[0], ",")) {
			// Split by comma
			r := csv.NewReader(strings.NewReader(row[0]))
			r.LazyQuotes = true
			r.FieldsPerRecord = -1
			if parsedRow, err := r.Read(); err == nil && len(parsedRow) > 1 {
				row = parsedRow
			}
		}

		qText := getCell(row, colMap["soal"])
		if qText == "" {
			continue
		}

		rawType := getCell(row, colMap["tipe"])
		qType, isAutoScored := normalizeQuestionType(rawType)

		points := 10
		if ptsStr := getCell(row, colMap["poin"]); ptsStr != "" {
			if parsedPts, err := strconv.Atoi(ptsStr); err == nil && parsedPts > 0 {
				points = parsedPts
			}
		}

		qID := uuid.New()
		q := domain.Question{
			ID:           qID,
			FormID:       formID,
			QuestionText: qText,
			QuestionType: qType,
			IsAutoScored: isAutoScored,
			Points:       points,
			OrderIndex:   orderIdx,
			IsRequired:   true,
		}
		orderIdx++

		var options []domain.QuestionOption
		kunciKey := strings.ToUpper(getCell(row, colMap["kunci"]))

		if qType == domain.TypeMultipleChoice {
			rawOpts := []string{
				getCell(row, colMap["opsi a"]),
				getCell(row, colMap["opsi b"]),
				getCell(row, colMap["opsi c"]),
				getCell(row, colMap["opsi d"]),
			}

			letters := []string{"A", "B", "C", "D"}
			for optIdx, optText := range rawOpts {
				if optText == "" {
					continue
				}
				isCorrect := (kunciKey == letters[optIdx]) || strings.HasPrefix(kunciKey, letters[optIdx])

				options = append(options, domain.QuestionOption{
					ID:         uuid.New(),
					QuestionID: qID,
					OptionText: optText,
					IsCorrect:  isCorrect,
					OrderIndex: optIdx + 1,
				})
			}
		} else if qType == domain.TypeYesNo {
			options = []domain.QuestionOption{
				{
					ID:         uuid.New(),
					QuestionID: qID,
					OptionText: "Ya",
					IsCorrect:  kunciKey == "A" || strings.Contains(kunciKey, "YA") || strings.Contains(kunciKey, "TRUE"),
					OrderIndex: 1,
				},
				{
					ID:         uuid.New(),
					QuestionID: qID,
					OptionText: "Tidak",
					IsCorrect:  kunciKey == "B" || strings.Contains(kunciKey, "TIDAK") || strings.Contains(kunciKey, "FALSE"),
					OrderIndex: 2,
				},
			}
		}

		q.Options = options
		extracted.Questions = append(extracted.Questions, q)
	}

	return extracted, nil
}
