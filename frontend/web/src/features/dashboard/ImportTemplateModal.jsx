import { Download } from 'lucide-react';
import { Modal } from '../../shared/Modal';
import { Button } from '../../shared/ui';

const TEMPLATES = {
  docx: {
    title: 'Format Dokumen Word (.docx) - Template Terbaru',
    intro:
      'Gunakan format template terbaru di bawah ini atau unduh file template resmi .docx. Sistem secara otomatis mendeteksi 10 tipe soal, opsi jawaban, dan kunci jawaban bertanda bintang (*).',
    example: `1. Apa ibu kota negara Indonesia?
A. Surabaya
*B. Nusantara
C. Bandung
D. Medan

2. Pilih hewan mamalia berikut! (boleh lebih dari satu jawaban)
[Checkbox]
*A. Paus
B. Hiu
*C. Kelelawar
D. Buaya

3. Jelaskan pengertian dari fotosintesis!
[Essay]

4. Air mendidih pada suhu .... derajat Celsius.
[Isian]

5. Apakah air mendidih pada suhu 100 derajat Celsius?
*A. Ya
B. Tidak

6. Seberapa puas Anda dengan materi ujian ini?
[Rating 5]

7. Tuliskan rumus luas lingkaran!
[Math]

8. Tuliskan fungsi untuk menjumlahkan dua bilangan!
[Code]

9. Jelaskan makna yang terkandung pada diagram berikut!
[Image]

10. Jodohkan negara dengan ibu kotanya!
[Matching]
Indonesia | Jakarta
Jepang | Tokyo
Prancis | Paris
Jerman | Berlin`,
    notes: [
      'Nomor soal diawali angka titik: "1.", "1)", "Soal 1."',
      'Pilihan Ganda (PG): Tambahkan tanda bintang (*) di depan huruf opsi yang benar (contoh: *B. Nusantara) atau tulis "Kunci Jawaban: B".',
      'Checkbox: Beri tag [Checkbox] di bawah soal. Opsi benar dapat lebih dari satu menggunakan tanda (*).',
      'Essay / Isian Singkat: Gunakan tag [Essay] atau [Isian].',
      'Ya / Tidak: Buat opsi *A. Ya dan B. Tidak, atau gunakan tag [Ya/Tidak].',
      'Menjodohkan: Gunakan tag [Matching] lalu tulis pasangan "Kiri | Kanan" di tiap baris.',
      'Gambar: Tempelkan gambar langsung di dokumen Word Anda, sistem akan mengekstraknya otomatis.',
    ],
    fileUrl: '/templates/template_import.docx',
    fileName: 'template-import-hidocs.docx',
  },
  pdf: {
    title: 'Format Dokumen PDF',
    intro: 'Pola yang sama persis dengan format Word di atas — PDF dibaca sebagai teks biasa.',
    example: `1. Apa ibu kota negara Indonesia?
A. Bandung
*B. Nusantara
C. Surabaya
D. Medan

2. Jelaskan pengertian dari fotosintesis!
[Essay]`,
    notes: [
      'PDF harus berupa teks asli (bukan hasil scan/foto) agar dapat dibaca sistem.',
      'Gambar di dalam PDF tidak dapat diekstrak otomatis — dapat diunggah manual di form builder.',
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
    if (tpl.fileUrl) {
      const a = document.createElement('a');
      a.href = tpl.fileUrl;
      a.download = tpl.fileName;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      return;
    }
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
