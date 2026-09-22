package parser

import (
	"testing"

	"backend/internal/domain"
	"github.com/google/uuid"
)

func TestParseLinesToForm_UserSample(t *testing.T) {
	lines := []string{
		"1.\tPerhatikan ilustrasi berikut!  (Berdasarkan Jenisnya)",
		"Pada saat terjadi ketegangan di wilayah perbatasan laut Indonesia, sebuah negara asing mengirim kapal bersenjata lengkap memasuki wilayah perairan Indonesia tanpa izin. Kapal tersebut juga melakukan intimidasi terhadap nelayan lokal sehingga aktivitas masyarakat terganggu. Pemerintah Indonesia kemudian mengerahkan TNI AL untuk menjaga kedaulatan wilayah tersebut.",
		"Berdasarkan ilustrasi di atas, tindakan yang paling tepat untuk mengidentifikasi jenis ancaman terhadap NKRI adalah...",
		"(a) Ancaman ekonomi karena aktivitas nelayan lokal mengalami penurunan hasil tangkapan harian",
		"(b) Ancaman militer karena melibatkan penggunaan kekuatan bersenjata asing terhadap kedaulatan negara",
		"(c) Ancaman sosial karena masyarakat pesisir merasa takut ketika melaut setiap harinya",
		"(d) Ancaman budaya karena wilayah perbatasan mulai dipengaruhi kebiasaan negara asing",
		"(e) Ancaman politik karena pemerintah daerah mengalami kesulitan mengatur wilayah pesisir",
		"Kunci Jawaban: B",
		"________________________________________",
		"2.\tPerhatikan kasus berikut!",
		"Di media sosial beredar informasi palsu yang menyatakan bahwa pemerintah Indonesia sengaja menjual aset negara kepada pihak asing...",
		"Jika dianalisis berdasarkan jenis ancamannya, kasus tersebut termasuk ancaman nonmiliter karena...",
		"(a) Demonstrasi masyarakat menyebabkan kerusakan fasilitas umum...",
		"(b) Video editan yang tersebar membuat masyarakat...",
		"(c) Penyebaran hoaks digunakan untuk melemahkan persatuan masyarakat tanpa menggunakan kekuatan bersenjata",
		"(d) Akun anonim yang digunakan pelaku berasal dari luar negeri...",
		"(e) Informasi palsu menyebabkan munculnya perbedaan pendapat...",
		"Kunci Jawaban: C",
	}

	formID := uuid.New()
	extracted, err := parseLinesToForm(lines, formID)
	if err != nil {
		t.Fatalf("parseLinesToForm failed: %v", err)
	}

	if len(extracted.Questions) != 2 {
		t.Fatalf("Expected 2 questions, got %d", len(extracted.Questions))
	}

	// Verify Question 1
	q1 := extracted.Questions[0]
	if len(q1.Options) != 5 {
		t.Fatalf("Expected 5 options for Question 1, got %d", len(q1.Options))
	}

	// Check option B is correct
	if !q1.Options[1].IsCorrect {
		t.Fatalf("Expected Option B for Question 1 to be correct")
	}

	// Check option text
	if q1.Options[1].OptionText != "Ancaman militer karena melibatkan penggunaan kekuatan bersenjata asing terhadap kedaulatan negara" {
		t.Fatalf("Unexpected option text for Q1 Opt B: %s", q1.Options[1].OptionText)
	}

	// Verify Question 2
	q2 := extracted.Questions[1]
	if len(q2.Options) != 5 {
		t.Fatalf("Expected 5 options for Question 2, got %d", len(q2.Options))
	}

	// Check option C is correct
	if !q2.Options[2].IsCorrect {
		t.Fatalf("Expected Option C for Question 2 to be correct")
	}
}

func TestParseLinesToForm_WithTitleAndDescription(t *testing.T) {
	lines := []string{
		"Ujian Akhir Semester PPKn Kelas 11",
		"Silakan jawab pertanyaan berikut dengan memilih satu jawaban yang benar.",
		"Soal 1. Apa dasar negara Indonesia?",
		"A. UUD 1945",
		"B. Pancasila",
		"C. Burung Garuda",
		"D. Bhinneka Tunggal Ika",
		"Kunci Jawaban: B",
	}

	formID := uuid.New()
	extracted, err := parseLinesToForm(lines, formID)
	if err != nil {
		t.Fatalf("parseLinesToForm failed: %v", err)
	}

	if extracted.Title != "Ujian Akhir Semester PPKn Kelas 11" {
		t.Fatalf("Expected title 'Ujian Akhir Semester PPKn Kelas 11', got '%s'", extracted.Title)
	}
	if extracted.Description != "Silakan jawab pertanyaan berikut dengan memilih satu jawaban yang benar." {
		t.Fatalf("Expected description, got '%s'", extracted.Description)
	}

	if len(extracted.Questions) != 1 {
		t.Fatalf("Expected 1 question, got %d", len(extracted.Questions))
	}

	if !extracted.Questions[0].Options[1].IsCorrect {
		t.Fatalf("Expected Option B to be correct")
	}
}

func TestParseLinesToForm_Markers(t *testing.T) {
	lines := []string{
		"1. [ESAI] Jelaskan dampak pemanasan global secara rinci!",
		"Para siswa diminta menulis minimal 3 dampak beserta contoh nyata.",
		"2. [MATCHING] Cocokkan istilah dengan definisinya.",
		"A. Ekosistem -> Tempat interaksi makhluk hidup dan lingkungannya",
		"B. Populasi -> Kumpulan individu sejenis pada suatu wilayah",
		"3. [GAMBAR] Amati gambar berikut dengan saksama.",
	}

	formID := uuid.New()
	extracted, err := parseLinesToForm(lines, formID)
	if err != nil {
		t.Fatalf("parseLinesToForm failed: %v", err)
	}

	if len(extracted.Questions) != 3 {
		t.Fatalf("Expected 3 questions, got %d", len(extracted.Questions))
	}

	q1 := extracted.Questions[0]
	if q1.QuestionType != domain.TypeLongText {
		t.Fatalf("Expected LONG_TEXT for [ESAI], got %v", q1.QuestionType)
	}
	if q1.IsAutoScored {
		t.Fatalf("Expected esai to not be auto scored")
	}
	if q1.Points != 5 {
		t.Fatalf("Expected 5 points for esai, got %d", q1.Points)
	}

	q2 := extracted.Questions[1]
	if q2.QuestionType != domain.TypeMatching {
		t.Fatalf("Expected MATCHING for [MATCHING], got %v", q2.QuestionType)
	}
	if len(q2.Options) != 2 {
		t.Fatalf("Expected 2 match options, got %d", len(q2.Options))
	}
	if q2.Options[0].MatchTargetText == nil || *q2.Options[0].MatchTargetText != "Tempat interaksi makhluk hidup dan lingkungannya" {
		t.Fatalf("Expected match target split via '->', got %v", q2.Options[0].MatchTargetText)
	}

	q3 := extracted.Questions[2]
	if q3.QuestionType != domain.TypeImage {
		t.Fatalf("Expected IMAGE for [GAMBAR], got %v", q3.QuestionType)
	}
}

func TestParseLinesToForm_Sections(t *testing.T) {
	lines := []string{
		"Test Soal",
		"",
		"Pilihan Ganda",
		"1. Ibu kota Indonesia adalah?",
		"A. Bandung",
		"B. Jakarta",
		"C. Surabaya",
		"Kunci Jawaban: B",
		"",
		"Essai",
		"2. Sebutkan 3 penyebab pemanasan global.",
	}

	formID := uuid.New()
	extracted, err := parseLinesToForm(lines, formID)
	if err != nil {
		t.Fatalf("parseLinesToForm failed: %v", err)
	}

	if len(extracted.Questions) != 2 {
		t.Fatalf("Expected 2 questions, got %d", len(extracted.Questions))
	}

	q1 := extracted.Questions[0]
	if q1.QuestionType != domain.TypeMultipleChoice {
		t.Fatalf("Expected MULTIPLE_CHOICE under 'Pilihan Ganda', got %v", q1.QuestionType)
	}
	if !q1.Options[1].IsCorrect {
		t.Fatalf("Expected Option B correct for q1")
	}

	q2 := extracted.Questions[1]
	if q2.QuestionType != domain.TypeLongText {
		t.Fatalf("Expected LONG_TEXT under 'Essai', got %v", q2.QuestionType)
	}
	if q2.IsAutoScored {
		t.Fatalf("Expected esai not auto scored")
	}
}

func TestParseLinesToForm_SectionsNoBlank(t *testing.T) {
	lines := []string{
		"Test Soal",
		"Pilihan Ganda",
		"1. Ibu kota Indonesia adalah?",
		"Kunci Jawaban: A",
		"Essai",
		"2. Sebutkan 3 penyebab pemanasan global.",
	}

	formID := uuid.New()
	extracted, err := parseLinesToForm(lines, formID)
	if err != nil {
		t.Fatalf("parseLinesToForm failed: %v", err)
	}

	if len(extracted.Questions) != 2 {
		t.Fatalf("Expected 2 questions, got %d", len(extracted.Questions))
	}
	if extracted.Questions[0].QuestionType != domain.TypeMultipleChoice {
		t.Fatalf("Expected MULTIPLE_CHOICE, got %v", extracted.Questions[0].QuestionType)
	}
	if extracted.Questions[1].QuestionType != domain.TypeLongText {
		t.Fatalf("Expected LONG_TEXT, got %v", extracted.Questions[1].QuestionType)
	}
}
