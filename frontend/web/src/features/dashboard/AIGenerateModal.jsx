import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Sparkles, Plus, Trash2, Loader2, Paperclip, X } from 'lucide-react';
import { Modal } from '../../shared/Modal';
import { Button, Input, Textarea, Select } from '../../shared/ui';
import { aiApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';
import { QUESTION_TYPES } from '../../lib/utils';

const emptySpec = () => ({ question_type: 'MULTIPLE_CHOICE', count: 5, points_each: 10, option_count: 4 });

export default function AIGenerateModal({ open, onClose }) {
  const [subject, setSubject] = useState('');
  const [topic, setTopic] = useState('');
  const [gradeLevel, setGradeLevel] = useState('');
  const [difficulty, setDifficulty] = useState('Sedang');
  const [totalTime, setTotalTime] = useState(60);
  const [category, setCategory] = useState('');
  const [specs, setSpecs] = useState([emptySpec()]);
  const [rawPrompt, setRawPrompt] = useState('');
  const [material, setMaterial] = useState(null); // { filename, text, truncated }
  const [extracting, setExtracting] = useState(false);

  const [preview, setPreview] = useState(null);
  const [loadingPreview, setLoadingPreview] = useState(false);
  const [loadingSave, setLoadingSave] = useState(false);

  const toast = useToast();
  const navigate = useNavigate();

  const buildPayload = (autoSave) => {
    const combinedPrompt = material
      ? `${rawPrompt ? rawPrompt + '\n\n' : ''}=== Materi dari file "${material.filename}" ===\n${material.text}`
      : rawPrompt;
    return {
      subject,
      topic,
      grade_level: gradeLevel,
      language: 'id',
      difficulty,
      total_time_minutes: Number(totalTime) || 0,
      specs: specs.map((s) => ({
        question_type: s.question_type,
        count: Number(s.count) || 1,
        points_each: Number(s.points_each) || 0,
        option_count: Number(s.option_count) || 0,
      })),
      attachments: [],
      raw_prompt: combinedPrompt,
      auto_save: autoSave,
      category,
    };
  };

  const updateSpec = (i, patch) => setSpecs((prev) => prev.map((s, idx) => (idx === i ? { ...s, ...patch } : s)));
  const addSpec = () => setSpecs((prev) => [...prev, emptySpec()]);
  const removeSpec = (i) => setSpecs((prev) => prev.filter((_, idx) => idx !== i));

  const handleMaterialUpload = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    setExtracting(true);
    try {
      const res = await aiApi.extractMaterial(file);
      setMaterial({ filename: res.filename || file.name, text: res.text, truncated: res.truncated });
      if (res.truncated) {
        toast.info('Materi terlalu panjang, cuma sebagian awal yang dipakai AI.');
      } else {
        toast.success('Materi berhasil dilampirkan');
      }
    } catch (err) {
      toast.error(err.message);
    } finally {
      setExtracting(false);
    }
  };

  const handlePreview = async () => {
    if (!subject.trim() && !rawPrompt.trim() && !material) {
      toast.error('Isi minimal mata pelajaran, instruksi bebas, atau lampirkan materi');
      return;
    }
    setLoadingPreview(true);
    try {
      const res = await aiApi.generatePreview(buildPayload(false));
      setPreview(res.preview);
      if (res.preview?.mock) {
        toast.info('AI berjalan dalam mode simulasi (GEMINI_API_KEY belum diisi di backend) — hasil ini contoh, bukan dari AI sungguhan.');
      }
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoadingPreview(false);
    }
  };

  const handleSaveAsForm = async () => {
    setLoadingSave(true);
    try {
      const res = await aiApi.generateForm(buildPayload(true));
      toast.success('Form berhasil dibuat dari AI. Periksa kembali soal & kunci jawabannya sebelum dipublikasikan.');
      onClose();
      resetState();
      if (res.form_id) navigate(`/forms/${res.form_id}`);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoadingSave(false);
    }
  };

  const resetState = () => {
    setPreview(null);
    setSubject('');
    setTopic('');
    setRawPrompt('');
    setSpecs([emptySpec()]);
    setMaterial(null);
  };

  return (
    <Modal
      open={open}
      onClose={() => {
        onClose();
        resetState();
      }}
      title="Buat Soal dengan AI"
      size="lg"
    >
      {!preview ? (
        <div className="flex flex-col gap-4">
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <Input label="Mata Pelajaran" placeholder="Contoh: IPA" value={subject} onChange={(e) => setSubject(e.target.value)} />
            <Input label="Topik / Bab" placeholder="Contoh: Sistem Pernapasan" value={topic} onChange={(e) => setTopic(e.target.value)} />
            <Input label="Jenjang / Kelas" placeholder="Contoh: Kelas 8 SMP" value={gradeLevel} onChange={(e) => setGradeLevel(e.target.value)} />
            <Select label="Tingkat Kesulitan" value={difficulty} onChange={(e) => setDifficulty(e.target.value)}>
              <option value="Mudah">Mudah</option>
              <option value="Sedang">Sedang</option>
              <option value="Sulit">Sulit</option>
            </Select>
            <Input label="Kategori (opsional)" placeholder="Contoh: IPA" value={category} onChange={(e) => setCategory(e.target.value)} />
            <Input label="Durasi Ujian (menit)" type="number" value={totalTime} onChange={(e) => setTotalTime(e.target.value)} />
          </div>

          <div className="flex flex-col gap-2">
            <span className="text-sm font-medium text-text">Komposisi Soal</span>
            {specs.map((s, i) => (
              <div key={i} className="grid grid-cols-[1.5fr_0.8fr_0.8fr_0.8fr_auto] items-end gap-2">
                <Select label={i === 0 ? 'Tipe' : undefined} value={s.question_type} onChange={(e) => updateSpec(i, { question_type: e.target.value })}>
                  {QUESTION_TYPES.map((t) => (
                    <option key={t.value} value={t.value}>
                      {t.label}
                    </option>
                  ))}
                </Select>
                <Input label={i === 0 ? 'Jumlah' : undefined} type="number" min={1} value={s.count} onChange={(e) => updateSpec(i, { count: e.target.value })} />
                <Input label={i === 0 ? 'Poin' : undefined} type="number" min={0} value={s.points_each} onChange={(e) => updateSpec(i, { points_each: e.target.value })} />
                <Input label={i === 0 ? 'Opsi' : undefined} type="number" min={0} value={s.option_count} onChange={(e) => updateSpec(i, { option_count: e.target.value })} />
                <button type="button" onClick={() => removeSpec(i)} disabled={specs.length <= 1} className="mb-2 text-text-secondary hover:text-danger disabled:opacity-30">
                  <Trash2 size={16} />
                </button>
              </div>
            ))}
            <button type="button" onClick={addSpec} className="flex items-center gap-1 self-start text-sm font-medium text-primary hover:underline">
              <Plus size={14} />
              Tambah Tipe Soal Lain
            </button>
          </div>

          <div className="flex flex-col gap-2 rounded-lg border border-border bg-bg-secondary p-3">
            <span className="text-sm font-medium text-text">Lampirkan Materi (opsional)</span>
            <p className="text-xs text-text-secondary">
              Unggah PDF/Word berisi bahan ajar — AI akan membuatkan soal berdasarkan isi materi ini
              (bukan cuma dari topik yang kamu ketik).
            </p>
            {material ? (
              <div className="flex items-center gap-2 rounded-lg border border-primary/30 bg-primary/5 px-3 py-2 text-sm">
                <Paperclip size={14} className="text-primary" />
                <span className="min-w-0 flex-1 truncate text-text">{material.filename}</span>
                <button onClick={() => setMaterial(null)} className="text-text-secondary hover:text-danger">
                  <X size={14} />
                </button>
              </div>
            ) : (
              <label className="flex cursor-pointer items-center justify-center gap-2 rounded-lg border border-dashed border-border py-2.5 text-sm text-text-secondary hover:border-primary hover:text-primary">
                {extracting ? <Loader2 size={16} className="animate-spin" /> : <Paperclip size={16} />}
                {extracting ? 'Mengekstrak teks...' : 'Pilih file PDF/Word'}
                <input type="file" accept=".pdf,.docx" className="hidden" onChange={handleMaterialUpload} disabled={extracting} />
              </label>
            )}
          </div>

          <Textarea
            label="Instruksi Tambahan / Prompt Bebas (opsional)"
            placeholder="Contoh: fokus ke soal HOTS, gunakan bahasa formal, sertakan 2 soal cerita"
            value={rawPrompt}
            onChange={(e) => setRawPrompt(e.target.value)}
            rows={2}
          />

          <Button onClick={handlePreview} loading={loadingPreview} className="w-full">
            <Sparkles size={16} />
            Lihat Preview Soal
          </Button>
        </div>
      ) : (
        <div className="flex flex-col gap-4">
          <div>
            <h4 className="font-semibold text-text">{preview.title}</h4>
            {preview.description && <p className="text-sm text-text-secondary">{preview.description}</p>}
          </div>
          <div className="flex max-h-80 flex-col gap-3 overflow-y-auto">
            {preview.questions?.map((q, i) => (
              <div key={i} className="rounded-lg border border-border p-3">
                <p className="text-sm font-medium text-text">
                  {i + 1}. {q.question_text}{' '}
                  <span className="text-xs font-normal text-text-secondary">({q.points} poin)</span>
                </p>
                {q.options?.length > 0 && (
                  <ul className="mt-1.5 space-y-1 pl-4 text-sm text-text-secondary">
                    {q.options.map((o, oi) => (
                      <li key={oi} className={o.is_correct ? 'font-medium text-success' : ''}>
                        {o.option_text} {o.is_correct && '✓'}
                      </li>
                    ))}
                  </ul>
                )}
                {q.answer_key_text && (
                  <p className="mt-1.5 text-xs text-text-secondary">Kunci: {q.answer_key_text}</p>
                )}
              </div>
            ))}
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={() => setPreview(null)} className="flex-1">
              Ubah Instruksi
            </Button>
            <Button onClick={handleSaveAsForm} loading={loadingSave} className="flex-1">
              {loadingSave ? <Loader2 size={16} className="animate-spin" /> : <Sparkles size={16} />}
              Simpan sebagai Form
            </Button>
          </div>
        </div>
      )}
    </Modal>
  );
}
