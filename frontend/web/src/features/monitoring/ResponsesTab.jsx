import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChevronDown, ChevronUp } from 'lucide-react';
import { responseApi } from '../../lib/api';
import { Card, EmptyState, FullPageSpinner, Pagination, Badge } from '../../shared/ui';
import { formatDate, cn } from '../../lib/utils';

const LIMIT = 25;

function formatStudentAnswer(a) {
  if (a.selected_option || a.selected_option_text) {
    return a.selected_option || a.selected_option_text;
  }
  if (a.match_pair_json) {
    try {
      const pairs = JSON.parse(a.match_pair_json);
      if (Array.isArray(pairs) && pairs.length > 0) {
        return pairs.map((p) => `${p.match_key} ↔ ${p.match_target_text}`).join(', ');
      }
    } catch {
      // ignore
    }
  }
  if (a.answer_text && String(a.answer_text).trim() !== '') {
    return a.answer_text;
  }
  return '(tidak dijawab)';
}

export default function ResponsesTab({ formId }) {
  const [offset, setOffset] = useState(0);
  const [expandedId, setExpandedId] = useState(null);

  const { data, isLoading } = useQuery({
    queryKey: ['form-responses', formId, offset],
    queryFn: () => responseApi.listByForm(formId, { limit: LIMIT, offset }),
  });

  if (isLoading) return <FullPageSpinner />;
  if (!data?.items?.length) {
    return <EmptyState title="Belum ada respons masuk" description="Daftar akan muncul begitu siswa menyelesaikan ujian" />;
  }

  return (
    <div className="flex flex-col gap-2">
      {data.items.map((r) => {
        const expanded = expandedId === r.id;
        return (
          <Card key={r.id} className="!p-0 overflow-hidden">
            <button
              onClick={() => setExpandedId(expanded ? null : r.id)}
              className="flex w-full items-center justify-between gap-3 px-4 py-3 text-left"
            >
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-text">{r.respondent_email}</p>
                <p className="text-xs text-text-secondary">Selesai {formatDate(r.submitted_at)}</p>
              </div>
              <div className="flex shrink-0 items-center gap-2">
                {r.is_auto_submitted && <Badge className="bg-warning/15 text-warning">Auto-submit</Badge>}
                <Badge>{r.total_score != null ? `${r.total_score} poin` : 'Belum dinilai'}</Badge>
                {expanded ? <ChevronUp size={16} className="text-text-secondary" /> : <ChevronDown size={16} className="text-text-secondary" />}
              </div>
            </button>
            {expanded && (
              <div className="border-t border-border px-4 py-3">
                <div className="flex flex-col gap-3">
                  {r.answers?.map((a, i) => (
                    <div key={a.id} className="rounded-lg bg-bg-secondary p-3">
                      <p className="text-sm font-medium text-text">
                        {i + 1}. {a.question_text || `Soal ${i + 1}`}
                      </p>
                      <p className="mt-1 text-sm text-text-secondary">
                        <strong className="text-text font-semibold">Jawaban:</strong>{' '}
                        <span className="text-text">{formatStudentAnswer(a)}</span>
                      </p>
                      <div className="mt-2 flex items-center gap-2 text-xs">
                        {a.is_correct != null && (
                          <span
                            className={cn(
                              'font-bold px-2 py-0.5 rounded-md',
                              a.is_correct
                                ? 'bg-success/15 text-success'
                                : 'bg-danger/15 text-danger'
                            )}
                          >
                            {a.is_correct ? 'Benar' : 'Salah'}
                          </span>
                        )}
                        <span className="font-semibold text-text-secondary">
                          {a.points_earned ?? a.score_given ?? 0} poin
                        </span>
                        {a.is_flagged && (
                          <span className="text-amber-500 font-medium">
                            &middot; Ditandai ragu-ragu
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </Card>
        );
      })}
      <Pagination total={data.total} limit={data.limit} offset={data.offset} onChange={setOffset} />
    </div>
  );
}
