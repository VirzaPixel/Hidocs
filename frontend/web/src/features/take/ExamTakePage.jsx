import { useState, useEffect, useMemo, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  ArrowLeft,
  ChevronLeft,
  ChevronRight,
  Flag,
  UserCheck,
  KeyRound,
  CheckCircle2,
  AlertCircle,
  Clock,
  Grid,
  Send,
  ShieldCheck,
  Sparkles,
  HelpCircle,
  X,
  RotateCcw,
  ShieldAlert,
  AlertTriangle,
  Maximize2,
  Lock,
  RefreshCw,
  ArrowRight,
} from 'lucide-react';
import { publicApi } from '../../lib/api';
import { Button, FullPageSpinner, Badge, Card } from '../../shared/ui';
import { renderMixedText } from '../../shared/MathField';
import { cn, questionTypeLabel, resolveMediaUrl } from '../../lib/utils';
import { useToast } from '../../shared/Toast';
import { useAuthStore } from '../../store/authStore';

function parseIdentityFields(jsonStr) {
  if (!jsonStr) return [];
  try {
    const parsed = JSON.parse(jsonStr);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function getRespondentIdentifier(identityData, currentUser, formId) {
  // If explicitly entered email
  const explicitEmail =
    identityData?.field_email ||
    identityData?.email ||
    Object.values(identityData || {}).find(
      (v) => typeof v === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim())
    ) ||
    currentUser?.email;

  if (explicitEmail && String(explicitEmail).trim()) {
    return String(explicitEmail).trim().toLowerCase();
  }

  // Otherwise deterministic slug from default fields (Nama, Kelas, No Absen)
  const name = String(identityData?.field_name || identityData?.name || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
  const cls = String(identityData?.field_class || identityData?.class || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
  const absence = String(identityData?.field_absence || identityData?.absence || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');

  if (name || cls || absence) {
    const slug = [name || 'peserta', cls || 'kelas', absence || '00'].join('.');
    return `${slug}@student.hidocs.local`;
  }

  // Persistent browser device ID fallback
  let deviceId = localStorage.getItem('hidocs_student_uid');
  if (!deviceId) {
    deviceId = Math.random().toString(36).substring(2, 10);
    localStorage.setItem('hidocs_student_uid', deviceId);
  }
  return `device-${deviceId}@student.hidocs.local`;
}

export default function ExamTakePage() {
  const { identifier } = useParams();
  const navigate = useNavigate();
  const toast = useToast();
  const currentUser = useAuthStore((s) => s.user);

  const { data: form, isLoading, error } = useQuery({
    queryKey: ['public-form', identifier],
    queryFn: () => publicApi.getForm(identifier),
    retry: 1,
  });

  const [verifiedForm, setVerifiedForm] = useState(null);
  const activeForm = verifiedForm || form;

  const settings = activeForm?.form_settings;
  const questions = useMemo(() => activeForm?.questions || [], [activeForm]);
  const accent = settings?.theme_color || '#4F46E5';
  const fontFamily = settings?.font_family || 'Inter';

  const identityFields = useMemo(
    () => parseIdentityFields(settings?.identity_fields_json),
    [settings]
  );
  const isTokenProtected = Boolean(settings?.is_token_protected);
  const isOneTimeSubmission = Boolean(settings?.is_one_time_submission);

  const isAlreadySubmittedLocally = useMemo(() => {
    if (!form?.id || !isOneTimeSubmission) return false;
    const submittedKey = `hidocs_submitted_${form.id}`;
    return localStorage.getItem(submittedKey) === 'true';
  }, [form?.id, isOneTimeSubmission]);

  const durationMinutes = settings?.duration_minutes || 0;
  const durationSeconds = durationMinutes * 60;
  const [timeLeft, setTimeLeft] = useState(durationSeconds);

  useEffect(() => {
    if (settings?.duration_minutes) {
      setTimeLeft(settings.duration_minutes * 60);
    }
  }, [settings?.duration_minutes]);

  // Stages: 'IDENTITY' | 'TOKEN' | 'EXAM' | 'COMPLETED'
  const [currentStage, setCurrentStage] = useState('EXAM');
  const [stageInitialized, setStageInitialized] = useState(false);
  const [sessionId, setSessionId] = useState(
    () => localStorage.getItem(`hidocs_session_${identifier}`) || null
  );

  const restoreAnswersFromQuestions = (questionItems) => {
    if (!Array.isArray(questionItems) || questionItems.length === 0) return;
    const restoredAnswers = {};
    const restoredFlagged = {};
    questionItems.forEach((sq) => {
      if (sq.is_flagged) restoredFlagged[sq.question_id] = true;
      if (sq.selected_option_id) {
        restoredAnswers[sq.question_id] = sq.selected_option_id;
      } else if (sq.match_pairs && sq.match_pairs.length > 0) {
        restoredAnswers[sq.question_id] = sq.match_pairs;
      } else if (sq.answer_text) {
        restoredAnswers[sq.question_id] = sq.answer_text;
      }
    });
    setAnswers((prev) => ({ ...restoredAnswers, ...prev }));
    setFlagged((prev) => ({ ...restoredFlagged, ...prev }));
  };

  const ensureSessionActive = async (tokenVal, identityVals) => {
    try {
      const respondentEmail = getRespondentIdentifier(identityVals, currentUser, form?.id);
      const res = await publicApi.verifyToken(form?.id || identifier, tokenVal, respondentEmail);
      const resId = res?.response_id || res?.response?.id || res?.data?.response?.id || res?.session_state?.response_id;
      if (resId) {
        setSessionId(resId);
        try {
          localStorage.setItem(`hidocs_session_${form?.id || identifier}`, resId);
        } catch {}
      }
      const returnedForm = res?.form || res?.data?.form;
      if (returnedForm) {
        setVerifiedForm(returnedForm);
      }

      // Restore previously saved answers & flagged marks from database
      const sessionQuestions = res?.session_state?.questions || res?.data?.session_state?.questions;
      restoreAnswersFromQuestions(sessionQuestions);
      return { success: true };
    } catch (err) {
      const msg = err?.response?.data?.message || err?.message || 'Gagal memulai sesi ujian';
      if (msg.includes('BLOCKED') || msg.includes('dicabut') || msg.includes('kecurangan')) {
        setIsBlocked(true);
        setStrikes(3);
      }
      return { success: false, error: msg };
    }
  };

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
        ensureSessionActive('', {});
      }
      setStageInitialized(true);
    }
  }, [form, stageInitialized]);

  // Identity Form State
  const [identityData, setIdentityData] = useState({});
  const [identityErrors, setIdentityErrors] = useState({});

  // Token Form State
  const [enteredToken, setEnteredToken] = useState('');
  const [tokenError, setTokenError] = useState('');

  // Exam Questions State
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState({});
  const [flagged, setFlagged] = useState({}); // { [questionId]: boolean }
  const [showMatrixModal, setShowMatrixModal] = useState(false);
  const [showSubmitModal, setShowSubmitModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [submissionResult, setSubmissionResult] = useState(null);

  const autosaveTimeoutRef = useRef(null);

  // Anti-cheat Fullscreen & 3-Strike System State
  const [isFullscreenActive, setIsFullscreenActive] = useState(false);
  const [strikes, setStrikes] = useState(0); // 0, 1, 2, 3
  const [isBlocked, setIsBlocked] = useState(false);
  const [showGuardOverlay, setShowGuardOverlay] = useState(false);
  const [guardCountdown, setGuardCountdown] = useState(5);
  const [guardReason, setGuardReason] = useState('');
  const [recheckingAccess, setRecheckingAccess] = useState(false);

  const strikesRef = useRef(0);
  strikesRef.current = strikes;
  const isBlockedRef = useRef(false);
  isBlockedRef.current = isBlocked;
  const guardActiveRef = useRef(false);
  guardActiveRef.current = showGuardOverlay;

  const enterFullscreen = () => {
    try {
      const elem = document.documentElement;
      if (elem.requestFullscreen) {
        elem.requestFullscreen().catch(() => {});
      } else if (elem.webkitRequestFullscreen) {
        elem.webkitRequestFullscreen().catch(() => {});
      } else if (elem.msRequestFullscreen) {
        elem.msRequestFullscreen().catch(() => {});
      }
      setIsFullscreenActive(true);
    } catch {}
  };

  const triggerViolation = (reason) => {
    if (currentStage !== 'EXAM' || isBlockedRef.current || showSubmitModal) return;
    if (guardActiveRef.current) return;

    const currentStrikes = strikesRef.current;
    const nextStrikes = currentStrikes + 1;
    setStrikes(nextStrikes);

    let eventType = 'FULLSCREEN_EXIT';
    let message = `Peringatan 1: User mencoba keluar dari tab / fullscreen (${reason})`;

    if (nextStrikes === 1) {
      eventType = 'TAB_SWITCH';
      message = `Peringatan 1: User mencoba keluar dari tab / fullscreen (${reason})`;
      setGuardReason('Kamu terdeteksi keluar dari layar penuh / jendela ujian!');
      setShowGuardOverlay(true);
      setGuardCountdown(5);
    } else if (nextStrikes === 2) {
      eventType = 'CHEATING_SUSPECTED';
      message = `Peringatan 2: Terindikasi melakukan kecurangan (${reason})`;
      setGuardReason('Peringatan ke-2: Kamu terindikasi melakukan kecurangan! 1 kali lagi izin ujian akan dicabut.');
      setShowGuardOverlay(true);
      setGuardCountdown(5);
    } else {
      eventType = 'SESSION_BLOCKED';
      message = `Peringatan 3: Izin pengerjaan dicabut (BLOCKED) karena pelanggaran ke-3 (${reason})`;
      setIsBlocked(true);
      setShowGuardOverlay(false);
    }

    if (sessionId) {
      publicApi
        .telemetry(sessionId, {
          event_type: eventType,
          event_message: message,
          current_question_index: currentIndex,
        })
        .catch((e) => console.error('Telemetry error:', e));
    }
  };

  const handleDismissGuard = () => {
    enterFullscreen();
    setShowGuardOverlay(false);
    toast.info('Kembali ke mode ujian layar penuh');
  };

  // Countdown timer in guard overlay (Strike 1 -> Strike 2 -> Strike 3 Blocked)
  useEffect(() => {
    if (!showGuardOverlay || isBlocked) return;

    const timer = setInterval(() => {
      setGuardCountdown((prev) => {
        if (prev <= 1) {
          const currentStrikes = strikesRef.current;
          if (currentStrikes >= 2) {
            // Second 5-second countdown expired without returning -> Strike 3: Blocked!
            setIsBlocked(true);
            setShowGuardOverlay(false);
            setStrikes(3);
            if (sessionId) {
              publicApi
                .telemetry(sessionId, {
                  event_type: 'SESSION_BLOCKED',
                  event_message:
                    'Peringatan 3: Izin pengerjaan dicabut (BLOCKED) - Mengabaikan countdown layar penuh',
                  current_question_index: currentIndex,
                })
                .catch(() => {});
            }
            return 0;
          } else {
            // First 5-second countdown expired without returning -> Escalate to Strike 2!
            setStrikes(2);
            setGuardReason(
              'Peringatan ke-2: Kamu terindikasi melakukan kecurangan! 1 kali lagi izin pengerjaan akan dicabut.'
            );
            if (sessionId) {
              publicApi
                .telemetry(sessionId, {
                  event_type: 'CHEATING_SUSPECTED',
                  event_message: 'Peringatan 2: Siswa mengabaikan hitungan mundur pertama (5s)',
                  current_question_index: currentIndex,
                })
                .catch(() => {});
            }
            return 5; // Reset countdown for second 5s window
          }
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [showGuardOverlay, isBlocked, sessionId, currentIndex]);

  // Anti-cheat Listeners: Fullscreen, Tab Switch, and Floating App / Blur
  useEffect(() => {
    if (currentStage !== 'EXAM') return;

    const handleFullscreenChange = () => {
      const isFS = Boolean(document.fullscreenElement || document.webkitFullscreenElement);
      setIsFullscreenActive(isFS);
      if (!isFS && !isBlockedRef.current && currentStage === 'EXAM') {
        triggerViolation('Keluar dari Layar Penuh');
      }
    };

    const handleVisibilityChange = () => {
      if (document.hidden && !isBlockedRef.current && currentStage === 'EXAM') {
        triggerViolation('Berpindah Tab / Aplikasi di Luar Browser');
      }
    };

    const handleBlur = () => {
      if (!isBlockedRef.current && currentStage === 'EXAM') {
        triggerViolation('Jendela Ujian Kehilangan Fokus (Floating App / Split Screen / Klik di Luar)');
      }
    };

    document.addEventListener('fullscreenchange', handleFullscreenChange);
    document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('blur', handleBlur);

    return () => {
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
      document.removeEventListener('webkitfullscreenchange', handleFullscreenChange);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('blur', handleBlur);
    };
  }, [currentStage]);

  // Periodic polling & operator unlock check when student is blocked
  const handleCheckOperatorUnlock = async () => {
    setRecheckingAccess(true);
    try {
      if (sessionId) {
        try {
          const res = await publicApi.getSessionState(sessionId);
          const sessionData = res?.data || res;
          if (sessionData && sessionData.status && sessionData.status !== 'BLOCKED') {
            if (sessionData.status === 'RESTARTED') {
              await publicApi.acknowledgeWarning(sessionId).catch(() => {});
            }
            if (sessionData.questions) {
              restoreAnswersFromQuestions(sessionData.questions);
            }
            setIsBlocked(false);
            setStrikes(0);
            setShowGuardOverlay(false);
            toast.success('Izin pengerjaan kamu telah dibuka kembali oleh pengawas!');
            enterFullscreen();
            return;
          }
        } catch {}
      }

      const respondentEmail = getRespondentIdentifier(identityData, currentUser, form?.id);
      const tokenRes = await publicApi.verifyToken(form?.id || identifier, enteredToken, respondentEmail);
      const resId = tokenRes?.response_id || tokenRes?.response?.id || tokenRes?.session_state?.response_id;
      if (resId) {
        setSessionId(resId);
        try {
          localStorage.setItem(`hidocs_session_${form?.id || identifier}`, resId);
        } catch {}
      }
      const questionsToRestore = tokenRes?.session_state?.questions || tokenRes?.questions;
      if (questionsToRestore) {
        restoreAnswersFromQuestions(questionsToRestore);
      }
      setIsBlocked(false);
      setStrikes(0);
      setShowGuardOverlay(false);
      toast.success('Izin pengerjaan kamu telah dibuka kembali oleh pengawas!');
      enterFullscreen();
    } catch (err) {
      toast.error(err?.response?.data?.message || err?.message || 'Status izin belum dibuka oleh operator/pengawas');
    } finally {
      setRecheckingAccess(false);
    }
  };

  useEffect(() => {
    if (!isBlocked) return;
    const interval = setInterval(async () => {
      try {
        if (sessionId) {
          const res = await publicApi.getSessionState(sessionId);
          const sessionData = res?.data || res;
          if (sessionData && sessionData.status && sessionData.status !== 'BLOCKED') {
            if (sessionData.status === 'RESTARTED') {
              await publicApi.acknowledgeWarning(sessionId).catch(() => {});
            }
            if (sessionData.questions) {
              restoreAnswersFromQuestions(sessionData.questions);
            }
            setIsBlocked(false);
            setStrikes(0);
            setShowGuardOverlay(false);
            toast.success('Izin pengerjaan kamu telah dibuka kembali oleh pengawas!');
            enterFullscreen();
            return;
          }
        } else {
          const respondentEmail = getRespondentIdentifier(identityData, currentUser, form?.id);
          const tokenRes = await publicApi.verifyToken(form?.id || identifier, enteredToken, respondentEmail);
          if (tokenRes) {
            const resId = tokenRes?.response_id || tokenRes?.response?.id;
            if (resId) setSessionId(resId);
            const questionsToRestore = tokenRes?.session_state?.questions || tokenRes?.questions;
            if (questionsToRestore) {
              restoreAnswersFromQuestions(questionsToRestore);
            }
            setIsBlocked(false);
            setStrikes(0);
            setShowGuardOverlay(false);
            toast.success('Izin pengerjaan kamu telah dibuka kembali oleh pengawas!');
            enterFullscreen();
          }
        }
      } catch (err) {
        // Still blocked
      }
    }, 3000);

    return () => clearInterval(interval);
  }, [isBlocked, sessionId, identityData, currentUser, form?.id, identifier, enteredToken]);

  // Timer Countdown Effect
  useEffect(() => {
    if (currentStage !== 'EXAM' || durationSeconds <= 0 || timeLeft <= 0) return;
    const interval = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          clearInterval(interval);
          toast.info('Waktu ujian telah berakhir! Mengumpulkan jawaban secara otomatis...');
          handleFinalSubmit();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [currentStage, durationSeconds, timeLeft]);

  const formatTimer = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    const pad = (n) => String(n).padStart(2, '0');
    return `${pad(mins)}:${pad(secs)}`;
  };

  // Helper Stats
  const answeredCount = Object.keys(answers).filter(
    (k) => answers[k] !== undefined && answers[k] !== '' && (!Array.isArray(answers[k]) || answers[k].length > 0)
  ).length;
  const flaggedCount = Object.keys(flagged).filter((k) => flagged[k]).length;
  const unansweredCount = Math.max(0, questions.length - answeredCount);
  const progressPercent = questions.length > 0 ? Math.round((answeredCount / questions.length) * 100) : 0;

  const currentQuestion = questions[currentIndex];

  const triggerAutosave = async (questionId, value, isFlaggedVal) => {
    if (!sessionId || !questionId) return;
    const q = questions.find((item) => item.id === questionId);
    if (!q) return;

    const payload = {
      question_id: questionId,
      is_flagged: Boolean(isFlaggedVal !== undefined ? isFlaggedVal : flagged[questionId]),
    };

    if (q.question_type === 'CHECKBOXES') {
      const selected = Array.isArray(value) ? value : [];
      payload.selected_option_id = selected.length > 0 ? selected[0] : null;
      payload.answer_text = selected.join(',');
    } else if (q.question_type === 'MATCHING') {
      payload.selected_option_id = null;
      payload.match_pairs = Array.isArray(value) ? value : [];
    } else if (q.options && q.options.length > 0) {
      payload.selected_option_id = value || null;
    } else {
      payload.selected_option_id = null;
      payload.answer_text = value != null ? String(value) : '';
    }

    try {
      await publicApi.autosave(sessionId, payload);
    } catch (err) {
      console.error('Autosave error:', err);
    }
  };

  const handleSetAnswer = (val) => {
    if (!currentQuestion) return;
    setAnswers((prev) => ({ ...prev, [currentQuestion.id]: val }));

    const isTextType = ['SHORT_TEXT', 'LONG_TEXT', 'CODE'].includes(currentQuestion.question_type);
    if (isTextType) {
      if (autosaveTimeoutRef.current) {
        clearTimeout(autosaveTimeoutRef.current);
      }
      autosaveTimeoutRef.current = setTimeout(() => {
        triggerAutosave(currentQuestion.id, val);
      }, 600);
    } else {
      // Instant broadcast for MCQ, Checkbox, Rating, Matching
      triggerAutosave(currentQuestion.id, val);
    }
  };

  const handleToggleFlag = () => {
    if (!currentQuestion) return;
    const nextFlag = !flagged[currentQuestion.id];
    setFlagged((prev) => ({ ...prev, [currentQuestion.id]: nextFlag }));
    triggerAutosave(currentQuestion.id, answers[currentQuestion.id], nextFlag);
  };

  // Stage Handlers
  const handleProceedFromIdentity = async (e) => {
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
      setSubmitting(true);
      const res = await ensureSessionActive('', identityData);
      setSubmitting(false);
      if (!res.success) {
        toast.error(res.error);
        return;
      }
      enterFullscreen();
      setCurrentStage('EXAM');
    }
  };

  const handleProceedFromToken = async (e) => {
    e?.preventDefault?.();
    const actualToken = enteredToken.trim();

    if (!actualToken) {
      setTokenError('Masukkan kode token ujian');
      return;
    }

    setSubmitting(true);
    const res = await ensureSessionActive(actualToken, identityData);
    setSubmitting(false);
    if (!res.success) {
      setTokenError(res.error);
      return;
    }
    setTokenError('');
    enterFullscreen();
    setCurrentStage('EXAM');
  };

  const handleFinalSubmit = async () => {
    setSubmitting(true);
    try {
      // 1. Determine valid deterministic respondent email
      const respondentEmail = getRespondentIdentifier(identityData, currentUser, form?.id);

      // 2. Build submission answers array matching backend SubmitAnswerDetail
      const submissionAnswers = [];
      questions.forEach((q) => {
        const val = answers[q.id];
        const isFlagged = Boolean(flagged[q.id]);

        if (q.question_type === 'CHECKBOXES') {
          const selected = Array.isArray(val) ? val : [];
          if (selected.length > 0) {
            selected.forEach((optId) => {
              submissionAnswers.push({
                question_id: q.id,
                selected_option_id: optId,
                is_flagged: isFlagged,
              });
            });
          } else {
            submissionAnswers.push({
              question_id: q.id,
              selected_option_id: null,
              answer_text: '',
              is_flagged: isFlagged,
            });
          }
        } else if (q.options && q.options.length > 0 && q.question_type !== 'MATCHING') {
          submissionAnswers.push({
            question_id: q.id,
            selected_option_id: val || null,
            is_flagged: isFlagged,
          });
        } else if (q.question_type === 'MATCHING') {
          const pairs = Array.isArray(val) ? val : [];
          submissionAnswers.push({
            question_id: q.id,
            selected_option_id: null,
            match_pairs: pairs,
            is_flagged: isFlagged,
          });
        } else {
          submissionAnswers.push({
            question_id: q.id,
            selected_option_id: null,
            answer_text: val != null ? String(val) : '',
            is_flagged: isFlagged,
          });
        }
      });

      const payload = {
        response_id: sessionId || undefined,
        respondent_email: respondentEmail,
        device_platform: 'WEB',
        passcode: enteredToken ? enteredToken.trim().toUpperCase() : '',
        answers: submissionAnswers,
      };

      await publicApi.submit(form.id, payload);

      if (form?.id) {
        localStorage.setItem(`hidocs_submitted_${form.id}`, 'true');
      }

      setSubmissionResult({
        formTitle: form.title,
        answered: answeredCount,
        total: questions.length,
        submittedAt: new Date(),
      });
      setShowSubmitModal(false);
      setCurrentStage('COMPLETED');
      toast.success('Jawaban ujian berhasil dikumpulkan!');
    } catch (err) {
      toast.error(err.response?.data?.message || err.message || 'Gagal mengumpulkan jawaban ujian');
    } finally {
      setSubmitting(false);
    }
  };

  if (isLoading) return <FullPageSpinner />;

  if (error || !form) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-bg">
        <Card className="max-w-md w-full p-6 text-center space-y-4 border-red-500/20">
          <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-red-500/10 text-red-500 mx-auto">
            <AlertCircle size={28} />
          </div>
          <h2 className="text-lg font-bold text-text">Form Tidak Ditemukan</h2>
          <p className="text-xs text-text-secondary">
            Tautan atau kode form <strong>{identifier}</strong> tidak valid, telah ditutup, atau tidak tersedia.
          </p>
          <div className="flex gap-2 justify-center pt-2">
            <Button variant="primary" onClick={() => navigate('/take')}>
              Kembali ke Portal Ujian
            </Button>
          </div>
        </Card>
      </div>
    );
  }

  if (isAlreadySubmittedLocally) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-bg">
        <Card className="max-w-md w-full p-8 text-center space-y-4 border-emerald-500/30 shadow-lg">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-emerald-500/10 text-emerald-500 mx-auto">
            <CheckCircle2 size={36} />
          </div>
          <h2 className="text-lg font-bold text-text">Ujian Sudah Dikerjakan</h2>
          <p className="text-xs text-text-secondary leading-relaxed">
            Kamu sudah pernah mengumpulkan lembar jawaban untuk form <strong>{form.title}</strong>. Form ini hanya memperbolehkan 1 kali pengumpulan.
          </p>
          <div className="flex gap-2 justify-center pt-2">
            <Button variant="primary" onClick={() => navigate('/take')}>
              Kembali ke Portal Ujian
            </Button>
          </div>
        </Card>
      </div>
    );
  }

  if (isBlocked) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-slate-950 text-white select-none">
        <div className="max-w-md w-full bg-slate-900 border-2 border-red-600 rounded-3xl p-8 text-center space-y-6 shadow-2xl animate-in fade-in zoom-in-95 duration-200">
          <div className="flex h-20 w-20 items-center justify-center rounded-3xl bg-red-500/20 text-red-500 mx-auto border border-red-500/30 animate-pulse">
            <Lock size={44} />
          </div>
          <div className="space-y-2">
            <span className="inline-block px-3 py-1 rounded-full text-xs font-black uppercase tracking-wider bg-red-600 text-white">
              Sesi Ujian Dikunci
            </span>
            <h2 className="text-2xl font-black text-white">Izin Pengerjaan Dicabut</h2>
            <p className="text-sm text-slate-400 leading-relaxed">
              Kamu telah melanggar aturan ujian sebanyak <strong>3 kali</strong> (keluar dari layar penuh / berpindah aplikasi / membuka floating app). Sesi kamu diblokir secara otomatis oleh sistem anti-kecurangan.
            </p>
          </div>

          <div className="p-4 rounded-2xl bg-red-950/40 border border-red-800/40 text-xs text-red-300 text-left space-y-2">
            <div className="flex items-center gap-2 font-bold text-red-400">
              <ShieldAlert size={16} className="shrink-0" />
              <span>Instruksi untuk Siswa:</span>
            </div>
            <p>1. Silakan segera menghadap guru pengawas atau operator ujian di ruanganmu.</p>
            <p>2. Minta pengawas untuk melakukan reset / buka kunci sesi kamu pada sistem monitoring.</p>
            <p>3. Halaman ini akan otomatis pulih begitu operator mengonfirmasi pembukaan kunci.</p>
          </div>

          <div className="pt-2 flex flex-col gap-2">
            <Button
              variant="primary"
              className="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-3 rounded-xl flex items-center justify-center gap-2"
              onClick={handleCheckOperatorUnlock}
              loading={recheckingAccess}
            >
              <RefreshCw size={16} className={recheckingAccess ? 'animate-spin' : ''} />
              Cek Ulang Status Izin Sekarang
            </Button>
            <p className="text-[11px] text-slate-500">
              Sistem secara otomatis mengecek status izin setiap beberapa detik...
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className="min-h-screen flex flex-col bg-bg text-text selection:bg-primary/20"
      style={{ fontFamily }}
    >
      {/* Top Header */}
      <header className="sticky top-0 z-30 border-b border-border bg-surface/90 backdrop-blur-md px-4 py-3 sm:px-6">
        <div className="max-w-5xl mx-auto flex items-center justify-between gap-3">
          <div className="flex items-center gap-3 min-w-0">
            <button
              type="button"
              onClick={() => navigate('/take')}
              className="rounded-lg p-1.5 text-text-secondary hover:bg-bg-secondary hover:text-text transition-colors"
              title="Keluar / Kembali ke Portal"
            >
              <ArrowLeft size={18} />
            </button>
            <div className="min-w-0">
              <h1 className="text-sm sm:text-base font-bold text-text truncate">
                {activeForm?.title}
              </h1>
              {activeForm?.category && (
                <span className="text-[11px] text-text-secondary">
                  {activeForm.category}
                </span>
              )}
            </div>
          </div>

          <div className="flex items-center gap-2 sm:gap-3 shrink-0">
            {/* Countdown Timer */}
            {durationSeconds > 0 && currentStage === 'EXAM' && (
              <div
                className={cn(
                  'flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-bold tracking-wider border',
                  timeLeft < 300
                    ? 'bg-red-500/10 text-red-600 border-red-500/30 animate-pulse'
                    : 'bg-primary/10 text-primary border-primary/20'
                )}
              >
                <Clock size={14} />
                <span>{formatTimer(timeLeft)}</span>
              </div>
            )}

            {/* "Lihat Semua Soal" Button */}
            {currentStage === 'EXAM' && questions.length > 0 && (
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setShowMatrixModal(true)}
                className="gap-1.5 text-xs font-semibold shadow-sm"
              >
                <Grid size={15} className="text-primary" />
                <span className="hidden sm:inline">Lihat Semua Soal</span>
                <span className="sm:hidden">Soal</span>
                <Badge className="bg-primary/15 text-primary text-[10px] px-1.5 py-0">
                  {currentIndex + 1}/{questions.length}
                </Badge>
              </Button>
            )}
          </div>
        </div>

        {/* Progress Bar (Stage 3) */}
        {currentStage === 'EXAM' && questions.length > 0 && (
          <div className="max-w-5xl mx-auto mt-2">
            <div className="h-1.5 w-full bg-bg-secondary rounded-full overflow-hidden">
              <div
                className="h-full transition-all duration-300 rounded-full"
                style={{
                  width: `${progressPercent}%`,
                  backgroundColor: accent,
                }}
              />
            </div>
          </div>
        )}
      </header>

      {/* Main Content Area */}
      <main className="flex-1 max-w-4xl w-full mx-auto p-4 sm:p-6 flex flex-col justify-center">
        {/* ================= STAGE 1: IDENTITY DATA ================= */}
        {currentStage === 'IDENTITY' && (
          <div className="max-w-xl w-full mx-auto my-auto animate-fadeIn">
            <Card className="flex flex-col gap-5 p-6 sm:p-8 border-primary/20 shadow-md">
              <div className="flex items-center gap-3">
                <div
                  className="flex h-12 w-12 items-center justify-center rounded-2xl text-white shadow-md"
                  style={{ backgroundColor: accent }}
                >
                  <UserCheck size={24} />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-text">Data Diri Peserta Ujian</h2>
                  <p className="text-xs text-text-secondary mt-0.5">
                    Lengkapi identitas kamu dengan teliti sebelum memulai soal.
                  </p>
                </div>
              </div>

              <form onSubmit={handleProceedFromIdentity} className="flex flex-col gap-4 pt-2">
                {identityFields.map((field, idx) => {
                  const errorMsg = identityErrors[field.id];
                  return (
                    <div key={field.id || idx} className="flex flex-col gap-1.5">
                      <label className="text-xs font-semibold text-text flex items-center justify-between">
                        <span>
                          {field.label}
                          {field.is_required && <span className="text-red-500 ml-1">*</span>}
                        </span>
                      </label>

                      {field.field_type === 'dropdown' ? (
                        <select
                          className={cn(
                            'w-full rounded-xl border bg-surface px-3.5 py-2.5 text-sm text-text transition-all focus:outline-none',
                            errorMsg
                              ? 'border-red-500 focus:border-red-500'
                              : 'border-border focus:border-primary'
                          )}
                          value={identityData[field.id] || ''}
                          onChange={(e) => {
                            setIdentityData((d) => ({ ...d, [field.id]: e.target.value }));
                            if (identityErrors[field.id]) {
                              setIdentityErrors((errs) => ({ ...errs, [field.id]: null }));
                            }
                          }}
                        >
                          <option value="">{field.placeholder || '-- Pilih Opsi --'}</option>
                          {(field.options || []).map((opt, optIdx) => (
                            <option key={optIdx} value={opt}>
                              {opt}
                            </option>
                          ))}
                        </select>
                      ) : (
                        <input
                          type={
                            field.field_type === 'number'
                              ? 'number'
                              : field.field_type === 'email'
                              ? 'email'
                              : 'text'
                          }
                          placeholder={field.placeholder || 'Ketik di sini...'}
                          className={cn(
                            'w-full rounded-xl border bg-surface px-3.5 py-2.5 text-sm text-text transition-all focus:outline-none',
                            errorMsg
                              ? 'border-red-500 focus:border-red-500'
                              : 'border-border focus:border-primary'
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

                      {errorMsg && (
                        <span className="text-[11px] text-red-500 font-medium">{errorMsg}</span>
                      )}
                    </div>
                  );
                })}

                <Button
                  type="submit"
                  size="lg"
                  className="w-full text-white font-semibold text-sm mt-3 shadow-md justify-center flex items-center gap-2"
                  style={{ backgroundColor: accent }}
                >
                  {isTokenProtected ? (
                    <>
                      <span>Lanjutkan ke Token Ujian</span>
                      <ArrowRight size={16} />
                    </>
                  ) : (
                    <>
                      <span>Mulai Kerjakan Soal</span>
                      <ArrowRight size={16} />
                    </>
                  )}
                </Button>
              </form>
            </Card>
          </div>
        )}

        {/* ================= STAGE 2: TOKEN GATEKEEPER ================= */}
        {currentStage === 'TOKEN' && (
          <div className="max-w-md w-full mx-auto my-auto animate-fadeIn">
            <Card className="flex flex-col items-center text-center gap-4 p-6 sm:p-8 border-amber-500/20 shadow-md">
              <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-amber-500/10 text-amber-500 border border-amber-500/20 shadow-sm">
                <KeyRound size={32} />
              </div>

              <div>
                <h2 className="text-lg font-bold text-text">Token Gatekeeper Ujian</h2>
                <p className="text-xs text-text-secondary mt-1">
                  Ujian ini diproteksi. Masukkan token akses yang diberikan oleh guru pengawas untuk membuka soal.
                </p>
              </div>

              {identityData?.field_name && (
                <div className="rounded-full bg-bg-secondary px-3.5 py-1 text-xs text-text font-medium border border-border">
                  Peserta: <strong>{identityData.field_name}</strong>
                </div>
              )}

              <form onSubmit={handleProceedFromToken} className="w-full flex flex-col gap-3.5 mt-2">
                <input
                  type="text"
                  maxLength={20}
                  placeholder="KODE TOKEN"
                  className="w-full rounded-xl border-2 border-amber-500/50 bg-amber-500/5 p-3.5 text-center text-lg font-mono font-bold uppercase tracking-widest text-text focus:outline-none focus:border-amber-500"
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
                  size="lg"
                  className="w-full text-white font-semibold text-sm shadow-md justify-center mt-1"
                  style={{ backgroundColor: accent }}
                >
                  <ShieldCheck size={18} />
                  Verifikasi & Masuk Ujian
                </Button>
              </form>
            </Card>
          </div>
        )}

        {/* ================= STAGE 3: EXAM QUESTION SHEET ================= */}
        {currentStage === 'EXAM' && (
          <div className="flex flex-col gap-5 max-w-3xl w-full mx-auto animate-fadeIn">
            {questions.length === 0 ? (
              <Card className="p-8 text-center text-sm text-text-secondary">
                Belum ada soal yang tersedia pada form ujian ini.
              </Card>
            ) : (
              <>
                {/* Question Card */}
                <Card className="flex flex-col gap-5 p-5 sm:p-7 shadow-sm border-border">
                  {/* Question Header meta */}
                  <div className="flex items-center justify-between border-b border-border pb-3">
                    <div className="flex items-center gap-2">
                      <span
                        className="flex h-7 w-7 items-center justify-center rounded-lg text-xs font-bold text-white shadow-sm"
                        style={{ backgroundColor: accent }}
                      >
                        {currentIndex + 1}
                      </span>
                      <span className="text-xs font-semibold text-text">
                        Soal Nomor {currentIndex + 1} dari {questions.length}
                      </span>
                    </div>

                    <div className="flex items-center gap-2">
                      <Badge className="bg-bg-secondary text-text-secondary text-[11px] font-medium border border-border">
                        {questionTypeLabel(currentQuestion.question_type)} &middot; {currentQuestion.points || 1} Poin
                      </Badge>
                    </div>
                  </div>

                  {/* Question Text */}
                  <div
                    className="text-lg sm:text-xl font-semibold text-text leading-relaxed select-text"
                    dangerouslySetInnerHTML={{
                      __html: renderMixedText(currentQuestion.question_text || 'Teks soal...'),
                    }}
                  />

                  {/* Media (Image / Audio / Video) */}
                  {currentQuestion.img_url && (
                    <div className="rounded-xl overflow-hidden border border-border bg-bg-secondary p-2 flex justify-center">
                      <img
                        src={resolveMediaUrl(currentQuestion.img_url)}
                        alt="Gambar Soal"
                        className="max-h-72 w-auto object-contain rounded-lg"
                      />
                    </div>
                  )}

                  {currentQuestion.audio_url && (
                    <audio
                      src={resolveMediaUrl(currentQuestion.audio_url)}
                      controls
                      className="w-full"
                    />
                  )}

                  {currentQuestion.video_url && (
                    <video
                      src={resolveMediaUrl(currentQuestion.video_url)}
                      controls
                      className="w-full max-h-72 rounded-xl"
                    />
                  )}

                  {/* Answer Input Area */}
                  <div className="pt-2">
                    <TakeQuestionAnswerArea
                      question={currentQuestion}
                      value={answers[currentQuestion.id]}
                      onChange={handleSetAnswer}
                      accent={accent}
                    />
                  </div>
                </Card>

                {/* Bottom Navigation Buttons: Previous | Ragu-Ragu | Next */}
                <div className="sticky bottom-4 z-20 flex items-center justify-between gap-2 sm:gap-4 rounded-2xl bg-surface/95 backdrop-blur-md p-3 border border-border shadow-lg">
                  {/* 1. PREVIOUS BUTTON */}
                  <Button
                    type="button"
                    variant="outline"
                    size="md"
                    disabled={currentIndex === 0}
                    onClick={() => setCurrentIndex((prev) => prev - 1)}
                    className="gap-1.5 text-xs sm:text-sm font-semibold min-w-[90px] sm:min-w-[120px]"
                  >
                    <ChevronLeft size={16} />
                    <span>Sebelumnya</span>
                  </Button>

                  {/* 2. RAGU-RAGU BUTTON (CENTER) */}
                  <button
                    type="button"
                    onClick={handleToggleFlag}
                    className={cn(
                      'flex items-center justify-center gap-1.5 px-3 sm:px-5 py-2 rounded-xl text-xs sm:text-sm font-bold transition-all border shadow-sm',
                      flagged[currentQuestion.id]
                        ? 'bg-amber-500 text-white border-amber-600 shadow-amber-500/20'
                        : 'bg-amber-500/10 text-amber-600 border-amber-500/30 hover:bg-amber-500/20'
                    )}
                  >
                    <Flag
                      size={15}
                      fill={flagged[currentQuestion.id] ? 'currentColor' : 'none'}
                    />
                    <span>Ragu - Ragu</span>
                  </button>

                  {/* 3. NEXT / SUBMIT BUTTON */}
                  {currentIndex === questions.length - 1 ? (
                    <Button
                      type="button"
                      size="md"
                      onClick={() => setShowSubmitModal(true)}
                      className="gap-1.5 text-xs sm:text-sm font-semibold min-w-[90px] sm:min-w-[120px] text-white shadow-md"
                      style={{ backgroundColor: '#059669' }}
                    >
                      <span>Kumpulkan</span>
                      <Send size={15} />
                    </Button>
                  ) : (
                    <Button
                      type="button"
                      size="md"
                      onClick={() => setCurrentIndex((prev) => prev + 1)}
                      className="gap-1.5 text-xs sm:text-sm font-semibold min-w-[90px] sm:min-w-[120px] text-white shadow-md"
                      style={{ backgroundColor: accent }}
                    >
                      <span>Selanjutnya</span>
                      <ChevronRight size={16} />
                    </Button>
                  )}
                </div>
              </>
            )}
          </div>
        )}

        {/* ================= STAGE 4: SUBMITTED SUCCESS ================= */}
        {currentStage === 'COMPLETED' && (
          <div className="max-w-md w-full mx-auto my-auto animate-fadeIn text-center">
            <Card className="flex flex-col items-center gap-5 p-8 border-emerald-500/20 shadow-lg">
              <div className="flex h-20 w-20 items-center justify-center rounded-full bg-emerald-500/10 text-emerald-500 border-2 border-emerald-500/30 shadow-inner">
                <CheckCircle2 size={44} />
              </div>

              <div>
                <h2 className="text-xl font-bold text-text">Ujian Telah Selesai!</h2>
                <p className="text-xs text-text-secondary mt-1 max-w-xs mx-auto leading-relaxed">
                  Terima kasih telah menyelesaikan form ujian <strong>{form.title}</strong>. Jawaban kamu telah tersimpan dengan aman.
                </p>
              </div>

              {submissionResult && (
                <div className="w-full rounded-xl bg-bg-secondary p-4 border border-border flex flex-col gap-2 text-xs">
                  <div className="flex justify-between text-text-secondary">
                    <span>Soal Dijawab:</span>
                    <strong className="text-text font-mono">
                      {submissionResult.answered} / {submissionResult.total}
                    </strong>
                  </div>
                  <div className="flex justify-between text-text-secondary">
                    <span>Waktu Selesai:</span>
                    <strong className="text-text font-mono">
                      {new Date(submissionResult.submittedAt).toLocaleTimeString()}
                    </strong>
                  </div>
                </div>
              )}

              <Button
                type="button"
                variant="primary"
                size="lg"
                onClick={() => navigate('/dashboard')}
                className="w-full justify-center font-semibold shadow-md"
              >
                Kembali ke Dashboard
              </Button>
            </Card>
          </div>
        )}
      </main>

      {/* ================= MODAL: LIHAT SEMUA SOAL (QUESTION MATRIX) ================= */}
      {showMatrixModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-fadeIn">
          <div className="w-full max-w-lg rounded-2xl border border-border bg-surface shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b border-border px-5 py-4">
              <div className="flex items-center gap-2">
                <Grid size={18} className="text-primary" />
                <h3 className="font-bold text-text text-base">Kisi-Kisi Soal Ujian</h3>
              </div>
              <button
                type="button"
                onClick={() => setShowMatrixModal(false)}
                className="rounded-lg p-1.5 text-text-secondary hover:bg-bg-secondary hover:text-text transition-colors"
              >
                <X size={18} />
              </button>
            </div>

            {/* Matrix Legend */}
            <div className="flex flex-wrap items-center justify-center gap-3 bg-bg-secondary px-4 py-2.5 border-b border-border text-[11px] font-medium text-text-secondary">
              <div className="flex items-center gap-1.5">
                <span className="h-3.5 w-3.5 rounded bg-emerald-500 text-white flex items-center justify-center text-[9px] font-bold">✓</span>
                <span>Sudah Dijawab ({answeredCount})</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="h-3.5 w-3.5 rounded bg-amber-500 text-white flex items-center justify-center text-[9px]">
                  <Flag size={9} fill="currentColor" />
                </span>
                <span>Ragu-Ragu ({flaggedCount})</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="h-3.5 w-3.5 rounded border border-border bg-surface" />
                <span>Belum ({unansweredCount})</span>
              </div>
            </div>

            {/* Matrix Grid of Numbers */}
            <div className="flex-1 overflow-y-auto p-5">
              <div className="grid grid-cols-5 sm:grid-cols-6 gap-2.5">
                {questions.map((q, idx) => {
                  const isCurrent = idx === currentIndex;
                  const isFlagged = Boolean(flagged[q.id]);
                  const isAnswered =
                    answers[q.id] !== undefined &&
                    answers[q.id] !== '' &&
                    (!Array.isArray(answers[q.id]) || answers[q.id].length > 0);

                  return (
                    <button
                      key={q.id || idx}
                      type="button"
                      onClick={() => {
                        setCurrentIndex(idx);
                        setShowMatrixModal(false);
                      }}
                      className={cn(
                        'relative flex flex-col items-center justify-center h-12 rounded-xl text-xs font-bold transition-all shadow-sm',
                        isCurrent && 'ring-2 ring-primary ring-offset-2 ring-offset-surface',
                        isFlagged
                          ? 'bg-amber-500 text-white shadow-amber-500/20'
                          : isAnswered
                          ? 'bg-emerald-600 text-white shadow-emerald-500/20'
                          : 'bg-bg-secondary text-text border border-border hover:border-primary/50'
                      )}
                    >
                      <span className="text-sm font-bold">{idx + 1}</span>
                      {isFlagged && (
                        <Flag
                          size={10}
                          fill="currentColor"
                          className="absolute top-1 right-1"
                        />
                      )}
                      {isAnswered && !isFlagged && (
                        <span className="text-[9px] font-normal opacity-90">Terisi</span>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Modal Footer */}
            <div className="border-t border-border px-5 py-3.5 bg-bg-secondary flex justify-end">
              <Button
                type="button"
                variant="primary"
                size="sm"
                onClick={() => setShowMatrixModal(false)}
              >
                Tutup Kisi-Kisi
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* ================= MODAL: SUBMISSION CONFIRMATION ================= */}
      {showSubmitModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-fadeIn">
          <div className="w-full max-w-md rounded-2xl border border-border bg-surface p-6 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-500/10 text-emerald-600">
                <HelpCircle size={26} />
              </div>
              <div>
                <h3 className="font-bold text-text text-base">Kumpulkan Lembar Jawaban?</h3>
                <p className="text-xs text-text-secondary mt-0.5">
                  Pastikan kamu sudah memeriksa semua jawaban sebelum mengumpulkan.
                </p>
              </div>
            </div>

            {/* Summary Statistics */}
            <div className="rounded-xl bg-bg-secondary p-4 border border-border flex flex-col gap-2 text-xs">
              <div className="flex justify-between">
                <span className="text-text-secondary">Total Soal:</span>
                <strong className="text-text font-bold">{questions.length}</strong>
              </div>
              <div className="flex justify-between">
                <span className="text-emerald-600 font-medium">Sudah Dijawab:</span>
                <strong className="text-emerald-600 font-bold">{answeredCount}</strong>
              </div>
              {flaggedCount > 0 && (
                <div className="flex justify-between text-amber-600">
                  <span className="font-medium">Masih Ragu-Ragu:</span>
                  <strong className="font-bold">{flaggedCount}</strong>
                </div>
              )}
              {unansweredCount > 0 && (
                <div className="flex justify-between text-red-500">
                  <span className="font-medium">Belum Dijawab:</span>
                  <strong className="font-bold">{unansweredCount}</strong>
                </div>
              )}
            </div>

            {(flaggedCount > 0 || unansweredCount > 0) && (
              <div className="rounded-lg bg-amber-500/10 p-3 border border-amber-500/20 text-xs text-amber-600 flex items-center gap-2">
                <AlertCircle size={15} className="shrink-0" />
                <span>
                  Masih ada {unansweredCount > 0 ? `${unansweredCount} soal kosong` : ''}
                  {unansweredCount > 0 && flaggedCount > 0 ? ' dan ' : ''}
                  {flaggedCount > 0 ? `${flaggedCount} soal bertanda ragu-ragu` : ''}.
                </span>
              </div>
            )}

            <div className="flex gap-2 justify-end pt-2">
              <Button
                type="button"
                variant="outline"
                onClick={() => setShowSubmitModal(false)}
                disabled={submitting}
              >
                Periksa Kembali
              </Button>
              <Button
                type="button"
                variant="primary"
                onClick={handleFinalSubmit}
                loading={submitting}
                className="bg-emerald-600 hover:bg-emerald-700 text-white font-semibold"
              >
                Ya, Kumpulkan Sekarang
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Anti-cheat Fullscreen Overlay Guard (Strike 1 & 2) */}
      {showGuardOverlay && !isBlocked && (
        <div
          onClick={handleDismissGuard}
          className="fixed inset-0 z-[9999] bg-black/90 backdrop-blur-md flex flex-col items-center justify-center p-6 text-center cursor-pointer select-none animate-in fade-in duration-150"
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className={cn(
              'max-w-lg w-full rounded-3xl p-8 border-2 shadow-2xl transition-all',
              strikes >= 2
                ? 'bg-gradient-to-b from-red-950 to-slate-900 border-red-600 text-white shadow-red-900/50 animate-pulse'
                : 'bg-slate-900 border-amber-500 text-white shadow-amber-900/40'
            )}
          >
            <div
              className={cn(
                'flex h-20 w-20 items-center justify-center rounded-3xl mx-auto mb-4 border',
                strikes >= 2
                  ? 'bg-red-500/20 text-red-500 border-red-500/30'
                  : 'bg-amber-500/20 text-amber-500 border-amber-500/30'
              )}
            >
              <ShieldAlert size={44} />
            </div>

            <div className="space-y-2 mb-6">
              <span
                className={cn(
                  'inline-block px-3 py-1 rounded-full text-xs font-black uppercase tracking-wider',
                  strikes >= 2 ? 'bg-red-600 text-white' : 'bg-amber-500 text-black font-extrabold'
                )}
              >
                {strikes >= 2 ? 'Peringatan Keras (Ke-2)' : 'Peringatan Pelanggaran (Ke-1)'}
              </span>
              <h2 className="text-2xl font-black">
                {strikes >= 2 ? 'Terindikasi Kecurangan!' : 'Keluar dari Mode Ujian!'}
              </h2>
              <p className="text-sm text-slate-300 leading-relaxed">{guardReason}</p>
            </div>

            <div className="bg-black/40 rounded-2xl p-4 border border-white/10 mb-6">
              <p className="text-xs text-slate-400 mb-2">Kembali ke layar penuh otomatis dalam:</p>
              <div className="text-4xl font-black text-amber-400 font-mono tracking-wider">
                {guardCountdown}s
              </div>
              <p className="text-[11px] text-slate-400 mt-2">
                Sentuh atau klik layar sekarang untuk langsung melanjutkan ujian.
              </p>
            </div>

            <Button
              type="button"
              variant="primary"
              onClick={handleDismissGuard}
              className={cn(
                'w-full py-3.5 text-base font-bold rounded-xl shadow-lg transition-transform active:scale-95',
                strikes >= 2
                  ? 'bg-red-600 hover:bg-red-700 text-white'
                  : 'bg-amber-500 hover:bg-amber-600 text-black'
              )}
            >
              <Maximize2 size={18} className="mr-2" />
              Masuk Layar Penuh &amp; Lanjutkan Ujian
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}

/* ================= QUESTION ANSWER AREA COMPONENT ================= */
function TakeQuestionAnswerArea({ question, value, onChange, accent }) {
  const type = question.question_type;

  if (type === 'SHORT_TEXT') {
    return (
      <input
        className="w-full rounded-xl border border-border bg-bg-secondary px-4 py-3 text-base text-text transition-all focus:border-primary focus:bg-surface focus:outline-none"
        placeholder="Ketik jawaban singkat kamu di sini..."
        value={value || ''}
        onChange={(e) => onChange(e.target.value)}
      />
    );
  }

  if (type === 'LONG_TEXT' || type === 'CODE') {
    return (
      <textarea
        className="w-full rounded-xl border border-border bg-bg-secondary px-4 py-3 text-base text-text transition-all focus:border-primary focus:bg-surface focus:outline-none leading-relaxed"
        rows={6}
        placeholder={
          type === 'CODE'
            ? 'Ketik kode program jawaban kamu di sini...'
            : 'Ketik jawaban lengkap / uraian kamu di sini...'
        }
        value={value || ''}
        onChange={(e) => onChange(e.target.value)}
      />
    );
  }

  if (type === 'MATCHING') {
    return (
      <div className="flex flex-col gap-2.5 text-base">
        {question.options?.map((o) => (
          <div
            key={o.id}
            className="flex items-center justify-between gap-3 rounded-xl border border-border p-3.5 bg-bg-secondary"
          >
            <span className="font-semibold text-text">{o.option_text}</span>
            <span className="text-primary font-bold">&harr;</span>
            <span className="text-text-secondary">{o.match_target_text}</span>
          </div>
        ))}
      </div>
    );
  }

  if (type === 'RATING') {
    return (
      <div className="flex gap-3 justify-center py-4">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            type="button"
            onClick={() => onChange(n)}
            className="flex h-12 w-12 items-center justify-center rounded-2xl border text-lg font-bold transition-all shadow-sm"
            style={
              value === n
                ? { backgroundColor: accent, color: '#fff', borderColor: accent }
                : { borderColor: 'var(--border)', backgroundColor: 'var(--surface)' }
            }
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
      <div className="flex flex-col gap-2.5">
        {question.options?.map((o, idx) => {
          const isSelected = selected.includes(o.id);
          const letter = String.fromCharCode(65 + idx);
          return (
            <label
              key={o.id}
              className={cn(
                'flex items-start gap-3.5 rounded-2xl border p-4 text-base cursor-pointer transition-all shadow-sm',
                isSelected
                  ? 'border-primary bg-primary/10 font-semibold'
                  : 'border-border bg-surface hover:bg-bg-secondary'
              )}
            >
              <div className="flex items-center gap-2 pt-0.5">
                <input
                  type="checkbox"
                  checked={isSelected}
                  onChange={() =>
                    onChange(
                      isSelected ? selected.filter((id) => id !== o.id) : [...selected, o.id]
                    )
                  }
                  className="rounded text-primary focus:ring-primary h-4.5 w-4.5"
                />
                <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-bg-secondary text-xs font-bold text-text border border-border">
                  {letter}
                </span>
              </div>
              <div className="flex-1 min-w-0 pt-0.5 text-text">
                <span dangerouslySetInnerHTML={{ __html: renderMixedText(o.option_text) }} />
              </div>
            </label>
          );
        })}
      </div>
    );
  }

  // MULTIPLE_CHOICE, YES_NO, etc.
  if (question.options?.length) {
    return (
      <div className="flex flex-col gap-2.5">
        {question.options.map((o, idx) => {
          const isSelected = value === o.id;
          const letter = String.fromCharCode(65 + idx);
          return (
            <label
              key={o.id}
              className={cn(
                'flex items-start gap-3.5 rounded-2xl border p-4 text-base cursor-pointer transition-all shadow-sm',
                isSelected
                  ? 'border-primary bg-primary/10 font-semibold'
                  : 'border-border bg-surface hover:bg-bg-secondary'
              )}
            >
              <div className="flex items-center gap-2 pt-0.5">
                <input
                  type="radio"
                  name={question.id}
                  checked={isSelected}
                  onChange={() => onChange(o.id)}
                  className="text-primary focus:ring-primary h-4.5 w-4.5"
                />
                <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-bg-secondary text-xs font-bold text-text border border-border">
                  {letter}
                </span>
              </div>
              <div className="flex-1 min-w-0 pt-0.5 text-text">
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
      className="w-full rounded-xl border border-border bg-bg-secondary px-4 py-3 text-base text-text focus:border-primary focus:bg-surface focus:outline-none"
      placeholder="Ketik jawabanmu..."
      value={value || ''}
      onChange={(e) => onChange(e.target.value)}
    />
  );
}
