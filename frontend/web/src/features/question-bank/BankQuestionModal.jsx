import { useState } from 'react';
import { Modal } from '../../shared/Modal';
import { Button, Input, Textarea, Select, Checkbox } from '../../shared/ui';
import OptionsEditor from '../../shared/OptionsEditor';
import MatchingEditor from '../../shared/MatchingEditor';
import MediaUploadField from '../../shared/MediaUploadField';
import { questionBankApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';
import { QUESTION_TYPES, DIFFICULTY_LEVELS, questionTypeMeta } from '../../lib/utils';

function defaultOptions(type) {
  if (type === 'MATCHING') {
    return [
      { option_text: '', match_target_text: '', match_key: `pair-1-${Date.now()}`, is_correct: true },
      { option_text: '', match_target_text: '', match_key: `pair-2-${Date.now()}`, is_correct: true },
    ];
  }
  return [
    { option_text: '', is_correct: true },
    { option_text: '', is_correct: false },
  ];
}

export default function BankQuestionModal({ open, onClose, initial, onSaved }) {
  const isEdit = !!initial;
  const [form, setForm] = useState(() => ({
    subject: initial?.subject || '',
    topic: initial?.topic || '',
    difficulty: initial?.difficulty || 'MEDIUM',
    question_text: initial?.question_text || '',
    question_type: initial?.question_type || 'MULTIPLE_CHOICE',
    points: initial?.points ?? 10,
    img_url: initial?.img_url || null,
    audio_url: initial?.audio_url || null,
    video_url: initial?.video_url || null,
    options: initial?.options?.length ? initial.options : defaultOptions(initial?.question_type || 'MULTIPLE_CHOICE'),
  }));
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  const meta = questionTypeMeta(form.question_type);
  const patch = (fields) => setForm((f) => ({ ...f, ...fields }));

  const handleTypeChange = (type) => {
    const newMeta = questionTypeMeta(type);
    patch({ question_type: type, options: newMeta.hasOptions ? defaultOptions(type) : [] });
  };

  const handleSave = async () => {
    if (!form.question_text.trim()) {
      toast.error('Teks soal wajib diisi');
      return;
    }
    setSaving(true);
    try {
      const payload = {
        subject: form.subject,
        topic: form.topic,
        difficulty: form.difficulty,
        question_text: form.question_text,
        question_type: form.question_type,
        img_url: form.img_url || '',
        audio_url: form.audio_url || null,
        video_url: form.video_url || null,
        points: Number(form.points) || 0,
        options: meta.hasOptions
          ? form.options.map((o) => ({
              option_text: o.option_text,
              is_correct: !!o.is_correct,
              img_url: o.img_url || null,
              audio_url: o.audio_url || null,
              video_url: o.video_url || null,
              match_key: form.question_type === 'MATCHING' ? o.match_key : null,
              match_target_text: form.question_type === 'MATCHING' ? o.match_target_text : null,
            }))
          : [],
      };
      if (isEdit) {
        await questionBankApi.update(initial.id, payload);
        toast.success('Soal diperbarui');
      } else {
        await questionBankApi.create(payload);
        toast.success('Soal ditambahkan ke bank');
      }
      onSaved();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={isEdit ? 'Edit Soal Bank' : 'Tambah Soal ke Bank'}
      size="lg"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Batal
          </Button>
          <Button onClick={handleSave} loading={saving}>
            Simpan
          </Button>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <Input label="Mata Pelajaran" value={form.subject} onChange={(e) => patch({ subject: e.target.value })} />
          <Input label="Topik" value={form.topic} onChange={(e) => patch({ topic: e.target.value })} />
          <Select label="Kesulitan" value={form.difficulty} onChange={(e) => patch({ difficulty: e.target.value })}>
            {DIFFICULTY_LEVELS.map((d) => (
              <option key={d.value} value={d.value}>
                {d.label}
              </option>
            ))}
          </Select>
        </div>

        <div className="grid grid-cols-1 gap-3 sm:grid-cols-[2fr_1fr]">
          <Select label="Tipe Soal" value={form.question_type} onChange={(e) => handleTypeChange(e.target.value)}>
            {QUESTION_TYPES.map((t) => (
              <option key={t.value} value={t.value}>
                {t.label}
              </option>
            ))}
          </Select>
          <Input label="Poin" type="number" min={0} value={form.points} onChange={(e) => patch({ points: e.target.value })} />
        </div>

        <Textarea
          label="Teks Soal"
          value={form.question_text}
          onChange={(e) => patch({ question_text: e.target.value })}
          rows={3}
        />

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

        <MediaUploadField mediaType="IMAGE" label="Gambar (opsional)" value={form.img_url} onChange={(v) => patch({ img_url: v })} />
      </div>
    </Modal>
  );
}
