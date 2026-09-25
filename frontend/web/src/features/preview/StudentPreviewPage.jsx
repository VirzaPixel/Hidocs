import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, ChevronLeft, ChevronRight, Flag, UserCheck, KeyRound, CheckCircle2, RotateCcw, ShieldCheck, AlertCircle } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Button, FullPageSpinner, Badge } from '../../shared/ui';
import { renderMixedText } from '../../shared/MathField';
import { cn, questionTypeLabel, resolveMediaUrl } from '../../lib/utils';

const DEFAULT_IDENTITY_FIELDS = [
  { id: 'field_name', label: 'Nama Lengkap', field_type: 'text', placeholder: 'Masukkan nama lengkap kamu', is_required: true },
  { id: 'field_class', label: 'Kelas', field_type: 'dropdown', placeholder: 'Pilih Kelas', is_required: true, options: ['X RPL 1', 'X RPL 2', 'XI RPL 1', 'XI RPL 2', 'XII RPL 1', 'XII RPL 2'] },
  { id: 'field_absence', label: 'Nomor Absen', field_type: 'number', placeholder: 'Contoh: 18', is_required: true },
];

function parseIdentityFields(jsonStr) {
  if (!jsonStr) return [];
  try {
    const parsed = JSON.parse(jsonStr);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export default function StudentPreviewPage() {
  const { formId } = useParams();
  const navigate = useNavigate();

  const { data: form, isLoading } = useQuery({
    queryKey: ['form', formId],
    queryFn: () => formApi.getById(formId),
  });

  const accent = form?.form_settings?.theme_color || '#4F46E5';
  const fontFamily = form?.form_settings?.font_family || 'Inter';
  const questions = form?.questions || [];
  const settings = form?.form_settings;

  const identityFields = parseIdentityFields(settings?.identity_fields_json);
  const hasIdentityFields = identityFields.length > 0;
  const isTokenProtected = Boolean(settings?.is_token_protected);

  // Stages: 'IDENTITY' -> 'TOKEN' -> 'EXAM'
  const [currentStage, setCurrentStage] = useState('EXAM');
  const [stageInitialized, setStageInitialized] = useState(false);

  useEffect(() => {
    if (form && !stageInitialized) {
      const fields = parseIdentityFields(form.form_settings?.identity_fields_json);
      const isProt = Boolean(form.form_settings?.is_token_protected);
      if (fields.length > 0) {
        setCurrentStage('IDENTITY');
      } else if (isProt) {
        setCurrentStage('TOKEN');
      } else {
        setCurrentStage('EXAM');
      }
      setStageInitialized(true);
    }
  }, [form, stageInitialized]);

  // Safeguard: If stage was set to IDENTITY but there are no identity fields, bypass immediately
  useEffect(() => {
    if (stageInitialized && currentStage === 'IDENTITY' && !hasIdentityFields) {
      if (isTokenProtected) {
        setCurrentStage('TOKEN');
      } else {
        setCurrentStage('EXAM');
      }
    }
  }, [stageInitialized, currentStage, hasIdentityFields, isTokenProtected]);

  // Identity Form State
  const [identityData, setIdentityData] = useState({});
  const [identityErrors, setIdentityErrors] = useState({});

  // Token Form State
  const [enteredToken, setEnteredToken] = useState('');
  const [tokenError, setTokenError] = useState('');

  // Exam Questions State
  const [index, setIndex] = useState(0);
  const [answers, setAnswers] = useState({});
  const [flagged, setFlagged] = useState({});

  const currentQuestion = questions[index];

  const setAnswer = (value) => setAnswers((a) => ({ ...a, [currentQuestion.id]: value }));
  const toggleFlag = () => setFlagged((f) => ({ ...f, [currentQuestion.id]: !f[currentQuestion.id] }));

  // Stage 1 -> Stage 2 or 3
  const handleProceedFromIdentity = (e) => {
    e?.preventDefault?.();
    const errors = {};
    identityFields.forEach((field) => {
      const val = identityData[field.id];
      if (field.is_required && (!val || String(val).trim() === '')) {
        errors[field.id] = `${field.label} wajib diisi`;
      }
    });

    if (Object.keys(errors).length > 0) {
      setIdentityErrors(errors);
      return;
    }

    setIdentityErrors({});
    if (isTokenProtected) {
      setCurrentStage('TOKEN');
    } else {
      setCurrentStage('EXAM');
    }
  };

  // Stage 2 -> Stage 3
  const handleProceedFromToken = (e) => {
    e?.preventDefault?.();
    const expectedToken = (settings?.exam_token || '').trim().toUpperCase();
    const actualToken = enteredToken.trim().toUpperCase();

    if (!actualToken) {
      setTokenError('Masukkan kode token ujian');
      return;
    }

    if (expectedToken && actualToken !== expectedToken) {
      setTokenError(`Kode token tidak cocok. (Petunjuk guru: ${expectedToken})`);
      return;
    }

    setTokenError('');
    setCurrentStage('EXAM');
  };

  const handleResetSimulation = () => {
    if (hasIdentityFields) {
      setCurrentStage('IDENTITY');
    } else if (isTokenProtected) {
      setCurrentStage('TOKEN');
    } else {
      setCurrentStage('EXAM');
    }
    setIdentityData({});
    setIdentityErrors({});
    setEnteredToken('');
    setTokenError('');
    setIndex(0);
    setAnswers({});
    setFlagged({});
  };

  if (isLoading) return <FullPageSpinner />;
  if (!form) return null;

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <button onClick={() => navigate(`/forms/${formId}`)} className="text-text-secondary hover:text-text">
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1 className="text-lg font-bold text-text">Preview Simulasi Siswa</h1>
            <p className="text-xs sm:text-sm text-text-secondary">
              Simulasi alur bertahap (Multi-Page Flow) yang akan dilalui siswa di aplikasi mobile.
            </p>
          </div>
        </div>

        <Button variant="outline" size="sm" onClick={handleResetSimulation} className="text-xs">
          <RotateCcw size={14} />
          Ulangi Simulasi (Page 1)
        </Button>
      </div>

      <div className="flex justify-center">
        <div
          className="preview-frame w-full max-w-sm overflow-hidden rounded-[2rem] border-8 border-neutral-800 bg-white shadow-2xl"
          style={{ '--preview-accent': accent, fontFamily }}
        >
          <div className="flex h-[640px] flex-col" style={{ backgroundColor: '#fff', color: '#111827' }}>
            {/* Header Mobile App */}
            <div className="flex items-center justify-between px-4 py-3 text-white shadow-xs" style={{ backgroundColor: accent }}>
              <span className="text-sm font-semibold truncate max-w-[200px]">{form.title}</span>
              <span className="text-xs opacity-90 font-medium">
                {currentStage === 'IDENTITY' && 'Page 1/3: Data Diri'}
                {currentStage === 'TOKEN' && 'Page 2/3: Token'}
                {currentStage === 'EXAM' && `Soal ${index + 1}/${questions.length || 0}`}
              </span>
            </div>

            {/* Stepper Wizard Bar */}
            <div className="flex items-center justify-around border-b border-gray-100 bg-gray-50 px-3 py-2 text-[11px] font-medium text-gray-500">
              {hasIdentityFields && (
                <>
                  <button
                    type="button"
                    onClick={() => setCurrentStage('IDENTITY')}
                    className={cn(
                      'flex items-center gap-1 transition-colors',
                      currentStage === 'IDENTITY' ? 'font-bold text-indigo-600' : 'hover:text-gray-800'
                    )}
                  >
                    <UserCheck size={13} />
                    <span>1. Data Diri</span>
                  </button>
                  <span className="text-gray-300">&rarr;</span>
                </>
              )}

              {isTokenProtected && (
                <>
                  <button
                    type="button"
                    onClick={() => setCurrentStage('TOKEN')}
                    className={cn(
                      'flex items-center gap-1 transition-colors',
                      currentStage === 'TOKEN' ? 'font-bold text-amber-600' : 'hover:text-gray-800'
                    )}
                  >
                    <KeyRound size={13} />
                    <span>{hasIdentityFields ? '2. Token' : '1. Token'}</span>
                  </button>
                  <span className="text-gray-300">&rarr;</span>
                </>
              )}

              <button
                type="button"
                onClick={() => setCurrentStage('EXAM')}
                className={cn(
                  'flex items-center gap-1 transition-colors',
                  currentStage === 'EXAM' ? 'font-bold text-emerald-600' : 'hover:text-gray-800'
                )}
              >
                <CheckCircle2 size={13} />
                <span>
                  {hasIdentityFields && isTokenProtected
                    ? '3. Soal'
                    : hasIdentityFields || isTokenProtected
                    ? '2. Soal'
                    : '1. Soal'}
                </span>
              </button>
            </div>

            {/* STAGE 1: IDENTITY DATA COLLECTION */}
            {currentStage === 'IDENTITY' && hasIdentityFields && (
              <div className="flex flex-1 flex-col overflow-y-auto p-4">
                <div className="mb-4">
                  <h2 className="text-base font-bold text-gray-900">Data Peserta Ujian</h2>
                  <p className="text-xs text-gray-500 mt-0.5">
                    Lengkapi data diri kamu dengan benar sebelum melanjutkan ke ujian.
                  </p>
                </div>

                <form onSubmit={handleProceedFromIdentity} className="flex flex-1 flex-col gap-3">
                  {identityFields.map((field) => {
                    const error = identityErrors[field.id];
                    return (
                      <div key={field.id} className="flex flex-col gap-1">
                        <label className="text-xs font-semibold text-gray-700">
                          {field.label}
                          {field.is_required && <span className="text-red-500 ml-1">*</span>}
                        </label>

                        {field.field_type === 'dropdown' ? (
                          <select
                            className={cn(
                              'w-full rounded-lg border px-3 py-2 text-xs bg-white text-gray-800 focus:outline-none',
                              error ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-indigo-600'
                            )}
                            value={identityData[field.id] || ''}
                            onChange={(e) => {
                              setIdentityData((d) => ({ ...d, [field.id]: e.target.value }));
                              if (identityErrors[field.id]) {
                                setIdentityErrors((errs) => ({ ...errs, [field.id]: null }));
                              }
                            }}
                          >
                            <option value="">{field.placeholder || '-- Pilih --'}</option>
                            {(field.options || []).map((opt, optIdx) => (
                              <option key={optIdx} value={opt}>
                                {opt}
                              </option>
                            ))}
                          </select>
                        ) : (
                          <input
                            type={field.field_type === 'number' ? 'number' : field.field_type === 'email' ? 'email' : 'text'}
                            placeholder={field.placeholder || ''}
                            className={cn(
                              'w-full rounded-lg border px-3 py-2 text-xs text-gray-800 focus:outline-none',
                              error ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-indigo-600'
                            )}
                            value={identityData[field.id] || ''}
                            onChange={(e) => {
                              setIdentityData((d) => ({ ...d, [field.id]: e.target.value }));
                              if (identityErrors[field.id]) {
                                setIdentityErrors((errs) => ({ ...errs, [field.id]: null }));
                              }
                            }}
                          />
                        )}

                        {error && <span className="text-[10px] text-red-500">{error}</span>}
                      </div>
                    );
                  })}

                  <div className="mt-auto pt-4">
                    <Button
                      type="submit"
                      className="w-full text-white font-semibold text-xs py-2.5 shadow-sm"
                      style={{ backgroundColor: accent }}
                    >
                      {isTokenProtected ? 'Lanjutkan ke Token Ujian &rarr;' : 'Mulai Kerjakan Ujian &rarr;'}
                    </Button>
                  </div>
                </form>
              </div>
            )}

            {/* STAGE 2: TOKEN GATEKEEPER */}
            {currentStage === 'TOKEN' && (
              <div className="flex flex-1 flex-col overflow-y-auto p-5">
                <div className="my-auto flex flex-col items-center text-center gap-3">
                  <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-amber-50 text-amber-600 border border-amber-200 shadow-sm">
                    <KeyRound size={28} />
                  </div>

                  <div>
                    <h2 className="text-base font-bold text-gray-900">Token Akses Ujian</h2>
                    <p className="text-xs text-gray-500 mt-1 max-w-[240px]">
                      Ujian ini dilindungi kode akses. Masukkan token yang diberikan oleh guru pengawas.
                    </p>
                  </div>

                  {identityData?.field_name && (
                    <div className="rounded-full bg-gray-100 px-3 py-1 text-[11px] text-gray-600 font-medium">
                      Peserta: <strong>{identityData.field_name}</strong>
                    </div>
                  )}

                  <form onSubmit={handleProceedFromToken} className="w-full mt-2 flex flex-col gap-3">
                    <input
                      type="text"
                      maxLength={20}
                      placeholder="Ketik Kode Token..."
                      className="w-full rounded-xl border-2 border-amber-400 bg-amber-50/40 p-3 text-center text-base font-mono font-bold uppercase tracking-widest text-gray-900 focus:outline-none focus:border-amber-500"
                      value={enteredToken}
                      onChange={(e) => {
                        setEnteredToken(e.target.value.toUpperCase());
                        setTokenError('');
                      }}
                      autoFocus
                    />

                    {tokenError && (
                      <div className="flex items-center justify-center gap-1.5 text-xs text-red-500 font-medium">
                        <AlertCircle size={14} />
                        <span>{tokenError}</span>
                      </div>
                    )}

                    <Button
                      type="submit"
                      className="w-full text-white font-semibold text-xs py-2.5 shadow-sm mt-1"
                      style={{ backgroundColor: accent }}
                    >
                      <ShieldCheck size={15} />
                      Verifikasi & Mulai Ujian &rarr;
                    </Button>
                  </form>
                </div>
              </div>
            )}

            {/* STAGE 3: EXAM QUESTIONS RUNNER */}
            {currentStage === 'EXAM' && (
              <>
                {questions.length === 0 ? (
                  <div className="flex flex-1 items-center justify-center p-6 text-center text-sm text-gray-500">
                    Form ini belum punya soal.
                  </div>
                ) : (
                  <>
                    <div className="flex-1 overflow-y-auto p-4">
                      <div className="mb-3 flex items-center justify-between">
                        <span className="text-xs font-medium text-gray-500">
                          {questionTypeLabel(currentQuestion.question_type)} &middot; {currentQuestion.points} poin
                        </span>
                        <button
                          onClick={toggleFlag}
                          className={cn(
                            'flex items-center gap-1 text-xs',
                            flagged[currentQuestion.id] ? 'text-amber-500' : 'text-gray-400'
                          )}
                        >
                          <Flag size={14} fill={flagged[currentQuestion.id] ? 'currentColor' : 'none'} />
                          Ragu-ragu
                        </button>
                      </div>

                      <div
                        className="mb-4 text-base font-semibold text-gray-900 leading-relaxed"
                        dangerouslySetInnerHTML={{ __html: renderMixedText(currentQuestion.question_text) }}
                      />

                      {currentQuestion.img_url && (
                        <img
                          src={resolveMediaUrl(currentQuestion.img_url)}
                          alt=""
                          className="mb-3 max-h-48 w-full rounded-lg object-contain"
                        />
                      )}
                      {currentQuestion.audio_url && (
                        <audio src={resolveMediaUrl(currentQuestion.audio_url)} controls className="mb-3 w-full" />
                      )}
                      {currentQuestion.video_url && (
                        <video src={resolveMediaUrl(currentQuestion.video_url)} controls className="mb-3 max-h-48 w-full rounded-lg" />
                      )}

                      <QuestionAnswerArea
                        question={currentQuestion}
                        value={answers[currentQuestion.id]}
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
                            i === index
                              ? 'text-white'
                              : flagged[q.id]
                              ? 'bg-amber-100 text-amber-700'
                              : answers[q.id] !== undefined
                              ? 'bg-gray-200 text-gray-700'
                              : 'bg-gray-100 text-gray-400'
                          )}
                          style={i === index ? { backgroundColor: accent } : undefined}
                        >
                          {i + 1}
                        </button>
                      ))}
                    </div>

                    <div className="flex justify-between gap-2 border-t border-gray-100 px-4 py-3">
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={index === 0}
                        onClick={() => setIndex((i) => i - 1)}
                      >
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
        className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-primary focus:outline-none"
        placeholder="Ketik jawabanmu..."
        value={value || ''}
        onChange={(e) => onChange(e.target.value)}
      />
    );
  }
  if (type === 'LONG_TEXT' || type === 'CODE') {
    return (
      <textarea
        className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-primary focus:outline-none"
        rows={5}
        placeholder={type === 'CODE' ? 'Ketik kode program jawabanmu di sini...' : 'Ketik jawaban lengkapmu di sini...'}
        value={value || ''}
        onChange={(e) => onChange(e.target.value)}
      />
    );
  }
  if (type === 'MATCHING') {
    return (
      <div className="flex flex-col gap-2 text-sm">
        {question.options?.map((o) => (
          <div key={o.id} className="flex items-center justify-between gap-2 rounded-lg border border-gray-200 p-2.5 bg-gray-50/60">
            <span className="font-medium text-gray-800">{o.option_text}</span>
            <span className="text-gray-400 font-bold">&harr;</span>
            <span className="text-gray-600">{o.match_target_text}</span>
          </div>
        ))}
        <p className="text-xs text-gray-400 mt-1">(di aplikasi siswa, pasangan ini akan diacak dan siswa menjodohkan sendiri)</p>
      </div>
    );
  }
  if (type === 'RATING') {
    return (
      <div className="flex gap-2 justify-center py-2">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            onClick={() => onChange(n)}
            className="flex h-10 w-10 items-center justify-center rounded-full border text-sm font-semibold transition-all"
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
        {question.options?.map((o, idx) => {
          const isSelected = selected.includes(o.id);
          const letter = String.fromCharCode(65 + idx);
          return (
            <label
              key={o.id}
              className={cn(
                'flex items-start gap-3 rounded-xl border p-3 text-sm cursor-pointer transition-colors',
                isSelected
                  ? 'border-indigo-600 bg-indigo-50/60 font-medium'
                  : 'border-gray-200 hover:border-gray-300 bg-white'
              )}
            >
              <div className="flex items-center gap-2 pt-0.5">
                <input
                  type="checkbox"
                  checked={isSelected}
                  onChange={() =>
                    onChange(isSelected ? selected.filter((id) => id !== o.id) : [...selected, o.id])
                  }
                  className="rounded text-primary focus:ring-primary"
                />
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-gray-100 text-[11px] font-bold text-gray-700">
                  {letter}
                </span>
              </div>
              <div className="flex-1 min-w-0 pt-0.5 text-gray-900">
                <span dangerouslySetInnerHTML={{ __html: renderMixedText(o.option_text) }} />
              </div>
            </label>
          );
        })}
      </div>
    );
  }
  // MULTIPLE_CHOICE, DROPDOWN, YES_NO, MATH (dengan opsi), dll.
  if (question.options?.length) {
    return (
      <div className="flex flex-col gap-2">
        {question.options.map((o, idx) => {
          const isSelected = value === o.id;
          const letter = String.fromCharCode(65 + idx);
          return (
            <label
              key={o.id}
              className={cn(
                'flex items-start gap-3 rounded-xl border p-3 text-sm cursor-pointer transition-colors',
                isSelected
                  ? 'border-indigo-600 bg-indigo-50/60 font-medium'
                  : 'border-gray-200 hover:border-gray-300 bg-white'
              )}
            >
              <div className="flex items-center gap-2 pt-0.5">
                <input
                  type="radio"
                  name={question.id}
                  checked={isSelected}
                  onChange={() => onChange(o.id)}
                  className="text-primary focus:ring-primary"
                />
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-gray-100 text-[11px] font-bold text-gray-700">
                  {letter}
                </span>
              </div>
              <div className="flex-1 min-w-0 pt-0.5 text-gray-900">
                <span dangerouslySetInnerHTML={{ __html: renderMixedText(o.option_text) }} />
              </div>
            </label>
          );
        })}
      </div>
    );
  }
  return (
    <input
      className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-primary focus:outline-none"
      placeholder="Ketik jawabanmu..."
      value={value || ''}
      onChange={(e) => onChange(e.target.value)}
    />
  );
}
