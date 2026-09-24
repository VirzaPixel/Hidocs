import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Sparkles, Plus, Trash2, Loader2, Paperclip, X, CheckCircle2, Clock } from 'lucide-react';
import { useQueryClient } from '@tanstack/react-query';
import { Modal } from '../../shared/Modal';
import { Button, Input, Textarea, Select } from '../../shared/ui';
import { aiApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';
import { QUESTION_TYPES } from '../../lib/utils';

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
  
  // Generation & Progress States
  const [loadingSave, setLoadingSave] = useState(false);
  const [progress, setProgress] = useState(0);
  const [stageMessage, setStageMessage] = useState('');
  const [elapsedSeconds, setElapsedSeconds] = useState(0);

  const toast = useToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const totalQuestionCount = specs.reduce((acc, s) => acc + (Number(s.count) || 0), 0);

  useEffect(() => {
    let timer;
    let interval;
    if (loadingSave) {
      setProgress(5);
      setStageMessage('Menganalisis instruksi, topik, dan materi...');
      setElapsedSeconds(0);

      const startTime = Date.now();
      interval = setInterval(() => {
        const seconds = Math.floor((Date.now() - startTime) / 1000);
        setElapsedSeconds(seconds);

        if (seconds < 4) {
          setProgress(15 + Math.min(10, seconds * 2));
          setStageMessage('Menganalisis instruksi, topik, dan materi...');
        } else if (seconds < 12) {
          setProgress(25 + Math.min(30, (seconds - 4) * 3.5));
          setStageMessage('Merumuskan kisi-kisi soal, rumus LaTeX & kode program...');
        } else if (seconds < 25) {
          setProgress(55 + Math.min(30, (seconds - 12) * 2.3));
          setStageMessage('Menyusun opsi pilihan jawaban, distractor & kunci...');
        } else {
          setProgress((prev) => Math.min(95, prev + 0.5));
          setStageMessage('Memvalidasi JSON & menyimpan form ke database...');
        }
      }, 500);
    } else {
      setProgress(0);
      setStageMessage('');
      setElapsedSeconds(0);
    }
    return () => {
      clearInterval(interval);
      clearTimeout(timer);
    };
  }, [loadingSave]);

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
      setProgress(100);
      setStageMessage('Form berhasil dibuat!');
      toast.success('Form berhasil dibuat dari AI!');
      await queryClient.invalidateQueries({ queryKey: formsQueryKey });
      setTimeout(() => {
        onClose();
        resetState();
        if (res.form_id) navigate(`/forms/${res.form_id}`);
      }, 400);
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
    setLoadingSave(false);
  };

  return (
    <Modal
      open={open}
      onClose={() => {
        if (loadingSave) return;
        onClose();
        resetState();
      }}
      title="Buat Soal dengan AI (Generator)"
      size="lg"
    >
      <div className="flex flex-col gap-4">
        {loadingSave ? (
          /* Live Progress Feedback Card */
          <div className="flex flex-col items-center justify-center gap-4 rounded-xl border border-primary/30 bg-primary/5 p-8 text-center my-4">
            <div className="relative flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-primary">
              <Sparkles size={32} className="animate-pulse text-primary" />
            </div>

            <div className="w-full max-w-md">
              <h3 className="text-lg font-bold text-text mb-1">
                Generasi Form AI Sedang Berlangsung...
              </h3>
              <p className="text-xs text-text-secondary">
                Memproses {totalQuestionCount > 0 ? `${totalQuestionCount} soal` : 'soal'} dengan kecerdasan Gemini AI Master Generator
              </p>

              {/* Progress Bar Container */}
              <div className="mt-5 w-full">
                <div className="flex items-center justify-between text-xs font-semibold mb-1.5">
                  <span className="text-primary flex items-center gap-1">
                    <Loader2 size={13} className="animate-spin" />
                    {stageMessage}
                  </span>
                  <span className="text-text font-mono">{Math.round(progress)}%</span>
                </div>
                <div className="h-3 w-full rounded-full bg-border overflow-hidden p-0.5">
                  <div
                    className="h-full rounded-full bg-primary transition-all duration-300 ease-out"
                    style={{ width: `${progress}%` }}
                  />
                </div>
              </div>

              {/* Waktu Berjalan */}
              <div className="mt-4 flex items-center justify-center gap-1.5 text-xs text-text-secondary">
                <Clock size={14} />
                <span>Waktu berjalan: <strong className="text-text font-mono">{elapsedSeconds} detik</strong></span>
              </div>
            </div>
          </div>
        ) : (
          /* Standard Form Inputs */
          <>
            <p className="text-sm text-text-secondary">
              Isi parameter di bawah, lalu klik <strong>Generate & Simpan</strong>. AI akan langsung menyusun form berkualitas tinggi lengkap dengan kunci jawaban, rumus Math (LaTeX), atau koding program.
            </p>

            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <Input label="Mata Pelajaran" placeholder="Contoh: IPA / Informatika" value={subject} onChange={(e) => setSubject(e.target.value)} />
              <Input label="Topik / Bab" placeholder="Contoh: Pemrograman Python / Trigonometri" value={topic} onChange={(e) => setTopic(e.target.value)} />
              <Input label="Jenjang / Kelas" placeholder="Contoh: Kelas 10 SMA" value={gradeLevel} onChange={(e) => setGradeLevel(e.target.value)} />
              <Select label="Tingkat Kesulitan" value={difficulty} onChange={(e) => setDifficulty(e.target.value)}>
                <option value="Mudah">Mudah</option>
                <option value="Sedang">Sedang</option>
                <option value="Sulit">Sulit</option>
                <option value="HOTS">HOTS (Higher Order Thinking Skills)</option>
              </Select>
              <Input label="Kategori (opsional)" placeholder="Contoh: Ujian Tengah Semester" value={category} onChange={(e) => setCategory(e.target.value)} />
              <Input label="Durasi Ujian (menit)" type="number" value={totalTime} onChange={(e) => setTotalTime(e.target.value)} />
            </div>

            <div className="flex flex-col gap-2">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-text">Komposisi & Jumlah Soal</span>
                <span className="text-xs font-semibold text-primary">
                  Total: {totalQuestionCount} Soal (Dukungan s/d 50 soal)
                </span>
              </div>
              {specs.map((s, i) => (
                <div key={i} className="grid grid-cols-[1.5fr_0.8fr_0.8fr_0.8fr_auto] items-end gap-2">
                  <Select label={i === 0 ? 'Tipe Soal' : undefined} value={s.question_type} onChange={(e) => updateSpec(i, { question_type: e.target.value })}>
                    {QUESTION_TYPES.map((t) => (
                      <option key={t.value} value={t.value}>
                        {t.label}
                      </option>
                    ))}
                  </Select>
                  <Input label={i === 0 ? 'Jumlah' : undefined} type="number" min={1} max={50} value={s.count} onChange={(e) => updateSpec(i, { count: e.target.value })} />
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
                Unggah PDF/Word berisi bahan ajar — AI akan membuatkan soal akurat berdasarkan isi dokumen materi ini.
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
              placeholder="Contoh: Sertakan soal cerita HOTS, gunakan rumus LaTeX untuk ekspresi matematika, atau tambahkan snippet kode Python"
              value={rawPrompt}
              onChange={(e) => setRawPrompt(e.target.value)}
              rows={2}
            />

            <Button onClick={handleGenerate} disabled={loadingSave} className="w-full">
              <Sparkles size={16} />
              Generate & Simpan sebagai Form
            </Button>
          </>
        )}
      </div>
    </Modal>
  );
}

