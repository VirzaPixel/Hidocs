import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Sparkles, Plus, Trash2, Loader2, Paperclip, X } from 'lucide-react';
import { useQueryClient } from '@tanstack/react-query';
import { Modal } from '../../shared/Modal';
import { Button, Input, Textarea, Select } from '../../shared/ui';
import { aiApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';
import { QUESTION_TYPES } from '../../lib/utils';
// formsQueryKey defined inline to avoid deleted form-builder file dependency
const formsQueryKey = ['forms'];

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
  const [material, setMaterial] = useState(null);
  const [extracting, setExtracting] = useState(false);
  const [loadingSave, setLoadingSave] = useState(false);

  const toast = useToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const buildPayload = () => {
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
      auto_save: true,
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

  const handleGenerate = async () => {
    if (loadingSave) return;
    if (!subject.trim() && !rawPrompt.trim() && !material) {
      toast.error('Isi minimal mata pelajaran, instruksi bebas, atau lampirkan materi');
      return;
    }
    setLoadingSave(true);
    try {
      const res = await aiApi.generateForm(buildPayload());
      toast.success('Form berhasil dibuat dari AI. Periksa kembali soal & kunci jawabannya sebelum dipublikasikan.');
      await queryClient.invalidateQueries({ queryKey: formsQueryKey });
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
      <div className="flex flex-col gap-4">
        <p className="text-sm text-text-secondary">
          Isi informasi di bawah, lalu klik <strong>Generate & Simpan</strong>. AI akan langsung membuat form berisi soal yang bisa kamu edit di builder.
        </p>

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

        <Button onClick={handleGenerate} disabled={loadingSave} className="w-full">
          {loadingSave ? <Loader2 size={16} className="animate-spin" /> : <Sparkles size={16} />}
          {loadingSave ? 'AI sedang membuat soal...' : 'Generate & Simpan sebagai Form'}
        </Button>
      </div>
    </Modal>
  );
}
