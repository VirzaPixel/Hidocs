import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { AlertTriangle, RotateCcw, Wifi, WifiOff } from 'lucide-react';
import { responseApi } from '../../lib/api';
import { Card, Badge, EmptyState, Spinner, Button } from '../../shared/ui';
import { ConfirmDialog } from '../../shared/Modal';
import { useToast } from '../../shared/Toast';
import { timeAgo } from '../../lib/utils';

const POLL_INTERVAL_MS = 8000; // jangan terlalu agresif — bisa ada 800-1000 siswa aktif

export default function LiveTab({ formId }) {
  const [restartTarget, setRestartTarget] = useState(null);
  const [restarting, setRestarting] = useState(false);
  const toast = useToast();
  const queryClient = useQueryClient();

  const { data: students, isLoading } = useQuery({
    queryKey: ['live-monitoring', formId],
    queryFn: () => responseApi.liveMonitoring(formId),
    refetchInterval: POLL_INTERVAL_MS,
  });

  const handleRestart = async () => {
    setRestarting(true);
    try {
      await responseApi.restartSession(formId, restartTarget.response_id);
      toast.success(`Sesi ${restartTarget.respondent_email} telah direset`);
      queryClient.invalidateQueries({ queryKey: ['live-monitoring', formId] });
      setRestartTarget(null);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setRestarting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <Spinner size={28} className="text-primary" />
      </div>
    );
  }

  if (!students?.length) {
    return <EmptyState title="Belum ada siswa yang mengerjakan" description="Data akan muncul begitu siswa mulai login lewat aplikasi mobile" />;
  }

  const isStale = (lastHeartbeat) => Date.now() - new Date(lastHeartbeat).getTime() > 60000;

  return (
    <div className="flex flex-col gap-3">
      <p className="text-xs text-text-secondary">Otomatis diperbarui tiap {POLL_INTERVAL_MS / 1000} detik &middot; {students.length} siswa</p>
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {students.map((s) => {
          const stale = isStale(s.last_heartbeat);
          return (
            <Card key={s.response_id} className={s.is_suspicious ? 'border-danger/40' : undefined}>
              <div className="flex items-start justify-between gap-2">
                <p className="min-w-0 flex-1 truncate text-sm font-medium text-text">{s.respondent_email}</p>
                {stale ? (
                  <WifiOff size={16} className="shrink-0 text-text-secondary" title="Tidak ada aktivitas > 1 menit" />
                ) : (
                  <Wifi size={16} className="shrink-0 text-success" title="Terhubung" />
                )}
              </div>

              <div className="mt-2 flex items-center gap-2">
                <Badge className={s.status === 'SUBMITTED' ? 'bg-success/15 text-success' : 'bg-primary/10 text-primary'}>
                  {s.status}
                </Badge>
                {s.is_suspicious && (
                  <Badge className="bg-danger/15 text-danger">
                    <AlertTriangle size={12} className="mr-1 inline" />
                    Mencurigakan
                  </Badge>
                )}
              </div>

              <div className="mt-3">
                <div className="mb-1 flex justify-between text-xs text-text-secondary">
                  <span>Progres</span>
                  <span>
                    {s.answered_count}/{s.total_questions} soal
                  </span>
                </div>
                <div className="h-1.5 w-full overflow-hidden rounded-full bg-bg-secondary">
                  <div
                    className="h-full rounded-full bg-primary"
                    style={{ width: `${s.total_questions ? (s.answered_count / s.total_questions) * 100 : 0}%` }}
                  />
                </div>
              </div>

              <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-text-secondary">
                <span>Tab switch: {s.tab_switch_count}</span>
                <span>Blur: {s.blur_count}</span>
                <span>Flag: {s.flagged_count}</span>
              </div>
              <p className="mt-1 text-xs text-text-secondary">Aktivitas terakhir: {timeAgo(s.last_heartbeat)}</p>
              {s.warning_message && <p className="mt-1 text-xs text-warning">{s.warning_message}</p>}

              <Button variant="outline" size="sm" className="mt-3 w-full" onClick={() => setRestartTarget(s)}>
                <RotateCcw size={14} />
                Reset Sesi
              </Button>
            </Card>
          );
        })}
      </div>

      <ConfirmDialog
        open={!!restartTarget}
        onClose={() => setRestartTarget(null)}
        onConfirm={handleRestart}
        loading={restarting}
        danger={false}
        confirmLabel="Reset Sesi"
        title="Reset sesi siswa ini?"
        description={`Progres pengerjaan ${restartTarget?.respondent_email} akan direset. Gunakan ini kalau siswa mengalami kendala teknis.`}
      />
    </div>
  );
}
