import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Sparkles, Save, ChevronDown, ChevronUp, Loader2 } from 'lucide-react';
import { responseApi, aiApi } from '../../lib/api';
import { Card, Input, Button, EmptyState, FullPageSpinner, Pagination, Badge } from '../../shared/ui';
import { useToast } from '../../shared/Toast';

const LIMIT = 20;

export default function GradingTab({ formId }) {
  const [offset, setOffset] = useState(0);
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['form-responses', formId, offset],
    queryFn: () => responseApi.listByForm(formId, { limit: LIMIT, offset }),
  });

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['form-responses', formId] });

  if (isLoading) return <FullPageSpinner />;
  if (!data?.items?.length) {
    return <EmptyState title="Belum ada jawaban untuk dinilai" />;
  }

  return (
    <div className="flex flex-col gap-2">
      <p className="text-sm text-text-secondary">
        Nilai esai otomatis pakai AI (perbandingan makna jawaban vs kunci), atau timpa manual skor totalnya.
      </p>
      {data.items.map((r) => (
        <ResponseGradeCard key={r.id} response={r} onGraded={invalidate} />
      ))}
      <Pagination total={data.total} limit={data.limit} offset={data.offset} onChange={setOffset} />
    </div>
  );
}

function ResponseGradeCard({ response, onGraded }) {
  const [expanded, setExpanded] = useState(false);
  const [scoreDraft, setScoreDraft] = useState(response.total_score ?? 0);
  const [saving, setSaving] = useState(false);
  const [aiGrading, setAiGrading] = useState(false);
  const [aiResult, setAiResult] = useState(null);
  const toast = useToast();

  const essayAnswers = response.answers?.filter((a) => a.is_correct === null || a.is_correct === undefined) || [];

  const handleSaveScore = async () => {
    setSaving(true);
    try {
      await responseApi.grade(response.id, { total_score: Number(scoreDraft) || 0 });
      toast.success('Skor disimpan');
      onGraded();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleAiGrade = async () => {
    setAiGrading(true);
    try {
      const result = await aiApi.gradeResponse({ response_id: response.id, auto_persist: true });
      setAiResult(result);
      if (result.mock) {
        toast.info('AI berjalan dalam mode simulasi (GEMINI_API_KEY belum diisi di backend).');
      } else {
        toast.success(`Penilaian AI selesai, +${result.total_added} poin ditambahkan`);
      }
      onGraded();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setAiGrading(false);
    }
  };

  return (
    <Card className="!p-0 overflow-hidden">
      <button onClick={() => setExpanded((e) => !e)} className="flex w-full items-center justify-between gap-3 px-4 py-3 text-left">
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-medium text-text">{response.respondent_email}</p>
          <p className="text-xs text-text-secondary">{essayAnswers.length} jawaban esai</p>
        </div>
        <Badge>{response.total_score != null ? `${response.total_score} poin` : 'Belum dinilai'}</Badge>
        {expanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
      </button>

      {expanded && (
        <div className="flex flex-col gap-3 border-t border-border px-4 py-3">
          {essayAnswers.map((a) => {
            const answerKey = a.question?.answer_key || a.answer_key;
            return (
              <div key={a.id} className="rounded-xl bg-bg-secondary p-3.5 border border-border flex flex-col gap-2">
                <div>
                  <span className="text-[11px] font-semibold text-primary uppercase tracking-wider">Soal Esai:</span>
                  <p className="text-sm font-medium text-text mt-0.5">{a.question_text || a.question?.question_text}</p>
                </div>

                {answerKey && (
                  <div className="rounded-lg bg-emerald-500/10 border border-emerald-500/20 p-2.5 text-xs text-emerald-700 dark:text-emerald-400">
                    <span className="font-semibold block">Kunci Jawaban Acuan:</span>
                    <span className="mt-0.5 block whitespace-pre-wrap">{answerKey}</span>
                  </div>
                )}

                <div className="rounded-lg bg-surface border border-border p-2.5 text-xs">
                  <span className="font-semibold text-text-secondary block">Jawaban Murid:</span>
                  <span className="mt-0.5 block text-text whitespace-pre-wrap">{a.answer_text || '(tidak dijawab)'}</span>
                </div>

                {a.score_given != null && (
                  <div className="flex items-center justify-between text-xs pt-1">
                    <span className="text-text-secondary">Skor yang Diberikan:</span>
                    <strong className="text-primary font-bold">{a.score_given} Poin</strong>
                  </div>
                )}
              </div>
            );
          })}

          {aiResult && (
            <div className="rounded-lg border border-primary/30 bg-primary/5 p-3 text-sm">
              <p className="font-medium text-primary">Hasil Penilaian AI</p>
              <ul className="mt-1.5 space-y-1 text-text-secondary">
                {aiResult.items?.map((item) => (
                  <li key={item.question_id}>
                    {item.score}/{item.max_points} — {item.feedback}
                  </li>
                ))}
              </ul>
            </div>
          )}

          <div className="flex flex-wrap items-center gap-2 pt-1">
            <Button variant="outline" size="sm" onClick={handleAiGrade} loading={aiGrading}>
              <Sparkles size={14} />
              Nilai Otomatis dengan AI
            </Button>
            <div className="ml-auto flex items-center gap-2">
              <Input
                type="number"
                value={scoreDraft}
                onChange={(e) => setScoreDraft(e.target.value)}
                className="w-24"
              />
              <Button size="sm" onClick={handleSaveScore} loading={saving}>
                <Save size={14} />
                Simpan Skor
              </Button>
            </div>
          </div>
        </div>
      )}
    </Card>
  );
}
