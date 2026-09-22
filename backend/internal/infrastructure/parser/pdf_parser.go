package parser

import (
	"bytes"
	"fmt"
	"io"
	"strings"

	"github.com/google/uuid"
	"github.com/ledongthuc/pdf"
)

// PDFParser mengekstrak teks dari file PDF lalu memakai ulang parser baris
// (parseLinesToForm, sudah ada di docx_parser.go, satu package) untuk mengubahnya
// jadi ExtractedForm — sehingga format soal "Soal 1 / A. .. / Kunci Jawaban: A"
// yang sudah didukung untuk Word, otomatis juga jalan untuk PDF.
//
// CATATAN: gambar di dalam PDF TIDAK diekstrak (beda dengan docx_parser yang bisa
// ambil gambar dari relasi zip .docx). Kalau materi PDF punya gambar penting per soal,
// untuk saat ini guru perlu upload gambar itu manual lewat endpoint upload-image
// setelah form ter-generate. Ini limitasi library PDF teks-saja yang dipakai di bawah.
type PDFParser struct{}

func NewPDFParser() *PDFParser {
	return &PDFParser{}
}

// FIX: baru — ekstrak teks mentah saja (untuk lampiran materi AI), tanpa
// mem-parsing jadi struktur soal.
func (p *PDFParser) ExtractRawText(fileBytes []byte) (string, error) {
	lines, err := p.extractLines(fileBytes)
	if err != nil {
		return "", err
	}
	return strings.Join(lines, "\n"), nil
}

func (p *PDFParser) extractLines(fileBytes []byte) ([]string, error) {
	if len(fileBytes) == 0 {
		return nil, fmt.Errorf("file PDF kosong")
	}

	reader, err := pdf.NewReader(bytes.NewReader(fileBytes), int64(len(fileBytes)))
	if err != nil {
		return nil, fmt.Errorf("failed to open pdf: %w", err)
	}

	plainText, err := reader.GetPlainText()
	if err != nil {
		return nil, fmt.Errorf("failed to extract text from pdf: %w", err)
	}

	var buf bytes.Buffer
	if _, err := io.Copy(&buf, plainText); err != nil {
		return nil, fmt.Errorf("failed to read extracted pdf text: %w", err)
	}

	rawLines := strings.Split(buf.String(), "\n")
	var lines []string
	for _, l := range rawLines {
		trimmed := strings.TrimSpace(l)
		if trimmed != "" {
			lines = append(lines, trimmed)
		}
	}
	return lines, nil
}

func (p *PDFParser) ParsePDF(fileBytes []byte, formID uuid.UUID) (*ExtractedForm, error) {
	lines, err := p.extractLines(fileBytes)
	if err != nil {
		return nil, err
	}

	if len(lines) == 0 {
		return nil, fmt.Errorf("tidak ada teks yang bisa diekstrak dari PDF (kemungkinan PDF hasil scan/gambar, coba OCR dulu)")
	}

	extracted, err := parseLinesToForm(lines, formID)
	if err != nil {
		return nil, err
	}
	if extracted.Title == "Dokumen Soal Import Docx" {
		extracted.Title = "Dokumen Soal Import PDF"
	}
	extracted.Description = "Form ujian diimport secara otomatis dari dokumen PDF"
	return extracted, nil
}
