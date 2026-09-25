import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Sparkles, Loader2, Paperclip, X, Clock, ArrowRight, CheckCircle2, FileText, ChevronDown, ChevronUp, Send } from 'lucide-react';
import { useQueryClient } from '@tanstack/react-query';
import { Modal } from '../../shared/Modal';
import { Button, Input, Select } from '../../shared/ui';
import { aiApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';
import { useAIGenerationStore } from '../../store/aiGenerationStore';

const PROMPT_TEMPLATES = [
  {
    icon: '🎓',
    title: 'Ujian Semester HOTS (IPA/IPS)',
    prompt: 'AIDoc, buatkan 10 soal Ujian Tengah Semester IPA Kelas 8 SMP materi Sistem Pernapasan Manusia. Tipe soal: 5 PG (HOTS dengan 4 opsi A-D), 3 Essay (dengan pembahasan/kunci jawaban), 2 Menjodohkan. Durasi 60 menit.',
  },
  {
    icon: '📐',
    title: 'Matematika & Rumus LaTeX',
    prompt: 'AIDoc, buatkan 8 soal Matematika SMA Trigonometri dan Persamaan Kuadrat. Wajib gunakan rumus LaTeX yang rapi (seperti \\(\\frac{a}{b}\\) atau \\(x^2\\)). Tipe soal: 5 PG, 3 Math Essay.',
  },
  {
    icon: '💻',
    title: 'Informatika & Pemrograman',
    prompt: 'AIDoc, buatkan 5 soal Informatika Dasar Pemrograman Python (tipe CODE) untuk kelas 10 SMA. Sertakan snippet kode program yang rapi, pertanyaan analisis output, dan kunci jawaban.',
  },
  {
    icon: '📄',
    title: 'Soal Berdasarkan Dokumen Materi',
    prompt: 'AIDoc, buatkan 10 soal kuis yang akurat berdasarkan dokumen materi yang saya lampirkan di bawah ini. Sertakan 7 PG dan 3 Essay beserta kunci jawabannya.',
  },
];

export default function AIGenerateModal({ open: propsOpen, onClose: propsOnClose }) {
  const [promptText, setPromptText] = useState('');
  const [material, setMaterial] = useState(null);
  const [extracting, setExtracting] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);

  // Advanced optional overrides
  const [category, setCategory] = useState('');
  const [difficulty, setDifficulty] = useState('Campuran');
  const [totalTime, setTotalTime] = useState(60);

  const {
    modalOpen,
    isGenerating,
    progress,
    stageMessage,
    elapsedSeconds,
    result,
    error,
    closeModal,
    startGeneration,
    dismiss,
  } = useAIGenerationStore();

  const toast = useToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const isOpen = propsOpen || modalOpen;

  const handleMaterialUpload = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    setExtracting(true);
    try {
      const res = await aiApi.extractMaterial(file);
      setMaterial({ filename: res.filename || file.name, text: res.text, truncated: res.truncated });
      if (res.truncated) {
        toast.info('Materi terlalu panjang, sebagian awal dokumen yang dipakai AIDoc.');
      } else {
        toast.success('Dokumen materi berhasil dilampirkan ke AIDoc');
      }
    } catch (err) {
      toast.error(err.message);
    } finally {
      setExtracting(false);
    }
  };

  const applyTemplate = (tplPrompt) => {
    setPromptText(tplPrompt);
  };

  const handleGenerate = async () => {
    if (isGenerating) return;
    if (!promptText.trim() && !material) {
      toast.error('Ketik instruksi prompt atau lampirkan materi untuk AIDoc');
      return;
    }

    const combinedPrompt = material
      ? `${promptText ? promptText + '\n\n' : ''}=== Dokumen Materi dari "${material.filename}" ===\n${material.text}`
      : promptText;

    const payload = {
      raw_prompt: combinedPrompt,
      difficulty,
      total_time_minutes: Number(totalTime) || 60,
      category,
      auto_save: true,
      specs: [],
    };

    await startGeneration(payload, 0, queryClient, navigate, toast);
  };

  const handleClose = () => {
    closeModal();
    if (propsOnClose) propsOnClose();
  };

  return (
    <Modal
      open={isOpen}
      onClose={handleClose}
      title={
        <div className="flex items-center gap-2">
          <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <Sparkles size={16} className="animate-pulse" />
          </div>
          <span className="font-bold text-text">AIDoc Generator</span>
          <span className="rounded bg-primary/10 px-2 py-0.5 text-[10px] font-semibold text-primary">
            Free-Form Chat AI
          </span>
        </div>
      }
      size="lg"
    >
      <div className="flex flex-col gap-4">
        {isGenerating ? (
          /* Live AIDoc Progress Screen */
          <div className="flex flex-col items-center justify-center gap-5 rounded-2xl border border-primary/30 bg-primary/5 p-8 text-center my-2 shadow-inner">
            <div className="relative flex h-20 w-20 items-center justify-center rounded-2xl bg-gradient-to-tr from-primary/20 via-primary/30 to-primary/10 text-primary shadow-md">
              <Sparkles size={40} className="animate-spin text-primary" />
            </div>

            <div className="w-full max-w-md">
              <h3 className="text-xl font-bold text-text mb-1">
                AIDoc Sedang Menyusun Form Anda...
              </h3>
              <p className="text-xs text-text-secondary">
                AIDoc sedang memproses kecerdasan AI untuk membuat pertanyaan, opsi, kunci jawaban, dan rumus secara presisi.
              </p>
              <p className="text-[11px] text-primary/90 mt-1 font-medium bg-primary/10 py-1 px-2 rounded-full inline-block">
                ✨ Anda dapat menutup modal ini — progress AIDoc akan tetap muncul di pojok kanan bawah
              </p>

              {/* Progress Bar */}
              <div className="mt-6 w-full">
                <div className="flex items-center justify-between text-xs font-semibold mb-2">
                  <span className="text-primary flex items-center gap-1.5 truncate max-w-[280px]">
                    <Loader2 size={14} className="animate-spin shrink-0" />
                    {stageMessage}
                  </span>
                  <span className="text-text font-mono text-sm font-bold">{progress}%</span>
                </div>
                <div className="h-3.5 w-full rounded-full bg-border overflow-hidden p-0.5 shadow-inner">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-primary to-indigo-500 transition-all duration-300 ease-out shadow-sm"
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

            <Button variant="secondary" size="sm" onClick={handleClose} className="mt-2">
              Lanjutkan di Background &rarr;
            </Button>
          </div>
        ) : result ? (
          /* AIDoc Success Screen */
          <div className="flex flex-col items-center justify-center gap-5 rounded-2xl border border-emerald-500/30 bg-emerald-500/5 p-8 text-center my-2 shadow-inner">
            <div className="flex h-20 w-20 items-center justify-center rounded-2xl bg-emerald-500/15 text-emerald-500 shadow-sm">
              <CheckCircle2 size={44} />
            </div>
            <div>
              <h3 className="text-xl font-bold text-text">AIDoc Berhasil Membuat Form!</h3>
              <p className="text-sm text-text-secondary mt-1">
                Judul Form: <strong className="text-text">{result.title}</strong>
              </p>
            </div>
            <div className="flex items-center gap-3 mt-2">
              <Button
                onClick={() => {
                  const formId = result.form_id || result.id;
                  dismiss();
                  if (formId) navigate(`/forms/${formId}`);
                }}
                className="px-6 shadow-md"
              >
                <span>Lihat Form</span>
                <ArrowRight size={16} />
              </Button>
              <Button variant="secondary" onClick={dismiss}>
                Tutup Modal
              </Button>
            </div>
          </div>
        ) : (
          /* Free-Form Chat Prompt Interface */
          <>
            {/* Prompt Template Inspirations */}
            <div className="flex flex-col gap-2">
              <span className="text-xs font-semibold text-text-secondary uppercase tracking-wider flex items-center gap-1">
                <Sparkles size={13} className="text-primary" /> Contoh Template Prompt Mantap (Klik untuk Pakai)
              </span>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {PROMPT_TEMPLATES.map((tpl, i) => (
                  <button
                    key={i}
                    type="button"
                    onClick={() => applyTemplate(tpl.prompt)}
                    className="flex items-start gap-2.5 rounded-xl border border-border bg-bg-secondary p-3 text-left transition-all hover:border-primary hover:bg-primary/5 active:scale-[0.98] group"
                  >
                    <span className="text-lg shrink-0 group-hover:scale-110 transition-transform">{tpl.icon}</span>
                    <div className="min-w-0 flex-1">
                      <h4 className="text-xs font-bold text-text group-hover:text-primary transition-colors">{tpl.title}</h4>
                      <p className="text-[11px] text-text-secondary line-clamp-2 mt-0.5">{tpl.prompt}</p>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Error Banner */}
            {error && (
              <div className="rounded-xl border border-danger/30 bg-danger/10 p-3 text-xs text-danger font-medium">
                {error}
              </div>
            )}

            {/* Free-Form Chat AI Text Input Box */}
            <div className="flex flex-col gap-2 rounded-2xl border border-border bg-surface p-4 shadow-sm focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/20 transition-all">
              <div className="flex items-center justify-between border-b border-border/60 pb-2">
                <span className="text-xs font-semibold text-text flex items-center gap-1.5">
                  <FileText size={14} className="text-primary" /> Instruksi Prompt Bebas ke AIDoc
                </span>
                <span className="text-[11px] text-text-secondary">
                  Bisa sebutkan topik, kelas, tipe soal, durasi, dll.
                </span>
              </div>

              <textarea
                value={promptText}
                onChange={(e) => setPromptText(e.target.value)}
                placeholder="Tulis instruksi pembuatan form ke AIDoc di sini...&#10;&#10;Contoh: AIDoc, buatkan 10 soal Ujian Tengah Semester IPA Kelas 8 tentang Sistem Pernapasan. Buat 5 PG, 3 Essay, dan 2 Menjodohkan..."
                rows={5}
                className="w-full resize-none bg-transparent font-sans text-sm text-text placeholder:text-text-secondary focus:outline-none leading-relaxed"
              />

              {/* Attachment Material Preview */}
              {material && (
                <div className="flex items-center gap-2 rounded-lg border border-primary/30 bg-primary/10 px-3 py-2 text-xs">
                  <Paperclip size={14} className="text-primary shrink-0" />
                  <span className="min-w-0 flex-1 truncate font-medium text-text">
                    Dokumen: {material.filename}
                  </span>
                  <button type="button" onClick={() => setMaterial(null)} className="text-text-secondary hover:text-danger">
                    <X size={14} />
                  </button>
                </div>
              )}

              {/* Bottom Actions inside Chat Box */}
              <div className="flex items-center justify-between border-t border-border/60 pt-3 mt-1">
                <label className="flex cursor-pointer items-center gap-1.5 rounded-lg border border-border bg-bg-secondary px-3 py-1.5 text-xs font-semibold text-text hover:border-primary hover:bg-primary/10 hover:text-primary transition-colors">
                  {extracting ? <Loader2 size={14} className="animate-spin text-primary" /> : <Paperclip size={14} />}
                  <span>{extracting ? 'Mengekstrak Dokumen...' : 'Lampirkan PDF / Word'}</span>
                  <input type="file" accept=".pdf,.docx" className="hidden" onChange={handleMaterialUpload} disabled={extracting} />
                </label>

                <button
                  type="button"
                  onClick={() => setShowAdvanced(!showAdvanced)}
                  className="flex items-center gap-1 text-xs text-text-secondary hover:text-primary transition-colors"
                >
                  <span>Pengaturan Tambahan</span>
                  {showAdvanced ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                </button>
              </div>
            </div>

            {/* Optional Collapsible Advanced Settings */}
            {showAdvanced && (
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-3 rounded-xl border border-border bg-bg-secondary p-3.5 animate-in fade-in">
                <Input
                  label="Kategori (opsional)"
                  placeholder="Contoh: UTS / Kuis Harian"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                />
                <Select
                  label="Tingkat Kesulitan"
                  value={difficulty}
                  onChange={(e) => setDifficulty(e.target.value)}
                >
                  <option value="Mudah">Mudah</option>
                  <option value="Sedang">Sedang</option>
                  <option value="Sulit">Sulit</option>
                  <option value="Campuran">Campuran</option>
                  <option value="HOTS">HOTS</option>
                </Select>
                <Input
                  label="Durasi Ujian (menit)"
                  type="number"
                  value={totalTime}
                  onChange={(e) => setTotalTime(e.target.value)}
                />
              </div>
            )}

            {/* Send Button */}
            <Button
              onClick={handleGenerate}
              disabled={isGenerating}
              className="w-full py-3 text-sm font-semibold shadow-md"
            >
              <Send size={16} />
              Kirim & Generate Form dengan AIDoc
            </Button>
          </>
        )}
      </div>
    </Modal>
  );
}
