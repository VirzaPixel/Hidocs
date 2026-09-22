import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, ChevronLeft, ChevronRight, Flag } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Button, FullPageSpinner } from '../../shared/ui';
import { renderMixedText } from '../../shared/MathField';
import { cn, questionTypeLabel, resolveMediaUrl } from '../../lib/utils';

export default function StudentPreviewPage() {
  const { formId } = useParams();
  const navigate = useNavigate();
  const [index, setIndex] = useState(0);
  const [answers, setAnswers] = useState({});
  const [flagged, setFlagged] = useState({});

  const { data: form, isLoading } = useQuery({
    queryKey: ['form', formId],
    queryFn: () => formApi.getById(formId),
  });

  const accent = form?.form_settings?.theme_color || '#4F46E5';
  const questions = form?.questions || [];
  const current = questions[index];

  const setAnswer = (value) => setAnswers((a) => ({ ...a, [current.id]: value }));
  const toggleFlag = () => setFlagged((f) => ({ ...f, [current.id]: !f[current.id] }));

  if (isLoading) return <FullPageSpinner />;
  if (!form) return null;

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center gap-3">
        <button onClick={() => navigate(`/forms/${formId}`)} className="text-text-secondary hover:text-text">
          <ArrowLeft size={20} />
        </button>
        <div>
          <h1 className="text-lg font-bold text-text">Preview Simulasi Siswa</h1>
          <p className="text-sm text-text-secondary">Tampilan ini yang akan dilihat siswa di aplikasi mobile — kunci jawaban disembunyikan.</p>
        </div>
      </div>

      <div className="flex justify-center">
        <div
          className="preview-frame w-full max-w-sm overflow-hidden rounded-[2rem] border-8 border-neutral-800 bg-white shadow-2xl"
          style={{ '--preview-accent': accent }}
        >
          <div className="flex h-[640px] flex-col" style={{ backgroundColor: '#fff', color: '#111827' }}>
            {/* Header ala mobile app */}
            <div className="flex items-center justify-between px-4 py-3 text-white" style={{ backgroundColor: accent }}>
              <span className="text-sm font-semibold truncate">{form.title}</span>
              <span className="text-xs opacity-90">
                {index + 1}/{questions.length || 0}
              </span>
            </div>

            {questions.length === 0 ? (
              <div className="flex flex-1 items-center justify-center p-6 text-center text-sm text-gray-500">
                Form ini belum punya soal.
              </div>
            ) : (
              <>
                <div className="flex-1 overflow-y-auto p-4">
                  <div className="mb-3 flex items-center justify-between">
                    <span className="text-xs font-medium text-gray-500">
                      {questionTypeLabel(current.question_type)} &middot; {current.points} poin
                    </span>
                    <button onClick={toggleFlag} className={cn('flex items-center gap-1 text-xs', flagged[current.id] ? 'text-amber-500' : 'text-gray-400')}>
                      <Flag size={14} fill={flagged[current.id] ? 'currentColor' : 'none'} />
                      Ragu-ragu
                    </button>
                  </div>

                  <p
                    className="mb-3 text-sm font-medium text-gray-900"
                    dangerouslySetInnerHTML={{ __html: renderMixedText(current.question_text) }}
                  />

                  {current.img_url && (
                    <img src={resolveMediaUrl(current.img_url)} alt="" className="mb-3 max-h-48 w-full rounded-lg object-contain" />
                  )}
                  {current.audio_url && <audio src={resolveMediaUrl(current.audio_url)} controls className="mb-3 w-full" />}
                  {current.video_url && <video src={resolveMediaUrl(current.video_url)} controls className="mb-3 max-h-48 w-full rounded-lg" />}

                  <QuestionAnswerArea
                    question={current}
                    value={answers[current.id]}
                    onChange={setAnswer}
                    accent={accent}
                  />
                </div>

                {/* Navigasi nomor soal */}
                <div className="flex gap-1.5 overflow-x-auto border-t border-gray-100 px-3 py-2">
                  {questions.map((q, i) => (
                    <button
                      key={q.id}
                      onClick={() => setIndex(i)}
                      className={cn(
                        'flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-medium',
                        i === index ? 'text-white' : flagged[q.id] ? 'bg-amber-100 text-amber-700' : answers[q.id] !== undefined ? 'bg-gray-200 text-gray-700' : 'bg-gray-100 text-gray-400'
                      )}
                      style={i === index ? { backgroundColor: accent } : undefined}
                    >
                      {i + 1}
                    </button>
                  ))}
                </div>

                <div className="flex justify-between gap-2 border-t border-gray-100 px-4 py-3">
                  <Button variant="outline" size="sm" disabled={index === 0} onClick={() => setIndex((i) => i - 1)}>
                    <ChevronLeft size={14} />
                    Sebelumnya
                  </Button>
                  <Button
                    size="sm"
                    disabled={index === questions.length - 1}
                    onClick={() => setIndex((i) => i + 1)}
                    style={{ backgroundColor: accent }}
                    className="text-white"
                  >
                    Berikutnya
                    <ChevronRight size={14} />
                  </Button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function QuestionAnswerArea({ question, value, onChange, accent }) {
  const type = question.question_type;

  if (type === 'SHORT_TEXT') {
    return (
      <input
        className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
        placeholder="Ketik jawabanmu..."
        value={value || ''}
        onChange={(e) => onChange(e.target.value)}
      />
    );
  }
  if (type === 'LONG_TEXT' || type === 'CODE') {
    return (
      <textarea
        className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
        rows={5}
        placeholder="Ketik jawabanmu..."
        value={value || ''}
        onChange={(e) => onChange(e.target.value)}
      />
    );
  }
  if (type === 'MATCHING') {
    return (
      <div className="flex flex-col gap-2 text-sm">
        {question.options?.map((o) => (
          <div key={o.id} className="flex items-center justify-between gap-2 rounded-lg border border-gray-200 p-2">
            <span>{o.option_text}</span>
            <span className="text-gray-400">&harr;</span>
            <span className="text-gray-500">{o.match_target_text}</span>
          </div>
        ))}
        <p className="text-xs text-gray-400">(di aplikasi siswa, pasangan ini akan diacak dan siswa menjodohkan sendiri)</p>
      </div>
    );
  }
  if (type === 'RATING') {
    return (
      <div className="flex gap-2">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            onClick={() => onChange(n)}
            className="flex h-9 w-9 items-center justify-center rounded-full border text-sm"
            style={value === n ? { backgroundColor: accent, color: '#fff', borderColor: accent } : { borderColor: '#d1d5db' }}
          >
            {n}
          </button>
        ))}
      </div>
    );
  }
  if (type === 'CHECKBOXES') {
    const selected = Array.isArray(value) ? value : [];
    return (
      <div className="flex flex-col gap-2">
        {question.options?.map((o) => (
          <label key={o.id} className="flex items-center gap-2 rounded-lg border border-gray-200 p-2.5 text-sm">
            <input
              type="checkbox"
              checked={selected.includes(o.id)}
              onChange={() =>
                onChange(selected.includes(o.id) ? selected.filter((id) => id !== o.id) : [...selected, o.id])
              }
            />
            {o.option_text}
          </label>
        ))}
      </div>
    );
  }
  // MULTIPLE_CHOICE, DROPDOWN, YES_NO, MATH (opsi opsional), IMAGE, default
  if (question.options?.length) {
    return (
      <div className="flex flex-col gap-2">
        {question.options.map((o) => (
          <label key={o.id} className="flex items-center gap-2 rounded-lg border border-gray-200 p-2.5 text-sm">
            <input type="radio" name={question.id} checked={value === o.id} onChange={() => onChange(o.id)} />
            {o.option_text}
          </label>
        ))}
      </div>
    );
  }
  return (
    <input
      className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
      placeholder="Ketik jawabanmu..."
      value={value || ''}
      onChange={(e) => onChange(e.target.value)}
    />
  );
}
