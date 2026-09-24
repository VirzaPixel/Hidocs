import { useNavigate } from 'react-router-dom';
import { Sparkles, Loader2, CheckCircle2, AlertCircle, X, Maximize2, ArrowRight } from 'lucide-react';
import { useAIGenerationStore } from '../../store/aiGenerationStore';

export default function AIGenerateFloatingWidget() {
  const {
    modalOpen,
    isGenerating,
    progress,
    stageMessage,
    elapsedSeconds,
    result,
    error,
    openModal,
    dismiss,
  } = useAIGenerationStore();

  const navigate = useNavigate();

  // If full modal is open, or no activity, don't show floating card
  if (modalOpen || (!isGenerating && !result && !error)) {
    return null;
  }

  return (
    <div className="fixed bottom-5 right-5 z-50 flex w-80 sm:w-96 flex-col gap-2 rounded-2xl border border-primary/30 bg-surface/95 p-4 shadow-2xl backdrop-blur-md transition-all animate-in fade-in slide-in-from-bottom-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          {isGenerating ? (
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-primary/10 text-primary">
              <Sparkles size={18} className="animate-spin text-primary" />
            </div>
          ) : result ? (
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-500">
              <CheckCircle2 size={18} />
            </div>
          ) : (
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-danger/10 text-danger">
              <AlertCircle size={18} />
            </div>
          )}

          <div>
            <h4 className="text-xs font-bold text-text leading-tight">
              {isGenerating
                ? 'AIDoc Sedang Memproses...'
                : result
                ? 'AIDoc Selesai Memproses!'
                : 'AIDoc Mengalami Masalah'}
            </h4>
            <span className="text-[11px] text-text-secondary">
              {isGenerating
                ? `${elapsedSeconds}s • ${progress}% selesai`
                : result
                ? 'Form berhasil disimpan'
                : 'Gagal membuat form'}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-1">
          {isGenerating && (
            <button
              type="button"
              onClick={openModal}
              className="rounded-lg p-1.5 text-text-secondary hover:bg-bg-secondary hover:text-primary transition-colors"
              title="Buka Modal AIDoc Penuh"
            >
              <Maximize2 size={15} />
            </button>
          )}
          <button
            type="button"
            onClick={dismiss}
            className="rounded-lg p-1.5 text-text-secondary hover:bg-bg-secondary hover:text-danger transition-colors"
            title="Tutup Widget"
          >
            <X size={15} />
          </button>
        </div>
      </div>

      {/* Body for Loading */}
      {isGenerating && (
        <div className="mt-1 flex flex-col gap-1.5">
          <div className="flex items-center justify-between text-[11px]">
            <span className="truncate font-medium text-primary flex items-center gap-1">
              <Loader2 size={12} className="animate-spin shrink-0" />
              {stageMessage}
            </span>
            <span className="font-mono text-text font-bold ml-1">{progress}%</span>
          </div>

          <div className="h-2 w-full overflow-hidden rounded-full bg-border/80 p-0.5">
            <div
              className="h-full rounded-full bg-gradient-to-r from-primary to-indigo-500 transition-all duration-300 ease-out"
              style={{ width: `${progress}%` }}
            />
          </div>

          <button
            type="button"
            onClick={openModal}
            className="mt-1 flex items-center justify-center gap-1 text-[11px] font-semibold text-primary hover:underline self-end"
          >
            Buka Detail Progress AIDoc &rarr;
          </button>
        </div>
      )}

      {/* Body for Success */}
      {result && (
        <div className="mt-1 flex flex-col gap-2">
          <p className="text-xs text-text-secondary line-clamp-1">
            Judul: <strong className="text-text">{result.title || 'Form Ujian Baru'}</strong>
          </p>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => {
                const formId = result.form_id || result.id;
                dismiss();
                if (formId) navigate(`/forms/${formId}`);
              }}
              className="flex min-w-0 flex-1 items-center justify-center gap-1.5 rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-white shadow-sm hover:bg-primary/90 active:scale-95 transition-all"
            >
              <span>Lihat Form</span>
              <ArrowRight size={14} />
            </button>
            <button
              type="button"
              onClick={dismiss}
              className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-text hover:bg-bg-secondary"
            >
              Tutup
            </button>
          </div>
        </div>
      )}

      {/* Body for Error */}
      {error && (
        <div className="mt-1 flex flex-col gap-2">
          <p className="text-xs text-danger line-clamp-2">{error}</p>
          <button
            type="button"
            onClick={openModal}
            className="self-end rounded-lg bg-primary px-3 py-1 text-xs font-medium text-white hover:bg-primary/90"
          >
            Coba Lagi
          </button>
        </div>
      )}
    </div>
  );
}
