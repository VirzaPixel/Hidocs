import { useState, useMemo, useEffect, useRef } from 'react';
import { Save, Dices, RotateCcw, Palette, Sparkles, X, Plus, Trash2, ArrowUp, ArrowDown, UserCheck, KeyRound, Layers, Check, AlertCircle } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Button, Input, Toggle, Card, Select, Badge } from '../../shared/ui';
import MediaUploadField from '../../shared/MediaUploadField';
import { useToast } from '../../shared/Toast';
import { useLangStore } from '../../store/langStore';
import { resolveMediaUrl, cn } from '../../lib/utils';

const THEME_PRESETS = [
  { name: 'Indigo (Default)', color: '#4F46E5' },
  { name: 'Emerald Green', color: '#059669' },
  { name: 'Royal Violet', color: '#7C3AED' },
  { name: 'Rose Pink', color: '#E11D48' },
  { name: 'Amber Gold', color: '#D97706' },
  { name: 'Sky Blue', color: '#0284C7' },
  { name: 'Crimson Red', color: '#DC2626' },
  { name: 'Slate Dark', color: '#334155' },
];

const FONT_OPTIONS = [
  { value: 'Inter', label: 'Inter (Modern Clean)' },
  { value: 'Plus Jakarta Sans', label: 'Plus Jakarta Sans (Formal)' },
  { value: 'Poppins', label: 'Poppins (Friendly)' },
  { value: 'Roboto', label: 'Roboto (Standard)' },
  { value: 'Outfit', label: 'Outfit (Geometric)' },
  { value: 'Merriweather', label: 'Merriweather (Serif Klasik)' },
  { value: 'Fira Code', label: 'Fira Code (Monospace/Kode)' },
];

const DEFAULT_IDENTITY_FIELDS = [
  { id: 'field_name', label: 'Nama Lengkap', field_type: 'text', placeholder: 'Masukkan nama lengkap kamu', is_required: true },
  { id: 'field_class', label: 'Kelas', field_type: 'dropdown', placeholder: 'Pilih Kelas', is_required: true, options: ['X RPL 1', 'X RPL 2', 'XI RPL 1', 'XI RPL 2', 'XII RPL 1', 'XII RPL 2'] },
  { id: 'field_absence', label: 'Nomor Absen', field_type: 'number', placeholder: 'Contoh: 18', is_required: true },
];

function parseIdentityFields(jsonStr) {
  if (!jsonStr) return [];
  try {
    const parsed = JSON.parse(jsonStr);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function toLocalInputValue(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function generateSlug(text) {
  return (text || '')
    .toString()
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function generateRandomSuffix(len = 6) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let res = '';
  for (let i = 0; i < len; i++) {
    res += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return res;
}

function generateRandomToken() {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const digits = '23456789';
  let p1 = '';
  let p2 = '';
  for (let i = 0; i < 4; i++) p1 += letters.charAt(Math.floor(Math.random() * letters.length));
  for (let i = 0; i < 4; i++) p2 += digits.charAt(Math.floor(Math.random() * digits.length));
  return `${p1}-${p2}`;
}

export default function FormSettingsPanel({ formId, formData, settings, onSaved, isActive = true }) {
  const { t } = useLangStore();
  const [form, setForm] = useState(() => ({
    custom_url: formData?.custom_url || '',
    duration_minutes: settings?.duration_minutes ?? 60,
    is_active_immediately: settings?.is_active_immediately ?? false,
    is_one_time_submission: settings?.is_one_time_submission ?? false,
    max_attempts: settings?.max_attempts ?? 0,
    randomize_questions: settings?.randomize_questions ?? false,
    randomize_options: settings?.randomize_options ?? false,
    start_time: toLocalInputValue(settings?.start_time),
    end_time: toLocalInputValue(settings?.end_time),
    theme_color: settings?.theme_color || '#4F46E5',
    font_family: settings?.font_family || 'Inter',
    cover_image_url: settings?.cover_image_url || null,
    allow_backtrack: settings?.allow_backtrack ?? true,
    show_question_number: settings?.show_question_number ?? true,
    fullscreen_mode: settings?.fullscreen_mode ?? false,
    exam_token: settings?.exam_token || '',
    is_token_protected: settings?.is_token_protected ?? false,
  }));

  const [identityFields, setIdentityFields] = useState(() =>
    parseIdentityFields(settings?.identity_fields_json)
  );
  const [enableIdentityPage, setEnableIdentityPage] = useState(() => {
    const fields = parseIdentityFields(settings?.identity_fields_json);
    return fields.length > 0;
  });
  const [saving, setSaving] = useState(false);
  const [lastSavedAt, setLastSavedAt] = useState(null);
  const toast = useToast();

  const patch = (fields) => setForm((f) => ({ ...f, ...fields }));

  const getPayload = (currentState, currentIdentity, currentEnableIdentity) => {
    const fieldsToSave = currentEnableIdentity ? currentIdentity : [];
    return {
      duration_minutes: Number(currentState.duration_minutes) || 0,
      auto_active_days: 30,
      is_active_immediately: currentState.is_active_immediately,
      is_one_time_submission: currentState.is_one_time_submission,
      max_attempts: Number(currentState.max_attempts) || 0,
      randomize_questions: currentState.randomize_questions,
      randomize_options: currentState.randomize_options,
      start_time: currentState.start_time ? new Date(currentState.start_time).toISOString() : null,
      end_time: currentState.end_time ? new Date(currentState.end_time).toISOString() : null,
      theme_color: currentState.theme_color,
      font_family: currentState.font_family,
      cover_image_url: currentState.cover_image_url || null,
      logo_url: settings?.logo_url || null,
      allow_backtrack: currentState.allow_backtrack,
      show_question_number: currentState.show_question_number,
      fullscreen_mode: currentState.fullscreen_mode,
      exam_token: currentState.is_token_protected ? currentState.exam_token?.trim() || null : null,
      is_token_protected: currentState.is_token_protected,
      identity_fields_json: JSON.stringify(fieldsToSave),
      custom_url: currentState.custom_url,
    };
  };

  const [savedSnapshot, setSavedSnapshot] = useState(() => {
    return JSON.stringify(getPayload(form, identityFields, enableIdentityPage));
  });

  const currentSnapshot = JSON.stringify(getPayload(form, identityFields, enableIdentityPage));
  const isDirty = savedSnapshot !== currentSnapshot;

  const handleRandomizeUrl = () => {
    const base = generateSlug(formData?.title || 'ujian') || 'form';
    const rand = generateRandomSuffix(5);
    patch({ custom_url: `${base}-${rand}` });
    toast.info('Custom URL baru diacak');
  };

  const handleResetUrlToTitle = () => {
    const standard = generateSlug(formData?.title || 'ujian') || 'form-ujian';
    patch({ custom_url: standard });
    toast.info('Custom URL direset sesuai judul form');
  };

  const handleRandomizeToken = () => {
    const newToken = generateRandomToken();
    patch({ exam_token: newToken, is_token_protected: true });
    toast.info(`Token diacak: ${newToken}`);
  };

  const handleClearToken = () => {
    patch({ exam_token: '', is_token_protected: false });
  };

  // Identity Fields Management
  const handleAddField = () => {
    const newField = {
      id: `field_${Date.now()}`,
      label: 'Field Baru',
      field_type: 'text',
      placeholder: 'Masukkan data...',
      is_required: true,
      options: [],
    };
    setIdentityFields((prev) => [...prev, newField]);
  };

  const handleUpdateField = (index, updated) => {
    setIdentityFields((prev) => {
      const copy = [...prev];
      copy[index] = { ...copy[index], ...updated };
      return copy;
    });
  };

  const handleDeleteField = (index) => {
    setIdentityFields((prev) => prev.filter((_, i) => i !== index));
  };

  const handleMoveField = (index, direction) => {
    const targetIdx = index + direction;
    if (targetIdx < 0 || targetIdx >= identityFields.length) return;
    setIdentityFields((prev) => {
      const copy = [...prev];
      const temp = copy[index];
      copy[index] = copy[targetIdx];
      copy[targetIdx] = temp;
      return copy;
    });
  };

  const handleResetDefaultIdentityFields = () => {
    setIdentityFields(DEFAULT_IDENTITY_FIELDS);
    toast.info('Template data peserta standar dimuat (Nama, Kelas, No Absen, Email)');
  };

  const handleSave = async (silent = false) => {
    if (saving) return;
    const payload = getPayload(form, identityFields, enableIdentityPage);
    const snapshotToSave = JSON.stringify(payload);
    setSaving(true);
    try {
      const { custom_url, ...settingsPayload } = payload;
      await formApi.updateSettings(formId, settingsPayload);
      if (form.custom_url !== formData?.custom_url) {
        await formApi.update(formId, {
          title: formData.title,
          description: formData.description || '',
          category: formData.category || '',
          type: formData.type,
          custom_url: form.custom_url.trim(),
          status: formData.status,
          is_template: formData.is_template,
        });
      }
      setSavedSnapshot(snapshotToSave);
      setLastSavedAt(new Date());
      if (!silent) {
        toast.success(t('settings.settingsSaved', 'Pengaturan form berhasil disimpan'));
      }
      onSaved?.();
    } catch (err) {
      if (!silent) {
        toast.error(err.message);
      }
    } finally {
      setSaving(false);
    }
  };

  // 1. Debounced auto-save (1200ms after user finishes changing settings)
  useEffect(() => {
    if (!isDirty || saving) return;

    const timer = setTimeout(() => {
      handleSave(true);
    }, 1200);

    return () => clearTimeout(timer);
  }, [currentSnapshot, isDirty, saving]);

  // 2. Auto-save on Tab change (when switching away from settings tab)
  const prevIsActiveRef = useRef(isActive);
  useEffect(() => {
    if (prevIsActiveRef.current && !isActive && isDirty && !saving) {
      handleSave(true);
    }
    prevIsActiveRef.current = isActive;
  }, [isActive, isDirty, saving]);

  // 3. Auto-save on Unmount (when navigating to any other sidebar route or page)
  const latestDataRef = useRef({ form, identityFields, enableIdentityPage, isDirty, saving });
  useEffect(() => {
    latestDataRef.current = { form, identityFields, enableIdentityPage, isDirty, saving };
  });

  useEffect(() => {
    return () => {
      const { form: f, identityFields: idf, enableIdentityPage: eid, isDirty: dirty, saving: isSaving } = latestDataRef.current;
      if (dirty && !isSaving) {
        const payload = getPayload(f, idf, eid);
        const { custom_url, ...settingsPayload } = payload;
        formApi.updateSettings(formId, settingsPayload).catch(() => {});
        if (f.custom_url !== formData?.custom_url) {
          formApi.update(formId, {
            title: formData.title,
            description: formData.description || '',
            category: formData.category || '',
            type: formData.type,
            custom_url: f.custom_url.trim(),
            status: formData.status,
            is_template: formData.is_template,
          }).catch(() => {});
        }
      }
    };
  }, [formId]);

  return (
    <div className="flex flex-col gap-5 relative">

      {/* 1. Halaman Pengumpulan Data Peserta (Identity Page) */}
      <Card className="flex flex-col gap-4 border-primary/20">
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <UserCheck size={20} className="text-primary" />
              <h3 className="font-semibold text-text">Halaman 1: Data Peserta / Siswa (Identity Page)</h3>
            </div>
            <p className="text-xs text-text-secondary mt-1">
              Atur data apa saja yang wajib diisi oleh siswa sebelum dapat memulai ujian (misal: Nama, Kelas, No. Absen, Email, NISN, dll.).
            </p>
          </div>
          <Toggle
            checked={enableIdentityPage}
            onChange={(v) => {
              setEnableIdentityPage(v);
              if (v && identityFields.length === 0) {
                setIdentityFields(DEFAULT_IDENTITY_FIELDS);
              }
            }}
            label="Aktifkan"
          />
        </div>

        {enableIdentityPage && (
          <div className="flex flex-col gap-3 pt-2 border-t border-border">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="text-xs font-semibold uppercase tracking-wider text-text-secondary">
                Daftar Field Input ({identityFields.length} Data)
              </span>
              <div className="flex items-center gap-2">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={handleResetDefaultIdentityFields}
                  className="text-xs"
                >
                  <RotateCcw size={13} />
                  Template Standar
                </Button>
                <Button
                  type="button"
                  variant="primary"
                  size="sm"
                  onClick={handleAddField}
                  className="text-xs"
                >
                  <Plus size={14} />
                  Tambah Data Baru
                </Button>
              </div>
            </div>

            {identityFields.length === 0 ? (
              <div className="rounded-lg border border-dashed border-border p-4 text-center text-xs text-text-secondary">
                Belum ada field data peserta. Klik "+ Tambah Data Baru" atau gunakan "Template Standar".
              </div>
            ) : (
              <div className="flex flex-col gap-3">
                {identityFields.map((field, idx) => (
                  <div
                    key={field.id || idx}
                    className="flex flex-col gap-3 rounded-xl border border-border bg-bg-secondary p-3 sm:p-4 transition-all"
                  >
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <span className="flex h-5 w-5 items-center justify-center rounded-full bg-primary text-[11px] font-bold text-white">
                          {idx + 1}
                        </span>
                        <span className="text-xs font-bold text-text">{field.label || `Field ${idx + 1}`}</span>
                        {field.is_required && (
                          <Badge className="bg-red-500/10 text-red-600 text-[10px] py-0 px-1.5 font-medium">
                            Wajib Diisi
                          </Badge>
                        )}
                      </div>

                      <div className="flex items-center gap-1">
                        <button
                          type="button"
                          onClick={() => handleMoveField(idx, -1)}
                          disabled={idx === 0}
                          className="rounded p-1 text-text-secondary hover:bg-surface disabled:opacity-30"
                          title="Pindah ke atas"
                        >
                          <ArrowUp size={14} />
                        </button>
                        <button
                          type="button"
                          onClick={() => handleMoveField(idx, 1)}
                          disabled={idx === identityFields.length - 1}
                          className="rounded p-1 text-text-secondary hover:bg-surface disabled:opacity-30"
                          title="Pindah ke bawah"
                        >
                          <ArrowDown size={14} />
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDeleteField(idx)}
                          className="rounded p-1 text-text-secondary hover:bg-danger/10 hover:text-danger ml-1"
                          title="Hapus field ini"
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                      <Input
                        label="Label / Nama Data"
                        value={field.label}
                        onChange={(e) => handleUpdateField(idx, { label: e.target.value })}
                        placeholder="Contoh: Nomor Induk Siswa (NISN)"
                      />
                      <Select
                        label="Tipe Input"
                        value={field.field_type}
                        onChange={(e) => handleUpdateField(idx, { field_type: e.target.value })}
                      >
                        <option value="text">Teks Singkat</option>
                        <option value="number">Angka / Numerik</option>
                        <option value="dropdown">Pilihan Dropdown (Kelas/Jurusan)</option>
                        <option value="email">Alamat Email</option>
                      </Select>
                      <Input
                        label="Placeholder / Petunjuk"
                        value={field.placeholder || ''}
                        onChange={(e) => handleUpdateField(idx, { placeholder: e.target.value })}
                        placeholder="Contoh: Ketik nama lengkap..."
                      />
                    </div>

                    {field.field_type === 'dropdown' && (
                      <div className="rounded-lg border border-border bg-surface p-3 flex flex-col gap-2">
                        <label className="text-xs font-semibold text-text">
                          Opsi Pilihan Dropdown (Pisahkan dengan koma atau baris baru):
                        </label>
                        <textarea
                          rows={2}
                          className="w-full rounded-md border border-border bg-bg-secondary px-3 py-1.5 text-xs text-text focus:border-primary focus:outline-none"
                          placeholder="X RPL 1, X RPL 2, XI RPL 1, XI RPL 2"
                          value={(field.options || []).join(', ')}
                          onChange={(e) => {
                            const opts = e.target.value
                              .split(/,|\n/)
                              .map((s) => s.trim())
                              .filter(Boolean);
                            handleUpdateField(idx, { options: opts });
                          }}
                        />
                        <div className="flex flex-wrap gap-1.5">
                          {(field.options || []).map((opt, optIdx) => (
                            <span
                              key={optIdx}
                              className="inline-flex items-center gap-1 rounded-md bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary"
                            >
                              {opt}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}

                    <div className="flex items-center justify-end">
                      <Toggle
                        checked={field.is_required}
                        onChange={(v) => handleUpdateField(idx, { is_required: v })}
                        label="Wajib diisi oleh siswa"
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </Card>

      {/* 2. Token Akses Ujian (Gatekeeper Page 2) */}
      <Card className="flex flex-col gap-4 border-amber-500/20">
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <KeyRound size={20} className="text-amber-500" />
              <h3 className="font-semibold text-text">Halaman 2: Token Gatekeeper Ujian</h3>
            </div>
            <p className="text-xs text-text-secondary mt-1">
              Jika aktif, setelah mengisi data diri siswa akan diarahkan ke halaman khusus memasukkan Token Akses sebelum soal ujian dimulai.
            </p>
          </div>
          <Toggle
            checked={form.is_token_protected}
            onChange={(v) => patch({ is_token_protected: v })}
            label="Wajibkan Token"
          />
        </div>

        {form.is_token_protected && (
          <div className="flex flex-col gap-3 pt-2 border-t border-border">
            <div className="rounded-lg bg-amber-500/10 p-3 text-xs text-amber-600 border border-amber-500/20 flex items-center gap-2">
              <Layers size={16} className="shrink-0" />
              <span>
                <strong>Alur Masuk Siswa:</strong> Siswa mengisi Data Peserta (Page 1) &rarr; Memasukkan Token Ujian (Page 2) &rarr; Mulai Pengerjaan Soal (Page 3).
              </span>
            </div>

            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
              <div className="flex-1">
                <Input
                  label="Kode Token Ujian"
                  placeholder="Contoh: KELAS8B-2026"
                  value={form.exam_token}
                  onChange={(e) => patch({ exam_token: e.target.value.toUpperCase() })}
                  className="font-mono tracking-wider uppercase font-bold text-base"
                />
              </div>
              <div className="flex items-end gap-2 pb-0.5">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={handleRandomizeToken}
                  title="Acak token acak baru"
                >
                  <Dices size={15} />
                  Acak Token
                </Button>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={handleClearToken}
                  title="Hapus token"
                  className="text-text-secondary hover:text-danger"
                >
                  <X size={15} />
                </Button>
              </div>
            </div>
          </div>
        )}
      </Card>

      {/* 3. Tautan Akses & Custom URL */}
      <Card className="flex flex-col gap-4">
        <div>
          <h3 className="font-semibold text-text">{t('settings.accessLinkTitle', 'Tautan Akses Form')}</h3>
          <p className="text-xs text-text-secondary mt-0.5">
            {t('settings.customUrlHint', 'Gunakan huruf kecil, angka, dan tanda hubung. Tautan ini dipakai aplikasi mobile dan QR code.')}
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div className="flex-1">
            <Input
              value={form.custom_url}
              onChange={(e) => patch({ custom_url: e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, '-') })}
              placeholder="contoh: ujian-ipa-kelas-8b"
            />
          </div>
          <div className="flex items-center gap-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={handleRandomizeUrl}
              title="Acak slug URL dengan kombinasi unik"
            >
              <Dices size={15} />
              {t('settings.randomizeUrl', 'Acak URL')}
            </Button>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={handleResetUrlToTitle}
              title="Reset URL ke slug judul asli"
            >
              <RotateCcw size={15} />
              {t('settings.resetToTitleUrl', 'Reset ke Judul')}
            </Button>
          </div>
        </div>
      </Card>

      {/* 4. Tema & Kustomisasi Tampilan */}
      <Card className="flex flex-col gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Palette size={18} className="text-primary" />
            <h3 className="font-semibold text-text">{t('settings.themeTitle', 'Kustomisasi Tema & Tampilan')}</h3>
          </div>
          <p className="text-xs text-text-secondary mt-0.5">
            {t('settings.themeDesc', 'Pilih warna tema dan font untuk tampilan simulasi dan pengerjaan ujian siswa.')}
          </p>
        </div>

        <div>
          <label className="text-xs font-medium text-text mb-2 block">{t('settings.themeColor', 'Warna Tema / Aksen')}</label>
          <div className="flex flex-wrap items-center gap-2 mb-3">
            {THEME_PRESETS.map((preset) => (
              <button
                key={preset.color}
                type="button"
                onClick={() => patch({ theme_color: preset.color })}
                className={cn(
                  'flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium transition-all',
                  form.theme_color?.toLowerCase() === preset.color.toLowerCase()
                    ? 'border-primary ring-2 ring-primary/20 bg-primary/5 font-semibold'
                    : 'border-border bg-surface hover:bg-bg-secondary text-text-secondary'
                )}
              >
                <span className="h-3 w-3 rounded-full shrink-0 shadow-xs" style={{ backgroundColor: preset.color }} />
                <span>{preset.name}</span>
              </button>
            ))}
          </div>

          <div className="flex items-center gap-3">
            <input
              type="color"
              value={form.theme_color}
              onChange={(e) => patch({ theme_color: e.target.value })}
              className="h-10 w-14 cursor-pointer rounded-lg border border-border bg-transparent p-1"
            />
            <Input
              value={form.theme_color}
              onChange={(e) => patch({ theme_color: e.target.value })}
              className="w-36 font-mono text-sm uppercase"
              placeholder="#4F46E5"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <Select
            label={t('settings.fontFamily', 'Gaya Font')}
            value={form.font_family}
            onChange={(e) => patch({ font_family: e.target.value })}
          >
            {FONT_OPTIONS.map((f) => (
              <option key={f.value} value={f.value}>
                {f.label}
              </option>
            ))}
          </Select>
        </div>

        {/* Live Mini Preview Box */}
        <div className="mt-1 rounded-xl border border-border bg-bg-secondary p-4">
          <p className="text-xs font-semibold uppercase tracking-wider text-text-secondary mb-3 flex items-center gap-1.5">
            <Sparkles size={14} className="text-primary" />
            Live Preview Tema Siswa
          </p>
          <div
            className="rounded-lg border border-border bg-white p-4 shadow-sm"
            style={{ fontFamily: form.font_family || 'Inter' }}
          >
            <div
              className="rounded-md px-3 py-2 text-white text-xs font-semibold flex items-center justify-between shadow-xs mb-3"
              style={{ backgroundColor: form.theme_color }}
            >
              <span className="truncate">{formData?.title || 'Asesmen Ujian Siswa'}</span>
              <span className="opacity-90">Soal 1/20</span>
            </div>
            <p className="text-xs font-semibold text-gray-800 mb-2">1. Manakah jawaban yang paling tepat?</p>
            <div className="space-y-1.5 mb-3 text-xs">
              <div
                className="flex items-center gap-2 rounded-md border p-2 bg-indigo-50/40 text-gray-800"
                style={{ borderColor: form.theme_color }}
              >
                <span
                  className="flex h-4 w-4 items-center justify-center rounded-full text-[10px] text-white font-bold"
                  style={{ backgroundColor: form.theme_color }}
                >
                  A
                </span>
                <span>Opsi Jawaban Terpilih (Siswa)</span>
              </div>
              <div className="flex items-center gap-2 rounded-md border border-gray-200 p-2 text-gray-600 bg-white">
                <span className="flex h-4 w-4 items-center justify-center rounded-full bg-gray-100 text-[10px] text-gray-600 font-bold">
                  B
                </span>
                <span>Opsi Jawaban Lainnya</span>
              </div>
            </div>
            <div className="flex justify-end">
              <button
                type="button"
                className="rounded-md px-3 py-1.5 text-xs font-medium text-white shadow-xs"
                style={{ backgroundColor: form.theme_color }}
              >
                Berikutnya &rarr;
              </button>
            </div>
          </div>
        </div>
      </Card>

      {/* 5. Waktu & Durasi Ujian */}
      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">{t('settings.scheduleTitle', 'Waktu Ujian')}</h3>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <Input
            label={t('settings.durationMinutes', 'Durasi Pengerjaan (menit)')}
            type="number"
            min={1}
            value={form.duration_minutes}
            onChange={(e) => patch({ duration_minutes: e.target.value })}
          />
          <div />
          <Input
            label={t('settings.startTime', 'Mulai')}
            type="datetime-local"
            value={form.start_time}
            onChange={(e) => patch({ start_time: e.target.value })}
          />
          <Input
            label={t('settings.endTime', 'Selesai')}
            type="datetime-local"
            value={form.end_time}
            onChange={(e) => patch({ end_time: e.target.value })}
          />
        </div>
        <Toggle
          checked={form.is_active_immediately}
          onChange={(v) => patch({ is_active_immediately: v })}
          label={t('settings.autoActivate', 'Aktifkan otomatis begitu jadwal mulai tiba')}
        />
      </Card>

      {/* 6. Batas Percobaan */}
      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">{t('settings.attemptsTitle', 'Batas Percobaan')}</h3>
        <Toggle
          checked={form.is_one_time_submission}
          onChange={(v) => patch({ is_one_time_submission: v })}
          label={t('settings.oneTimeSubmission', 'Satu kali pengerjaan (mode sederhana)')}
        />
        <Input
          label={t('settings.maxAttempts', 'Atau: batas jumlah percobaan (angka, 0 = tidak dibatasi)')}
          type="number"
          min={0}
          value={form.max_attempts}
          onChange={(e) => patch({ max_attempts: e.target.value })}
          hint="Kalau diisi angka > 0, ini yang berlaku. Kalau 0, mengikuti toggle di atas."
        />
      </Card>

      {/* 7. Keamanan & Navigasi */}
      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">{t('settings.securityTitle', 'Keamanan & Navigasi')}</h3>
        <Toggle
          checked={form.randomize_questions}
          onChange={(v) => patch({ randomize_questions: v })}
          label={t('settings.randomizeQuestions', 'Acak urutan soal per siswa')}
        />
        <Toggle
          checked={form.randomize_options}
          onChange={(v) => patch({ randomize_options: v })}
          label={t('settings.randomizeOptions', 'Acak urutan opsi jawaban per siswa')}
        />
        <Toggle
          checked={form.allow_backtrack}
          onChange={(v) => patch({ allow_backtrack: v })}
          label={t('settings.allowBacktrack', 'Izinkan siswa kembali ke soal sebelumnya')}
        />
        <Toggle
          checked={form.show_question_number}
          onChange={(v) => patch({ show_question_number: v })}
          label={t('settings.showQuestionNumber', 'Tampilkan nomor soal ke siswa')}
        />
        <div className="pt-2 border-t border-border">
          <Toggle
            checked={form.fullscreen_mode}
            onChange={(v) => patch({ fullscreen_mode: v })}
            label="Aktifkan Fitur Anti-Cheat Layar Penuh (Fullscreen Mode)"
          />
          <p className="mt-1 text-xs text-text-secondary pl-7">
            Wajibkan siswa mengerjakan ujian dalam mode layar penuh (fullscreen). Sistem akan memberikan peringatan 3 kali (Strike 1, 2, dan 3 Kunci Total) jika siswa keluar dari fullscreen, berpindah tab, atau membuka aplikasi lain.
          </p>
        </div>
      </Card>

      {/* 8. Banner Form */}
      <Card className="flex flex-col gap-4">
        <h3 className="font-semibold text-text">{t('settings.bannerTitle', 'Banner Form')}</h3>
        <p className="text-sm text-text-secondary">
          {t('settings.bannerDesc', 'Gambar ini tampil di kartu form pada halaman Form Saya, supaya form kamu mudah dikenali.')}
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

      <div className="flex flex-wrap items-center gap-3 pt-2">
        <Button onClick={() => handleSave(false)} loading={saving} className="self-start gap-1.5">
          <Save size={16} />
          {t('settings.saveSettings', 'Simpan Pengaturan')}
        </Button>

        {saving ? (
          <span className="flex items-center gap-1.5 text-xs text-text-secondary">
            <span className="h-2 w-2 rounded-full bg-primary animate-pulse" />
            Menyimpan otomatis...
          </span>
        ) : isDirty ? (
          <span className="flex items-center gap-1.5 text-xs text-amber-500 font-medium">
            <span className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
            Ada perubahan yang akan tersimpan otomatis...
          </span>
        ) : (
          <span className="flex items-center gap-1.5 text-xs text-emerald-600 font-medium">
            <Check size={14} className="text-emerald-600" />
            Semua perubahan tersimpan otomatis
          </span>
        )}
      </div>
    </div>
  );
}
