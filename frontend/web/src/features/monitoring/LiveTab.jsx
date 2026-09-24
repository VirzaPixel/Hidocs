import { useState, useEffect, useRef, useCallback } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  AlertTriangle,
  RotateCcw,
  Wifi,
  WifiOff,
  RefreshCw,
  Zap,
  ShieldAlert,
  CheckCircle2,
  Lock,
  LockOpen,
} from 'lucide-react';
import { responseApi } from '../../lib/api';
import { Card, Badge, EmptyState, Spinner, Button } from '../../shared/ui';
import { ConfirmDialog } from '../../shared/Modal';
import { useToast } from '../../shared/Toast';
import { timeAgo, cn } from '../../lib/utils';
import { TOKEN_KEY } from '../../lib/apiClient';

const POLL_INTERVAL_MS = 10000;

function getWebSocketUrl(formId) {
  const token = localStorage.getItem(TOKEN_KEY) || '';
  const isHttps = window.location.protocol === 'https:';
  const wsProtocol = isHttps ? 'wss:' : 'ws:';
  let host = window.location.host;

  if (import.meta.env.VITE_API_BASE_URL && import.meta.env.VITE_API_BASE_URL.startsWith('http')) {
    try {
      const u = new URL(import.meta.env.VITE_API_BASE_URL);
      host = u.host;
    } catch {
      // ignore
    }
  }

  return `${wsProtocol}//${host}/api/v1/ws/forms/${formId}/live?token=${encodeURIComponent(token)}`;
}

export default function LiveTab({ formId }) {
  const [restartTarget, setRestartTarget] = useState(null);
  const [restarting, setRestarting] = useState(false);
  const [wsConnected, setWsConnected] = useState(false);
  const toast = useToast();
  const queryClient = useQueryClient();
  const wsRef = useRef(null);
  const reconnectTimeoutRef = useRef(null);

  const {
    data: students,
    isLoading,
    refetch,
  } = useQuery({
    queryKey: ['live-monitoring', formId],
    queryFn: () => responseApi.liveMonitoring(formId),
    refetchInterval: wsConnected ? false : POLL_INTERVAL_MS, // Poll only if WebSocket is disconnected
  });

  // Handle incoming real-time WebSocket event
  const handleWsEvent = useCallback(
    (eventData) => {
      try {
        const payload = typeof eventData === 'string' ? JSON.parse(eventData) : eventData;
        const { event, data } = payload;

        if (event === 'CONNECTED') {
          setWsConnected(true);
          return;
        }

        // Trigger react-query cache update or invalidate to sync student list
        queryClient.invalidateQueries({ queryKey: ['live-monitoring', formId] });

        if (event === 'STUDENT_SUBMIT' && data?.respondent_email) {
          toast.info(`Peserta ${data.respondent_email} baru saja menyelesaikan ujian.`);
        }
      } catch (err) {
        console.error('Failed to parse WS message:', err);
      }
    },
    [formId, queryClient, toast]
  );

  // Establish and maintain WebSocket connection
  useEffect(() => {
    if (!formId) return;

    let isMounted = true;

    function connectWs() {
      try {
        const wsUrl = getWebSocketUrl(formId);
        const ws = new WebSocket(wsUrl);
        wsRef.current = ws;

        ws.onopen = () => {
          if (isMounted) setWsConnected(true);
        };

        ws.onmessage = (event) => {
          if (isMounted) handleWsEvent(event.data);
        };

        ws.onerror = () => {
          if (isMounted) setWsConnected(false);
        };

        ws.onclose = () => {
          if (isMounted) {
            setWsConnected(false);
            // Reconnect after 4s
            reconnectTimeoutRef.current = setTimeout(connectWs, 4000);
          }
        };
      } catch (e) {
        if (isMounted) setWsConnected(false);
      }
    }

    connectWs();

    return () => {
      isMounted = false;
      if (reconnectTimeoutRef.current) clearTimeout(reconnectTimeoutRef.current);
      if (wsRef.current) {
        wsRef.current.close();
        wsRef.current = null;
      }
    };
  }, [formId, handleWsEvent]);

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

  const isStale = (lastHeartbeat) => Date.now() - new Date(lastHeartbeat).getTime() > 60000;

  return (
    <div className="flex flex-col gap-4">
      {/* Top Status & Controls Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-border bg-surface p-3.5 shadow-sm">
        <div className="flex items-center gap-3">
          <div
            className={cn(
              'flex h-9 w-9 items-center justify-center rounded-xl shadow-sm transition-colors',
              wsConnected ? 'bg-emerald-500/10 text-emerald-600' : 'bg-amber-500/10 text-amber-600'
            )}
          >
            {wsConnected ? <Zap size={18} /> : <WifiOff size={18} />}
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-xs font-bold text-text">Live Monitoring Peserta</h3>
              <Badge
                className={cn(
                  'text-[10px] font-semibold flex items-center gap-1 py-0.5 px-2 rounded-full border',
                  wsConnected
                    ? 'bg-emerald-500/10 text-emerald-600 border-emerald-500/30'
                    : 'bg-amber-500/10 text-amber-600 border-amber-500/30'
                )}
              >
                <span
                  className={cn(
                    'h-1.5 w-1.5 rounded-full animate-pulse',
                    wsConnected ? 'bg-emerald-500' : 'bg-amber-500'
                  )}
                />
                {wsConnected ? 'Real-Time (WebSocket Aktif)' : 'Polling Cadangan (10s)'}
              </Badge>
            </div>
            <p className="text-[11px] text-text-secondary mt-0.5">
              {students?.length || 0} peserta terdata dalam sesi ujian
            </p>
          </div>
        </div>

        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={() => refetch()}
          className="gap-1.5 text-xs font-medium"
        >
          <RefreshCw size={13} />
          <span>Refresh Data</span>
        </Button>
      </div>

      {/* Alert banner if any students are blocked */}
      {students?.some((s) => s.status === 'BLOCKED') && (
        <div className="flex items-start gap-3.5 p-4 rounded-2xl bg-red-500/10 border-2 border-red-500/40 text-red-600 dark:text-red-400 shadow-sm animate-pulse">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-red-500/20 text-red-500">
            <Lock size={20} />
          </div>
          <div className="flex-1 min-w-0">
            <h4 className="text-sm font-bold">
              Perhatian: Ada Siswa yang Terkunci Karena Melanggar Layar Penuh!
            </h4>
            <p className="text-xs text-text-secondary mt-0.5 leading-relaxed">
              Siswa dengan kartu bertanda merah di bawah tidak dapat melanjutkan ujian karena layarnya terkunci.
              Klik tombol hijau <strong>"🔓 Buka Kunci &amp; Izinkan Lanjut Ujian"</strong> pada kartu siswa untuk mengizinkannya kembali.
            </p>
          </div>
        </div>
      )}

      {!students?.length ? (
        <EmptyState
          title="Belum ada siswa yang mengerjakan"
          description="Data aktivitas peserta akan muncul secara real-time saat siswa mulai membuka atau mengerjakan form ini."
        />
      ) : (
        <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-2 lg:grid-cols-3">
          {students.map((s) => {
            const stale = isStale(s.last_heartbeat);
            const isBlocked = s.status === 'BLOCKED';
            const isRestarted = s.status === 'RESTARTED' || (Boolean(s.warning_message) && !isBlocked);
            const isSubmitted = s.status === 'SUBMITTED';

            return (
              <Card
                key={s.response_id}
                className={cn(
                  'p-4 flex flex-col justify-between transition-all hover:shadow-md border rounded-2xl',
                  isBlocked
                    ? 'border-2 border-red-500 bg-red-500/[0.04] shadow-lg shadow-red-500/10 ring-2 ring-red-500/20'
                    : s.is_suspicious
                    ? 'border-danger/60 bg-danger/[0.02]'
                    : 'border-border'
                )}
              >
                <div>
                  <div className="flex items-start justify-between gap-2 border-b border-border/60 pb-2.5">
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-xs font-bold text-text" title={s.respondent_email}>
                        {s.respondent_email}
                      </p>
                      <p className="text-[10px] text-text-secondary mt-0.5">
                        Aktif: {timeAgo(s.last_heartbeat)}
                      </p>
                    </div>
                    {isBlocked ? (
                      <Badge className="bg-red-500/20 text-red-600 text-[10px] font-bold flex items-center gap-1 border border-red-500/30">
                        <Lock size={11} />
                        Terkunci
                      </Badge>
                    ) : stale ? (
                      <Badge className="bg-bg-secondary text-text-secondary text-[10px] flex items-center gap-1 border border-border">
                        <WifiOff size={11} />
                        Idle &gt;1m
                      </Badge>
                    ) : (
                      <Badge className="bg-emerald-500/10 text-emerald-600 text-[10px] flex items-center gap-1 border border-emerald-500/20">
                        <Wifi size={11} />
                        Online
                      </Badge>
                    )}
                  </div>

                  <div className="mt-2.5 flex flex-wrap items-center gap-2">
                    {isBlocked ? (
                      <Badge className="bg-red-600 text-white font-black text-[10px] px-2.5 py-1 tracking-wide shadow-sm flex items-center gap-1.5 animate-pulse">
                        <Lock size={12} />
                        <span>SESI TERKUNCI (MELANGGAR ATURAN)</span>
                      </Badge>
                    ) : isSubmitted ? (
                      <Badge className="bg-emerald-500/15 text-emerald-600 text-[10px] font-semibold uppercase px-2 py-0.5 rounded-md">
                        Selesai Mengerjakan
                      </Badge>
                    ) : isRestarted ? (
                      <Badge className="bg-emerald-500/15 text-emerald-700 dark:text-emerald-400 border border-emerald-500/30 font-bold text-[10px] flex items-center gap-1">
                        <CheckCircle2 size={12} />
                        <span>Kunci Terbuka (Menunggu Siswa)</span>
                      </Badge>
                    ) : (
                      <Badge className="bg-primary/10 text-primary text-[10px] font-semibold uppercase px-2 py-0.5 rounded-md">
                        Sedang Mengerjakan
                      </Badge>
                    )}

                    {s.is_suspicious && !isBlocked && (
                      <Badge className="bg-danger/15 text-danger text-[10px] font-bold border border-danger/30">
                        <AlertTriangle size={11} className="mr-1 inline" />
                        Mencurigakan
                      </Badge>
                    )}
                  </div>

                  {/* Informational Callout Box for Blocked or Restarted */}
                  {isBlocked && (
                    <div className="mt-3 rounded-xl bg-red-500/10 p-3 border border-red-500/30 text-xs text-red-600 dark:text-red-400">
                      <div className="flex items-center gap-1.5 font-bold mb-1">
                        <ShieldAlert size={14} className="shrink-0" />
                        <span>Izin Pengerjaan Dicabut</span>
                      </div>
                      <p className="text-[11px] text-text-secondary leading-relaxed">
                        Siswa keluar dari layar penuh / berpindah aplikasi sebanyak 3 kali. Klik tombol hijau di bawah untuk mengizinkan siswa melanjutkan.
                      </p>
                    </div>
                  )}

                  {isRestarted && !isBlocked && (
                    <div className="mt-3 rounded-xl bg-emerald-500/10 p-2.5 border border-emerald-500/30 text-xs text-emerald-600 dark:text-emerald-400 flex items-center gap-2">
                      <CheckCircle2 size={15} className="shrink-0" />
                      <span className="text-[11px] font-medium leading-relaxed">
                        Kunci sesi telah dibuka oleh pengawas.
                      </span>
                    </div>
                  )}

                  {/* Progress Bar */}
                  <div className="mt-3">
                    <div className="mb-1 flex justify-between text-[11px] text-text-secondary font-medium">
                      <span>Progres Jawaban</span>
                      <span className="text-text font-semibold">
                        {s.answered_count} / {s.total_questions} soal ({Math.round(s.total_questions ? (s.answered_count / s.total_questions) * 100 : 0)}%)
                      </span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-bg-secondary border border-border/40">
                      <div
                        className={cn(
                          'h-full rounded-full transition-all duration-300',
                          isBlocked ? 'bg-red-500' : 'bg-primary'
                        )}
                        style={{
                          width: `${s.total_questions ? (s.answered_count / s.total_questions) * 100 : 0}%`,
                        }}
                      />
                    </div>
                  </div>

                  {/* Telemetry badges */}
                  <div className="mt-3 flex flex-wrap gap-1.5 text-[11px]">
                    <span
                      className={cn(
                        'rounded-md px-2 py-0.5 border',
                        s.tab_switch_count > 0
                          ? 'bg-amber-500/10 border-amber-500/30 text-amber-600 font-bold'
                          : 'bg-bg-secondary border-border text-text-secondary'
                      )}
                    >
                      Tab switch: <strong className="text-text">{s.tab_switch_count}</strong>
                    </span>
                    <span
                      className={cn(
                        'rounded-md px-2 py-0.5 border',
                        s.blur_count > 0
                          ? 'bg-amber-500/10 border-amber-500/30 text-amber-600 font-bold'
                          : 'bg-bg-secondary border-border text-text-secondary'
                      )}
                    >
                      Keluar fokus: <strong className="text-text">{s.blur_count}</strong>
                    </span>
                    <span className="rounded-md bg-bg-secondary px-2 py-0.5 text-text-secondary border border-border">
                      Ragu: <strong className="text-text">{s.flagged_count}</strong>
                    </span>
                  </div>

                  {s.warning_message && !isBlocked && (
                    <div className="mt-2.5 rounded-lg bg-amber-500/10 p-2 text-[11px] text-amber-600 border border-amber-500/20">
                      <strong>Peringatan Pengawas:</strong> {s.warning_message}
                    </div>
                  )}
                </div>

                <div className="pt-3 mt-3 border-t border-border/60">
                  {isBlocked ? (
                    <Button
                      variant="primary"
                      size="sm"
                      className="w-full text-xs font-bold py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white shadow-md shadow-emerald-600/20 flex items-center justify-center gap-2 transition-all hover:scale-[1.01]"
                      onClick={() => setRestartTarget(s)}
                    >
                      <LockOpen size={15} />
                      <span>🔓 Buka Kunci &amp; Izinkan Lanjut Ujian</span>
                    </Button>
                  ) : isSubmitted ? (
                    <Button
                      variant="outline"
                      size="sm"
                      className="w-full text-xs font-medium text-text-secondary opacity-60 hover:opacity-100 hover:text-red-500 hover:border-red-300"
                      onClick={() => setRestartTarget(s)}
                    >
                      <RotateCcw size={12} className="mr-1" />
                      <span>Reset Ulang Ujian</span>
                    </Button>
                  ) : isRestarted ? (
                    <Button
                      variant="outline"
                      size="sm"
                      className="w-full text-xs font-semibold gap-1.5 text-emerald-600 border-emerald-500/30 hover:bg-emerald-50 hover:border-emerald-500"
                      onClick={() => setRestartTarget(s)}
                    >
                      <RotateCcw size={13} />
                      <span>Buka Ulang Kunci / Reset Lagi</span>
                    </Button>
                  ) : (
                    <Button
                      variant="outline"
                      size="sm"
                      className="w-full text-xs font-semibold gap-1.5 hover:bg-bg-secondary text-text-secondary hover:text-text"
                      onClick={() => setRestartTarget(s)}
                      title="Gunakan jika siswa mengalami error perangkat atau ingin mengulang."
                    >
                      <RotateCcw size={13} />
                      <span>Reset Sesi Siswa</span>
                    </Button>
                  )}
                </div>
              </Card>
            );
          })}
        </div>
      )}

      <ConfirmDialog
        open={!!restartTarget}
        onClose={() => setRestartTarget(null)}
        onConfirm={handleRestart}
        loading={restarting}
        danger={restartTarget?.status !== 'BLOCKED'}
        confirmLabel={
          restartTarget?.status === 'BLOCKED' ? 'Ya, Buka Kunci Siswa' : 'Reset Sesi'
        }
        title={
          restartTarget?.status === 'BLOCKED'
            ? 'Buka Kunci & Izinkan Siswa Lanjut Ujian?'
            : 'Reset Sesi Siswa Ini?'
        }
        description={
          restartTarget?.status === 'BLOCKED'
            ? `Siswa ${restartTarget?.respondent_email} akan diizinkan kembali melanjutkan ujian. Jawaban yang sudah tersimpan sebelumnya TIDAK AKAN HILANG dan hitungan pelanggaran akan direset ke 0.`
            : `Progres pengerjaan ${restartTarget?.respondent_email} akan diatur ulang. Gunakan ini kalau siswa mengalami kendala teknis.`
        }
      />
    </div>
  );
}
