import { Plus, Trash2, GripVertical, Paperclip } from 'lucide-react';
import { Input, Checkbox } from './ui';
import MediaUploadField from './MediaUploadField';

// options: [{ id?, option_text, is_correct, order_index, img_url?, audio_url?, video_url? }]
// singleCorrect: true untuk MULTIPLE_CHOICE/DROPDOWN/YES_NO (radio),
// false untuk CHECKBOXES (bisa lebih dari satu jawaban benar).
export default function OptionsEditor({ options, onChange, singleCorrect = true, minOptions = 2 }) {
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
              <Input
                className="flex-1"
                placeholder={`Opsi ${i + 1}`}
                value={opt.option_text}
                onChange={(e) => update(i, { option_text: e.target.value })}
              />
              <details className="shrink-0">
                <summary
                  className={
                    'flex h-8 w-8 cursor-pointer list-none items-center justify-center rounded hover:bg-bg-secondary ' +
                    (hasMedia ? 'text-primary' : 'text-text-secondary')
                  }
                  title="Lampirkan media ke opsi ini"
                >
                  <Paperclip size={15} />
                </summary>
                <div className="mt-2 grid grid-cols-1 gap-2 border-t border-border pt-2 sm:grid-cols-3">
                  <MediaUploadField mediaType="IMAGE" label="Gambar" value={opt.img_url} onChange={(v) => update(i, { img_url: v })} />
                  <MediaUploadField mediaType="AUDIO" label="Audio" value={opt.audio_url} onChange={(v) => update(i, { audio_url: v })} />
                  <MediaUploadField mediaType="VIDEO" label="Video" value={opt.video_url} onChange={(v) => update(i, { video_url: v })} />
                </div>
              </details>
              <button
                type="button"
                onClick={() => removeOption(i)}
                disabled={options.length <= minOptions}
                className="shrink-0 text-text-secondary hover:text-danger disabled:opacity-30"
              >
                <Trash2 size={16} />
              </button>
            </div>
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
