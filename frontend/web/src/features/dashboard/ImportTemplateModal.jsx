import { Download } from 'lucide-react';
import { Modal } from '../../shared/Modal';
import { Button } from '../../shared/ui';

const TEMPLATES = {
  docx: {
    title: 'Format Dokumen Word (.docx)',
    intro:
      'Tulis tiap soal dengan pola berikut di dalam dokumen Word. Sistem membaca urutan baris, jadi ikuti pola persis (nomor soal, opsi A-E, lalu baris "Kunci Jawaban").',
    example: `Soal 1. Ibu kota Indonesia adalah?
A. Bandung
B. Jakarta
C. Surabaya
D. Medan
Kunci Jawaban: B

Soal 2. Sebutkan 3 penyebab pemanasan global.
(kosongkan opsi A-D dan baris Kunci Jawaban untuk soal esai)`,
    notes: [
      'Nomor soal boleh "Soal 1", "1.", "Question 1", dll — yang penting diakhiri titik/titik dua.',
      'Opsi jawaban ditulis "A.", "B.", "C.", dst (maksimal E).',
      'Baris "Kunci Jawaban: <huruf>" WAJIB ada untuk soal pilihan ganda — tanpa ini, soal tetap masuk tapi tanpa kunci jawaban.',
      'Untuk soal esai (tanpa opsi), cukup tulis pertanyaannya saja tanpa baris A-E dan Kunci Jawaban.',
      'Gambar yang ditempel langsung di dalam dokumen Word akan ikut terbawa otomatis.',
    ],
    fileName: 'template-soal.txt',
  },
  pdf: {
    title: 'Format Dokumen PDF',
    intro: 'Pola yang sama persis dengan format Word di atas — PDF dibaca sebagai teks biasa.',
    example: `Soal 1. Ibu kota Indonesia adalah?
A. Bandung
B. Jakarta
C. Surabaya
D. Medan
Kunci Jawaban: B`,
    notes: [
      'PDF harus berupa teks asli (bukan hasil scan/foto) — kalau PDF hasil scan, tidak ada teks yang bisa dibaca sama sekali.',
      'Gambar di dalam PDF TIDAK ikut terbawa otomatis (beda dari Word) — tambahkan manual lewat editor soal setelah form dibuat.',
    ],
    fileName: 'template-soal.txt',
  },
  excel: {
    title: 'Format Spreadsheet Excel (.xlsx) / CSV',
    intro: 'Buat kolom-kolom berikut di baris pertama (header), lalu isi satu baris per soal.',
    example: `No | Soal | Tipe | Opsi A | Opsi B | Opsi C | Opsi D | Kunci | Poin
1  | Ibu kota Indonesia? | pilihan_ganda | Bandung | Jakarta | Surabaya | Medan | B | 10
2  | Sebutkan penyebab pemanasan global | esai |  |  |  |  |  | 20`,
    notes: [
      'Nama kolom fleksibel — cukup mengandung kata "soal", "opsi a/b/c/d", "kunci"/"jawaban", "poin", sistem akan mendeteksi otomatis.',
      'Untuk soal esai, kosongkan saja kolom Opsi A-D dan Kunci.',
      'Kolom "Kunci" isi hurufnya saja (A/B/C/D), bukan teks jawabannya.',
    ],
    fileName: 'template-soal.csv',
  },
};

export default function ImportTemplateModal({ open, onClose, type, onContinue }) {
  const tpl = TEMPLATES[type];
  if (!tpl) return null;

  const downloadTemplate = () => {
    const blob = new Blob([tpl.example], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = tpl.fileName;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={tpl.title}
      size="lg"
      footer={
        <>
          <Button variant="outline" onClick={downloadTemplate}>
            <Download size={14} />
            Unduh Contoh
          </Button>
          <Button onClick={onContinue}>Lanjut Pilih File</Button>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <p className="text-sm text-text-secondary">{tpl.intro}</p>
        <pre className="overflow-x-auto whitespace-pre-wrap rounded-lg border border-border bg-bg-secondary p-3 text-xs text-text">
          {tpl.example}
        </pre>
        <ul className="flex flex-col gap-1.5 text-sm text-text-secondary">
          {tpl.notes.map((n, i) => (
            <li key={i} className="flex gap-2">
              <span className="text-primary">&bull;</span>
              <span>{n}</span>
            </li>
          ))}
        </ul>
      </div>
    </Modal>
  );
}
