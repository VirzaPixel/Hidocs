import { Plus, Trash2, GripVertical, Paperclip } from 'lucide-react';
import { Checkbox } from './ui';
import MediaUploadField from './MediaUploadField';
import CodeMirrorEditor from './CodeMirrorEditor';
import MathLiveEditor from './MathLiveEditor';

// options: [{ id?, option_text, is_correct, order_index, img_url?, audio_url?, video_url? }]
// singleCorrect: true untuk MULTIPLE_CHOICE/DROPDOWN/YES_NO (radio),
// false untuk CHECKBOXES (bisa lebih dari satu jawaban benar).
export default function OptionsEditor({ options, onChange, singleCorrect = true, minOptions = 2, contentMode = 'text', codeLanguage = 'javascript' }) {
  const update = (index, patch) => {
    const next = options.map((o, i) => (i === index ? { ...o, ...patch } : o));
    onChange(next);
  };

  const setCorrect = (index) => {
    if (singleCorrect) {
      onChange(options.map((o, i) => ({ ...o, is_correct: i === index })));
    } else {
      update(index, { is_correct: !options[index].is_correct });
    }
  };

  const addOption = () => {
    onChange([
      ...options,
      { option_text: '', is_correct: false, order_index: options.length + 1 },
    ]);
  };

  const removeOption = (index) => {
    if (options.length <= minOptions) return;
    onChange(options.filter((_, i) => i !== index).map((o, i) => ({ ...o, order_index: i + 1 })));
  };

  return (
    <div className="flex flex-col gap-2">
      <span className="text-sm font-medium text-text">
        Pilihan Jawaban {singleCorrect ? '(pilih satu yang benar)' : '(bisa lebih dari satu benar)'}
      </span>
      {options.map((opt, i) => {
        const hasMedia = opt.img_url || opt.audio_url || opt.video_url;
        return (
          <div key={i} className="rounded-lg border border-border p-2">
            <div className="flex items-center gap-2">
              <GripVertical size={16} className="shrink-0 text-text-secondary" />
              {singleCorrect ? (
                <input
                  type="radio"
                  checked={!!opt.is_correct}
                  onChange={() => setCorrect(i)}
                  className="h-4 w-4 shrink-0 text-primary focus:ring-primary/40"
                  title="Tandai sebagai jawaban benar"
                />
              ) : (
                <Checkbox checked={!!opt.is_correct} onChange={() => setCorrect(i)} />
              )}
              <div className="min-w-0 flex-1">
                {contentMode === 'math' ? (
                  <MathLiveEditor
                    value={opt.option_text}
                    onChange={(v) => update(i, { option_text: v })}
                    placeholder={`Rumus opsi ${i + 1}`}
                  />
                ) : contentMode === 'code' ? (
                  <div className="flex flex-col gap-1.5">
                    <div className="flex gap-1.5">
                      <button
                        type="button"
                        onClick={() => update(i, { option_kind: 'text' })}
                        className={(opt.option_kind === 'code' ? 'border border-border text-text-secondary hover:border-primary' : 'bg-primary text-white') + ' rounded-md px-2 py-1 text-xs font-medium'}
                      >
                        Teks
                      </button>
                      <button
                        type="button"
                        onClick={() => update(i, { option_kind: 'code' })}
                        className={(opt.option_kind === 'code' ? 'bg-primary text-white' : 'border border-border text-text-secondary hover:border-primary') + ' rounded-md px-2 py-1 text-xs font-medium'}
                      >
                        Kode
                      </button>
                    </div>
                    {opt.option_kind === 'code' ? (
                      <CodeMirrorEditor
                        value={opt.option_text}
                        language={codeLanguage}
                        onChange={(v) => update(i, { option_text: v })}
                        onLanguageChange={() => {}}
                      />
                    ) : (
                      <input
                        value={opt.option_text}
                        onChange={(e) => update(i, { option_text: e.target.value })}
                        placeholder={`Opsi ${i + 1}`}
                        className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-secondary focus:border-primary focus:outline-none"
                      />
                    )}
                  </div>
                ) : (
                  <input
                    value={opt.option_text}
                    onChange={(e) => update(i, { option_text: e.target.value })}
                    placeholder={`Opsi ${i + 1}`}
                    className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-secondary focus:border-primary focus:outline-none"
                  />
                )}
              </div>
              <button
                type="button"
                onClick={() => removeOption(i)}
                disabled={options.length <= minOptions}
                className="shrink-0 text-text-secondary hover:text-danger disabled:opacity-30"
              >
                <Trash2 size={16} />
              </button>
            </div>
            <details className="mt-1 shrink-0">
              <summary className={'flex cursor-pointer list-none items-center gap-1 text-xs ' + (hasMedia ? 'text-primary' : 'text-text-secondary')} title="Lampirkan media ke opsi ini">
                <Paperclip size={14} /> Media opsi
              </summary>
              <div className="mt-2 grid grid-cols-1 gap-2 border-t border-border pt-2 sm:grid-cols-3">
                <MediaUploadField mediaType="IMAGE" label="Gambar" value={opt.img_url} onChange={(v) => update(i, { img_url: v })} />
                <MediaUploadField mediaType="AUDIO" label="Audio" value={opt.audio_url} onChange={(v) => update(i, { audio_url: v })} />
                <MediaUploadField mediaType="VIDEO" label="Video" value={opt.video_url} onChange={(v) => update(i, { video_url: v })} />
              </div>
            </details>
          </div>
        );
      })}
      <button
        type="button"
        onClick={addOption}
        className="mt-1 flex items-center gap-1.5 self-start text-sm font-medium text-primary hover:underline"
      >
        <Plus size={14} />
        Tambah Opsi
      </button>
    </div>
  );
}
