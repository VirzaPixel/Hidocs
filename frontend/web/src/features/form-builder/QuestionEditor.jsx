import { useState } from 'react';
import { Save, X, Trash2, Library, ChevronDown, ChevronUp } from 'lucide-react';
import { questionApi } from '../../lib/api';
import { Input, Textarea, Select, Checkbox, Toggle, Button, Badge } from '../../shared/ui';
import { ConfirmDialog } from '../../shared/Modal';
import OptionsEditor from '../../shared/OptionsEditor';
import MatchingEditor from '../../shared/MatchingEditor';
import { renderMixedText } from '../../shared/MathField';
import MediaUploadField from '../../shared/MediaUploadField';
import SaveToBankModal from './SaveToBankModal';
import MathLiveEditor from '../../shared/MathLiveEditor';
import CodeMirrorEditor from '../../shared/CodeMirrorEditor';
import { useToast } from '../../shared/Toast';
import { QUESTION_TYPES, questionTypeMeta, questionTypeLabel } from '../../lib/utils';

const CONTENT_MODES = [
  { key: 'text', label: 'Teks Biasa' },
  { key: 'math', label: 'Matematika' },
  { key: 'code', label: 'Kode Program' },
];



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

const FENCE_BLOCK = /^```[a-zA-Z0-9+#-]*\n([\s\S]*?)\n```(?:\n([\s\S]*))?$/;

function splitCodeBlock(raw) {
  const text = (raw || '').trim();
  const match = text.match(FENCE_BLOCK);
  if (match) {
    return { snippet: (match[1] || '').trim(), prompt: (match[2] || '').trim() };
  }
  return { snippet: text, prompt: '' };
}

function initFromQuestion(question) {
  if (!question) {
    return {
      question_text: '',
      code_snippet: '',
      code_language: 'javascript',
      content_mode: 'text',
      img_url: null,
      audio_url: null,
      video_url: null,
      points: 10,
      is_required: true,
      is_auto_scored: questionTypeMeta('MULTIPLE_CHOICE').autoScored,
      options: defaultOptions('MULTIPLE_CHOICE'),
    };
  }
  const isCode = Boolean(question.code_language);
  const split = isCode ? splitCodeBlock(question.question_text) : { snippet: '', prompt: '' };
  return {
    question_text: isCode ? split.prompt : (question.question_text || ''),
    code_snippet: isCode ? split.snippet : '',
    code_language: question.code_language || 'javascript',
    content_mode: isCode ? 'code' : 'text',
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
    if (form.content_mode === 'code') {
      if (!form.code_snippet.trim()) return 'Kode soal wajib diisi';
      if (!form.question_text.trim()) return 'Kalimat pertanyaan wajib diisi';
    } else if (!form.question_text.trim()) {
      return 'Teks soal wajib diisi';
    }
    if (meta.hasOptions) {
      const filled = form.options.filter((o) => (o.option_text || '').trim());
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
      const questionText =
        form.content_mode === 'code'
          ? `\`\`\`${form.code_language || 'text'}\n${form.code_snippet.trim()}\n\`\`\`\n${form.question_text.trim()}`
          : form.question_text;
      const codeLanguage = form.content_mode === 'code' ? form.code_language : '';
      const payload = {
        question_text: questionText,
        question_type: form.question_type,
        code_language: codeLanguage,
        img_url: form.img_url || '',
        audio_url: form.audio_url || null,
        video_url: form.video_url || null,
        is_auto_scored: form.is_auto_scored,
        points: Number(form.points) || 0,
        order_index: question?.order_index ?? index + 1,
        is_required: form.is_required,
        options: meta.hasOptions
          ? form.options.filter((o) => (o.option_text || '').trim()).map((o, i) => ({
              option_text: (o.option_text || '').trim(),
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
      <button
        type="button"
        className="flex w-full cursor-pointer items-center gap-3 rounded-lg border border-border bg-surface px-4 py-3 text-left hover:border-primary/50"
        onClick={() => setExpanded(true)}
      >
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
        <ChevronDown size={18} className="text-text-secondary" />
      </button>
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

      <details className="rounded-lg border border-border">
        <summary className="cursor-pointer px-3 py-2 text-sm font-medium text-text-secondary">
          Lampiran Media untuk soal (Opsional)
        </summary>
        <div className="grid grid-cols-1 gap-3 border-t border-border p-3 sm:grid-cols-3">
          <MediaUploadField mediaType="IMAGE" label="Gambar" value={form.img_url} onChange={(v) => patch({ img_url: v })} />
          <MediaUploadField mediaType="AUDIO" label="Audio" value={form.audio_url} onChange={(v) => patch({ audio_url: v })} />
          <MediaUploadField mediaType="VIDEO" label="Video" value={form.video_url} onChange={(v) => patch({ video_url: v })} />
        </div>
      </details>

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

      <div className="flex gap-2">
        {CONTENT_MODES.map((mode) => (
          <button
            key={mode.key}
            type="button"
            onClick={() => patch({ content_mode: mode.key })}
            className={
              form.content_mode === mode.key
                ? 'rounded-lg bg-primary px-3 py-1.5 text-sm font-medium text-white'
                : 'rounded-lg border border-border px-3 py-1.5 text-sm text-text-secondary hover:border-primary'
            }
          >
            {mode.label}
          </button>
        ))}
      </div>

      {form.content_mode === 'math' ? (
        <MathLiveEditor value={form.question_text} onChange={(v) => patch({ question_text: v })} />
      ) : form.content_mode === 'code' ? (
        <div className="flex flex-col gap-2">
          <CodeMirrorEditor
            value={form.code_snippet}
            language={form.code_language}
            onChange={(v) => patch({ code_snippet: v })}
            onLanguageChange={(v) => patch({ code_language: v })}
          />
          <Textarea
            label="Kalimat Pertanyaan"
            value={form.question_text}
            onChange={(e) => patch({ question_text: e.target.value })}
            rows={3}
          />
        </div>
      ) : (
        <Textarea
          label="Teks Soal"
          value={form.question_text}
          onChange={(e) => patch({ question_text: e.target.value })}
          rows={4}
        />
      )}

      {meta.hasOptions &&
        (form.question_type === 'MATCHING' ? (
          <MatchingEditor pairs={form.options} onChange={(options) => patch({ options })} />
        ) : (
          <OptionsEditor
            options={form.options}
            onChange={(options) => patch({ options })}
            singleCorrect={form.question_type !== 'CHECKBOXES'}
            contentMode={form.content_mode}
            codeLanguage={form.code_language}
          />
        ))}

      {form.question_type === 'LONG_TEXT' && (
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
