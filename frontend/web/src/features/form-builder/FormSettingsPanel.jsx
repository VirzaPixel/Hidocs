import { useState } from 'react';
import { Save } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Button, Input, Toggle, Card } from '../../shared/ui';
import MediaUploadField from '../../shared/MediaUploadField';
import { useToast } from '../../shared/Toast';
import { resolveMediaUrl } from '../../lib/utils';

function toLocalInputValue(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export default function FormSettingsPanel({ formId, settings, onSaved }) {
  const [form, setForm] = useState(() => ({
    duration_minutes: settings?.duration_minutes ?? 60,
    is_active_immediately: settings?.is_active_immediately ?? false,
    is_one_time_submission: settings?.is_one_time_submission ?? false,
    max_attempts: settings?.max_attempts ?? 0,
    randomize_questions: settings?.randomize_questions ?? false,
    randomize_options: settings?.randomize_options ?? false,
    start_time: toLocalInputValue(settings?.start_time),
    end_time: toLocalInputValue(settings?.end_time),
    theme_color: settings?.theme_color || '#4F46E5',
    cover_image_url: settings?.cover_image_url || null,
    allow_backtrack: settings?.allow_backtrack ?? true,
    show_question_number: settings?.show_question_number ?? true,
    fullscreen_mode: settings?.fullscreen_mode ?? true,
    exam_token: settings?.exam_token || '',
    is_token_protected: settings?.is_token_protected ?? false,
  }));
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  const patch = (fields) => setForm((f) => ({ ...f, ...fields }));

  const handleSave = async () => {
    setSaving(true);
    try {
      const payload = {
        duration_minutes: Number(form.duration_minutes) || 0,
        auto_active_days: 30,
        is_active_immediately: form.is_active_immediately,
        is_one_time_submission: form.is_one_time_submission,
        max_attempts: Number(form.max_attempts) || 0,
        randomize_questions: form.randomize_questions,
        randomize_options: form.randomize_options,
        start_time: form.start_time ? new Date(form.start_time).toISOString() : null,
        end_time: form.end_time ? new Date(form.end_time).toISOString() : null,
        theme_color: form.theme_color,
        cover_image_url: form.cover_image_url || null,
        logo_url: settings?.logo_url || null,
        font_family: settings?.font_family || null,
        allow_backtrack: form.allow_backtrack,
        show_question_number: form.show_question_number,
        fullscreen_mode: form.fullscreen_mode,
        exam_token: form.exam_token || null,
        is_token_protected: form.is_token_protected,
      };
      const updated = await formApi.updateSettings(formId, payload);
      toast.success('Pengaturan form disimpan');
      onSaved?.(updated);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex flex-col gap-5">
      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">Waktu Ujian</h3>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <Input
            label="Durasi Pengerjaan (menit)"
            type="number"
            min={1}
            value={form.duration_minutes}
            onChange={(e) => patch({ duration_minutes: e.target.value })}
          />
          <div />
          <Input
            label="Mulai"
            type="datetime-local"
            value={form.start_time}
            onChange={(e) => patch({ start_time: e.target.value })}
          />
          <Input
            label="Selesai"
            type="datetime-local"
            value={form.end_time}
            onChange={(e) => patch({ end_time: e.target.value })}
          />
        </div>
        <Toggle
          checked={form.is_active_immediately}
          onChange={(v) => patch({ is_active_immediately: v })}
          label="Aktifkan otomatis begitu jadwal mulai tiba"
        />
      </Card>

      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">Batas Percobaan</h3>
        <Toggle
          checked={form.is_one_time_submission}
          onChange={(v) => patch({ is_one_time_submission: v })}
          label="Satu kali pengerjaan (mode sederhana)"
        />
        <Input
          label="Atau: batas jumlah percobaan (angka, 0 = tidak dibatasi)"
          type="number"
          min={0}
          value={form.max_attempts}
          onChange={(e) => patch({ max_attempts: e.target.value })}
          hint="Kalau diisi angka > 0, ini yang berlaku. Kalau 0, mengikuti toggle di atas."
        />
      </Card>

      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">Keamanan & Navigasi</h3>
        <Toggle
          checked={form.randomize_questions}
          onChange={(v) => patch({ randomize_questions: v })}
          label="Acak urutan soal per siswa"
        />
        <Toggle
          checked={form.randomize_options}
          onChange={(v) => patch({ randomize_options: v })}
          label="Acak urutan opsi jawaban per siswa"
        />
        <Toggle
          checked={form.allow_backtrack}
          onChange={(v) => patch({ allow_backtrack: v })}
          label="Izinkan siswa kembali ke soal sebelumnya"
        />
        <Toggle
          checked={form.show_question_number}
          onChange={(v) => patch({ show_question_number: v })}
          label="Tampilkan nomor soal ke siswa"
        />
        <Toggle
          checked={form.fullscreen_mode}
          onChange={(v) => patch({ fullscreen_mode: v })}
          label="Wajibkan mode kunci layar (pinned) di aplikasi mobile"
        />
      </Card>

      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">Token Akses (opsional)</h3>
        <Toggle
          checked={form.is_token_protected}
          onChange={(v) => patch({ is_token_protected: v })}
          label="Wajibkan kode token untuk masuk ujian"
        />
        {form.is_token_protected && (
          <Input
            label="Kode Token"
            placeholder="Contoh: KELAS8B-2026"
            value={form.exam_token}
            onChange={(e) => patch({ exam_token: e.target.value })}
          />
        )}
      </Card>

      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">Banner Form</h3>
        <p className="text-sm text-text-secondary">
          Gambar ini tampil di kartu form pada halaman "Form Saya", supaya form kamu mudah
          dikenali di antara form lain.
        </p>
        {form.cover_image_url && (
          <img
            src={resolveMediaUrl(form.cover_image_url)}
            alt="Banner saat ini"
            className="h-32 w-full rounded-lg border border-border object-cover"
          />
        )}
        <MediaUploadField
          mediaType="IMAGE"
          value={form.cover_image_url}
          onChange={(v) => patch({ cover_image_url: v })}
          label={form.cover_image_url ? 'Ganti Banner' : 'Unggah Banner'}
        />
      </Card>

      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">Tema Preview Siswa</h3>
        <p className="text-sm text-text-secondary">
          Warna ini hanya dipakai di halaman Preview Simulasi Siswa (tampilan yang dilihat siswa),
          terpisah dari warna aplikasi HiDocs ini.
        </p>
        <div className="flex items-center gap-3">
          <input
            type="color"
            value={form.theme_color}
            onChange={(e) => patch({ theme_color: e.target.value })}
            className="h-10 w-14 cursor-pointer rounded border border-border bg-transparent"
          />
          <Input value={form.theme_color} onChange={(e) => patch({ theme_color: e.target.value })} className="w-32" />
        </div>
      </Card>

      <Button onClick={handleSave} loading={saving} className="self-start">
        <Save size={16} />
        Simpan Pengaturan
      </Button>
    </div>
  );
}
