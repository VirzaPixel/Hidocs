import { useState } from 'react';
import { Save, X, Trash2, Library, ChevronDown, ChevronUp } from 'lucide-react';
import { questionApi } from '../../lib/api';
import { Input, Textarea, Select, Checkbox, Toggle, Button, Badge } from '../../shared/ui';
import { ConfirmDialog } from '../../shared/Modal';
import OptionsEditor from '../../shared/OptionsEditor';
import MatchingEditor from '../../shared/MatchingEditor';
import MathField, { renderMixedText } from '../../shared/MathField';
import MediaUploadField from '../../shared/MediaUploadField';
import SaveToBankModal from './SaveToBankModal';
import { useToast } from '../../shared/Toast';
import { QUESTION_TYPES, questionTypeMeta, questionTypeLabel } from '../../lib/utils';

const CODE_LANGUAGES = ['javascript', 'python', 'java', 'c', 'cpp', 'go', 'sql', 'html'];

function defaultOptions(type) {
  if (type === 'MATCHING') {
    return [
      { option_text: '', match_target_text: '', match_key: `pair-1-${Date.now()}`, is_correct: true, order_index: 1 },
      { option_text: '', match_target_text: '', match_key: `pair-2-${Date.now()}`, is_correct: true, order_index: 2 },
    ];
  }
  return [
    { option_text: '', is_correct: true, order_index: 1 },
    { option_text: '', is_correct: false, order_index: 2 },
  ];
}

function initFromQuestion(question) {
  if (!question) {
    return {
      question_text: '',
      question_type: 'MULTIPLE_CHOICE',
      code_language: '',
      img_url: null,
      audio_url: null,
      video_url: null,
      points: 10,
      is_required: true,
      is_auto_scored: questionTypeMeta('MULTIPLE_CHOICE').autoScored,
      options: defaultOptions('MULTIPLE_CHOICE'),
    };
  }
  return {
    question_text: question.question_text || '',
    question_type: question.question_type,
    code_language: question.code_language || '',
    img_url: question.img_url || null,
    audio_url: question.audio_url || null,
    video_url: question.video_url || null,
    points: question.points ?? 10,
    is_required: question.is_required ?? true,
    is_auto_scored: question.is_auto_scored ?? questionTypeMeta(question.question_type).autoScored,
    options: (question.options || []).map((o, i) => ({
      option_text: o.option_text,
      match_target_text: o.match_target_text || '',
      match_key: o.match_key || `pair-${i + 1}`,
      is_correct: !!o.is_correct,
      order_index: o.order_index ?? i + 1,
      img_url: o.img_url,
      audio_url: o.audio_url,
      video_url: o.video_url,
    })),
  };
}

export default function QuestionEditor({ formId, question, index, defaultExpanded, onSaved, onCancelNew, onDeleted }) {
  const isNew = !question;
  const [expanded, setExpanded] = useState(defaultExpanded ?? isNew);
  const [form, setForm] = useState(() => initFromQuestion(question));
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [saveToBankOpen, setSaveToBankOpen] = useState(false);
  const toast = useToast();

  const meta = questionTypeMeta(form.question_type);

  const patch = (fields) => setForm((f) => ({ ...f, ...fields }));

  const handleTypeChange = (newType) => {
    const newMeta = questionTypeMeta(newType);
    const oldMeta = questionTypeMeta(form.question_type);
    // Kalau bentuk opsi berubah (mis. dari tipe biasa ke MATCHING atau sebaliknya,
    // atau dari "tidak punya opsi" ke "punya opsi"), reset ke default supaya
    // bentuk datanya tetap valid untuk tipe baru.
    const shapeChanged =
      newMeta.hasOptions !== oldMeta.hasOptions ||
      (newType === 'MATCHING') !== (form.question_type === 'MATCHING');
    patch({
      question_type: newType,
      is_auto_scored: newMeta.autoScored,
      options: newMeta.hasOptions ? (shapeChanged ? defaultOptions(newType) : form.options) : [],
    });
  };

  const validate = () => {
    if (!form.question_text.trim()) return 'Teks soal wajib diisi';
    if (meta.hasOptions) {
      const filled = form.options.filter((o) =>
        form.question_type === 'MATCHING' ? o.option_text.trim() && o.match_target_text.trim() : o.option_text.trim()
      );
      if (filled.length < 2) return 'Minimal 2 opsi/pasangan harus terisi';
      if (form.question_type !== 'MATCHING' && meta.autoScored) {
        const hasCorrect = form.options.some((o) => o.is_correct);
        if (!hasCorrect) return 'Tandai minimal satu jawaban yang benar';
      }
    }
    return null;
  };

  const handleSave = async () => {
    const error = validate();
    if (error) {
      toast.error(error);
      return;
    }
    setSaving(true);
    try {
      const payload = {
        question_text: form.question_text,
        question_type: form.question_type,
        code_language: form.question_type === 'CODE' ? form.code_language : '',
        img_url: form.img_url || '',
        audio_url: form.audio_url || null,
        video_url: form.video_url || null,
        is_auto_scored: form.is_auto_scored,
        points: Number(form.points) || 0,
        order_index: question?.order_index ?? index + 1,
        is_required: form.is_required,
        options: meta.hasOptions
          ? form.options.map((o, i) => ({
              option_text: o.option_text,
              img_url: o.img_url || null,
              audio_url: o.audio_url || null,
              video_url: o.video_url || null,
              match_key: form.question_type === 'MATCHING' ? o.match_key : null,
              match_target_text: form.question_type === 'MATCHING' ? o.match_target_text : null,
              is_correct: !!o.is_correct,
              order_index: i + 1,
            }))
          : [],
      };

      let saved;
      if (isNew) {
        saved = await questionApi.create(formId, payload);
        toast.success('Soal ditambahkan');
      } else {
        saved = await questionApi.update(question.id, payload);
        toast.success('Soal diperbarui');
      }
      onSaved(saved);
      setExpanded(false);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    setDeleting(true);
    try {
      await questionApi.remove(question.id);
      toast.success('Soal dihapus');
      onDeleted(question.id);
    } catch (err) {
      toast.error(err.message);
      setDeleting(false);
    }
  };

  if (!expanded) {
    return (
      <div className="flex items-center gap-3 rounded-lg border border-border bg-surface px-4 py-3">
        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-bg-secondary text-xs font-medium text-text-secondary">
          {index + 1}
        </span>
        <div className="min-w-0 flex-1">
          <p
            className="truncate text-sm text-text"
            dangerouslySetInnerHTML={{ __html: renderMixedText(form.question_text || '(Soal kosong)') }}
          />
        </div>
        <Badge>{questionTypeLabel(form.question_type)}</Badge>
        <span className="text-xs text-text-secondary">{form.points} poin</span>
        <button onClick={() => setExpanded(true)} className="text-text-secondary hover:text-primary">
          <ChevronDown size={18} />
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4 rounded-lg border border-primary/30 bg-surface p-4">
      <div className="flex items-center justify-between">
        <span className="text-sm font-semibold text-text">Soal {index + 1}</span>
        <button onClick={() => setExpanded(false)} className="text-text-secondary hover:text-text">
          <ChevronUp size={18} />
        </button>
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-[2fr_1fr]">
        <Select
          label="Tipe Soal"
          value={form.question_type}
          onChange={(e) => handleTypeChange(e.target.value)}
        >
          {QUESTION_TYPES.map((t) => (
            <option key={t.value} value={t.value}>
              {t.label}
            </option>
          ))}
        </Select>
        <Input
          label="Poin"
          type="number"
          min={0}
          value={form.points}
          onChange={(e) => patch({ points: e.target.value })}
        />
      </div>

      {form.question_type === 'MATH' ? (
        <MathField
          textareaId={`math-${question?.id || 'new'}-${index}`}
          value={form.question_text}
          onChange={(v) => patch({ question_text: v })}
        />
      ) : (
        <Textarea
          label="Teks Soal"
          placeholder="Tulis pertanyaan di sini..."
          value={form.question_text}
          onChange={(e) => patch({ question_text: e.target.value })}
          rows={3}
        />
      )}

      {form.question_type === 'CODE' && (
        <Select
          label="Bahasa Pemrograman"
          value={form.code_language}
          onChange={(e) => patch({ code_language: e.target.value })}
        >
          <option value="">Pilih bahasa</option>
          {CODE_LANGUAGES.map((l) => (
            <option key={l} value={l}>
              {l}
            </option>
          ))}
        </Select>
      )}

      {meta.hasOptions &&
        (form.question_type === 'MATCHING' ? (
          <MatchingEditor pairs={form.options} onChange={(options) => patch({ options })} />
        ) : (
          <OptionsEditor
            options={form.options}
            onChange={(options) => patch({ options })}
            singleCorrect={form.question_type !== 'CHECKBOXES'}
          />
        ))}

      <details className="rounded-lg border border-border">
        <summary className="cursor-pointer px-3 py-2 text-sm font-medium text-text-secondary">
          Lampiran Media (opsional)
        </summary>
        <div className="grid grid-cols-1 gap-3 border-t border-border p-3 sm:grid-cols-3">
          <MediaUploadField mediaType="IMAGE" label="Gambar" value={form.img_url} onChange={(v) => patch({ img_url: v })} />
          <MediaUploadField mediaType="AUDIO" label="Audio" value={form.audio_url} onChange={(v) => patch({ audio_url: v })} />
          <MediaUploadField mediaType="VIDEO" label="Video" value={form.video_url} onChange={(v) => patch({ video_url: v })} />
        </div>
      </details>

      {['SHORT_TEXT', 'LONG_TEXT', 'CODE'].includes(form.question_type) && (
        <div className="rounded-lg border border-border bg-bg-secondary p-3">
          <Toggle
            checked={form.is_auto_scored}
            onChange={(v) => patch({ is_auto_scored: v })}
            label="Nilai otomatis dengan AI"
          />
          <p className="mt-1.5 pl-[52px] text-xs text-text-secondary">
            {form.is_auto_scored
              ? 'AI akan menilai jawaban siswa otomatis (bandingkan makna dengan kunci jawaban), guru tetap bisa timpa manual.'
              : 'Jawaban harus dinilai manual satu-satu oleh guru di halaman Monitoring.'}
          </p>
        </div>
      )}

      <Checkbox
        label="Wajib dijawab"
        checked={form.is_required}
        onChange={(e) => patch({ is_required: e.target.checked })}
      />

      <div className="flex flex-wrap items-center gap-2 border-t border-border pt-3">
        <Button onClick={handleSave} loading={saving} size="sm">
          <Save size={14} />
          Simpan Soal
        </Button>
        {isNew ? (
          <Button variant="outline" size="sm" onClick={onCancelNew}>
            <X size={14} />
            Batal
          </Button>
        ) : (
          <>
            <Button variant="outline" size="sm" onClick={() => setSaveToBankOpen(true)}>
              <Library size={14} />
              Simpan ke Bank Soal
            </Button>
            <Button variant="outline" size="sm" className="ml-auto text-danger" onClick={() => setConfirmDelete(true)}>
              <Trash2 size={14} />
              Hapus
            </Button>
          </>
        )}
      </div>

      <ConfirmDialog
        open={confirmDelete}
        onClose={() => setConfirmDelete(false)}
        onConfirm={handleDelete}
        loading={deleting}
        title="Hapus soal ini?"
        description="Soal yang sudah dihapus tidak bisa dikembalikan."
      />

      {!isNew && (
        <SaveToBankModal
          open={saveToBankOpen}
          onClose={() => setSaveToBankOpen(false)}
          questionId={question.id}
        />
      )}
    </div>
  );
}
