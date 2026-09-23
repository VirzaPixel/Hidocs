import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Activity,
  Cpu,
  Radio,
  History,
  RefreshCw,
  Server,
  Zap,
  Users,
  AlertCircle,
  Database,
  CheckCircle2,
  XCircle,
  FileText,
} from 'lucide-react';
import { metricsApi } from '../../lib/api';
import { Card, Button, FullPageSpinner, Badge, Tabs, Select } from '../../shared/ui';
import { formatDate } from '../../lib/utils';

const METRIC_TABS = [
  { value: 'realtime', label: 'Telemetri Realtime' },
  { value: 'system', label: 'Performa Sistem' },
  { value: 'live-exams', label: 'Ujian Live' },
  { value: 'traffic-history', label: 'Riwayat Traffic' },
];

export default function AdminMetricsPage() {
  const [activeTab, setActiveTab] = useState('realtime');
  const [historyDuration, setHistoryDuration] = useState('1h');

  // Realtime Traffic Query
  const {
    data: realtimeData,
    isLoading: realtimeLoading,
    refetch: refetchRealtime,
  } = useQuery({
    queryKey: ['metrics-realtime'],
    queryFn: metricsApi.getRealtimeMetrics,
    refetchInterval: 3000,
  });

  // System Health Query
  const {
    data: systemData,
    isLoading: systemLoading,
    refetch: refetchSystem,
  } = useQuery({
    queryKey: ['metrics-system'],
    queryFn: metricsApi.getSystemMetrics,
    refetchInterval: 5000,
  });

  // Live Exams Query
  const {
    data: liveExams,
    isLoading: liveExamsLoading,
    refetch: refetchLiveExams,
  } = useQuery({
    queryKey: ['metrics-live-exams'],
    queryFn: metricsApi.getLiveExams,
    refetchInterval: 5000,
  });

  // Traffic History Query
  const {
    data: trafficHistory,
    isLoading: trafficHistoryLoading,
    refetch: refetchTrafficHistory,
  } = useQuery({
    queryKey: ['metrics-traffic-history', historyDuration],
    queryFn: () => metricsApi.getTrafficHistory(historyDuration),
  });

  const handleRefresh = () => {
    refetchRealtime();
    refetchSystem();
    refetchLiveExams();
    refetchTrafficHistory();
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Telemetri & Metrik Sistem</h1>
          <p className="text-sm text-text-secondary">
            Pemantauan langsung performa server, traffic RPS, latency, dan ujian aktif
          </p>
        </div>
        <Button variant="outline" onClick={handleRefresh}>
          <RefreshCw size={16} />
          Refresh Data
        </Button>
      </div>

      {/* Tabs */}
      <Tabs tabs={METRIC_TABS} active={activeTab} onChange={setActiveTab} />

      {/* TAB 1: Realtime Telemetry */}
      {activeTab === 'realtime' && (
        <div className="flex flex-col gap-6">
          {realtimeLoading ? (
            <FullPageSpinner />
          ) : (
            <>
              {/* Primary Cards */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <Card className="flex flex-col gap-2">
                  <div className="flex items-center justify-between text-text-secondary">
                    <span className="text-xs font-medium">Throughput (RPS)</span>
                    <Zap size={18} className="text-amber-500" />
                  </div>
                  <p className="text-3xl font-bold text-text">
                    {realtimeData?.requests_per_second?.toFixed(1) ?? '0.0'}
                  </p>
                  <span className="text-xs text-text-secondary">Request per detik</span>
                </Card>

                <Card className="flex flex-col gap-2">
                  <div className="flex items-center justify-between text-text-secondary">
                    <span className="text-xs font-medium">Siswa Aktif Ujian</span>
                    <Users size={18} className="text-primary" />
                  </div>
                  <p className="text-3xl font-bold text-text">
                    {realtimeData?.active_users ?? 0}
                  </p>
                  <span className="text-xs text-text-secondary">Koneksi websocket & telemetry aktif</span>
                </Card>

                <Card className="flex flex-col gap-2">
                  <div className="flex items-center justify-between text-text-secondary">
                    <span className="text-xs font-medium">Latency P95</span>
                    <Activity size={18} className="text-emerald-500" />
                  </div>
                  <p className="text-3xl font-bold text-text">
                    {realtimeData?.p95_response_time_ms?.toFixed(1) ?? realtimeData?.latency?.p95_ms?.toFixed(1) ?? '0.0'} <span className="text-sm font-normal">ms</span>
                  </p>
                  <span className="text-xs text-text-secondary">
                    Avg: {realtimeData?.average_response_time_ms?.toFixed(1) ?? realtimeData?.latency?.avg_ms?.toFixed(1) ?? '0'} ms &middot; P99: {realtimeData?.p99_response_time_ms?.toFixed(1) ?? realtimeData?.latency?.p99_ms?.toFixed(1) ?? '0'} ms
                  </span>
                </Card>

                <Card className="flex flex-col gap-2">
                  <div className="flex items-center justify-between text-text-secondary">
                    <span className="text-xs font-medium">Error Rate %</span>
                    <AlertCircle size={18} className={realtimeData?.error_rate_percent > 1 ? 'text-red-500' : 'text-emerald-500'} />
                  </div>
                  <p className="text-3xl font-bold text-text">
                    {realtimeData?.error_rate_percent?.toFixed(2) ?? '0.00'}%
                  </p>
                  <span className="text-xs text-text-secondary">Presentase HTTP 4xx & 5xx</span>
                </Card>
              </div>

              {/* Breakdown Grid */}
              <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                {/* HTTP Status Code Breakdown */}
                <Card className="flex flex-col gap-4">
                  <h3 className="font-semibold text-text">HTTP Status Response Breakdown</h3>
                  <div className="grid grid-cols-3 gap-3 text-center">
                    <div className="rounded-lg bg-emerald-500/10 p-4 border border-emerald-500/20">
                      <div className="flex items-center justify-center gap-1.5 text-emerald-600 mb-1">
                        <CheckCircle2 size={16} />
                        <span className="text-xs font-semibold">2xx Success</span>
                      </div>
                      <p className="text-2xl font-bold text-emerald-600">
                        {realtimeData?.http_status_breakdown?.['2xx_success'] ?? 0}
                      </p>
                    </div>

                    <div className="rounded-lg bg-amber-500/10 p-4 border border-amber-500/20">
                      <div className="flex items-center justify-center gap-1.5 text-amber-600 mb-1">
                        <AlertCircle size={16} />
                        <span className="text-xs font-semibold">4xx Client Err</span>
                      </div>
                      <p className="text-2xl font-bold text-amber-600">
                        {realtimeData?.http_status_breakdown?.['4xx_client_err'] ?? 0}
                      </p>
                    </div>

                    <div className="rounded-lg bg-red-500/10 p-4 border border-red-500/20">
                      <div className="flex items-center justify-center gap-1.5 text-red-600 mb-1">
                        <XCircle size={16} />
                        <span className="text-xs font-semibold">5xx Server Err</span>
                      </div>
                      <p className="text-2xl font-bold text-red-600">
                        {realtimeData?.http_status_breakdown?.['5xx_server_err'] ?? 0}
                      </p>
                    </div>
                  </div>
                </Card>

                {/* Submissions & Session Info */}
                <Card className="flex flex-col gap-4">
                  <h3 className="font-semibold text-text">Aktivitas Ujian & Pengerjaan</h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="rounded-lg bg-bg-secondary p-4">
                      <span className="text-xs text-text-secondary">Submission Rate / Menit</span>
                      <p className="mt-1 text-2xl font-bold text-text">
                        {realtimeData?.submissions_per_minute ?? 0} <span className="text-xs font-normal">subm/min</span>
                      </p>
                    </div>
                    <div className="rounded-lg bg-bg-secondary p-4">
                      <span className="text-xs text-text-secondary">Total Submissions Hari Ini</span>
                      <p className="mt-1 text-2xl font-bold text-text">
                        {realtimeData?.total_submissions_today ?? 0}
                      </p>
                    </div>
                  </div>
                </Card>
              </div>
            </>
          )}
        </div>
      )}

      {/* TAB 2: System Health */}
      {activeTab === 'system' && (
        <div className="flex flex-col gap-6">
          {systemLoading ? (
            <FullPageSpinner />
          ) : (
            <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
              <Card className="flex flex-col gap-4">
                <div className="flex items-center gap-2">
                  <Cpu size={20} className="text-primary" />
                  <h3 className="font-semibold text-text">Go Runtime & Process CPU</h3>
                </div>
                <div className="space-y-4">
                  <div>
                    <div className="flex justify-between text-sm mb-1">
                      <span className="text-text-secondary">Penggunaan CPU</span>
                      <span className="font-semibold text-text">
                        {systemData?.cpu?.usage_percent?.toFixed(1) ?? '0.0'}%
                      </span>
                    </div>
                    <div className="h-2.5 w-full rounded-full bg-bg-secondary overflow-hidden">
                      <div
                        className="h-full bg-primary transition-all duration-500"
                        style={{ width: `${Math.min(100, systemData?.cpu?.usage_percent || 0)}%` }}
                      />
                    </div>
                  </div>

                  <div className="flex justify-between border-t border-border pt-3 text-sm">
                    <span className="text-text-secondary">Jumlah Core CPU</span>
                    <span className="font-medium text-text">{systemData?.cpu?.cores ?? 0} Core</span>
                  </div>

                  <div className="flex justify-between border-t border-border pt-3 text-sm">
                    <span className="text-text-secondary">Active Goroutines</span>
                    <span className="font-medium text-text">{systemData?.goroutines_count ?? 0}</span>
                  </div>
                </div>
              </Card>

              <Card className="flex flex-col gap-4">
                <div className="flex items-center gap-2">
                  <Server size={20} className="text-blue-500" />
                  <h3 className="font-semibold text-text">Memori (Heap & Sys Alloc)</h3>
                </div>
                <div className="space-y-3">
                  <div className="rounded-lg bg-bg-secondary p-3 flex justify-between items-center">
                    <span className="text-xs text-text-secondary">Allocated Memory</span>
                    <span className="text-base font-bold text-text">
                      {systemData?.memory?.alloc_mb?.toFixed(1) ?? '0.0'} MB
                    </span>
                  </div>

                  <div className="rounded-lg bg-bg-secondary p-3 flex justify-between items-center">
                    <span className="text-xs text-text-secondary">OS System Memory</span>
                    <span className="text-base font-bold text-text">
                      {systemData?.memory?.sys_mb?.toFixed(1) ?? '0.0'} MB
                    </span>
                  </div>

                  <div className="rounded-lg bg-bg-secondary p-3 flex justify-between items-center">
                    <span className="text-xs text-text-secondary">Garbage Collection (GC) Cycles</span>
                    <span className="text-base font-bold text-text">
                      {systemData?.memory?.gc_cycles ?? 0}
                    </span>
                  </div>
                </div>
              </Card>

              <Card className="flex flex-col gap-4 md:col-span-2">
                <div className="flex items-center gap-2">
                  <Database size={20} className="text-emerald-500" />
                  <h3 className="font-semibold text-text">PostgreSQL Database Connection Pool</h3>
                </div>

                <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
                  <div className="rounded-lg bg-bg-secondary p-4 text-center">
                    <span className="text-xs text-text-secondary">Max Open Connections</span>
                    <p className="mt-1 text-2xl font-bold text-text">
                      {systemData?.database_pool?.max_open_connections ?? 0}
                    </p>
                  </div>

                  <div className="rounded-lg bg-emerald-500/10 p-4 text-center border border-emerald-500/20">
                    <span className="text-xs text-emerald-600 font-semibold">Active Connections</span>
                    <p className="mt-1 text-2xl font-bold text-emerald-600">
                      {systemData?.database_pool?.active_connections ?? 0}
                    </p>
                  </div>

                  <div className="rounded-lg bg-bg-secondary p-4 text-center">
                    <span className="text-xs text-text-secondary">Idle Connections</span>
                    <p className="mt-1 text-2xl font-bold text-text">
                      {systemData?.database_pool?.idle_connections ?? 0}
                    </p>
                  </div>

                  <div className="rounded-lg bg-amber-500/10 p-4 text-center border border-amber-500/20">
                    <span className="text-xs text-amber-600 font-semibold">Wait Count</span>
                    <p className="mt-1 text-2xl font-bold text-amber-600">
                      {systemData?.database_pool?.wait_count ?? 0}
                    </p>
                  </div>
                </div>
              </Card>
            </div>
          )}
        </div>
      )}

      {/* TAB 3: Live Exams */}
      {activeTab === 'live-exams' && (
        <div className="flex flex-col gap-6">
          {liveExamsLoading ? (
            <FullPageSpinner />
          ) : !liveExams?.length ? (
            <Card className="py-12 text-center text-text-secondary">
              <Radio size={40} className="mx-auto mb-2 opacity-50" />
              <p className="font-medium text-text">Tidak ada ujian live sedang berlangsung saat ini</p>
              <p className="text-xs mt-1">Ujian aktif yang sedang dikerjakan siswa akan muncul di sini secara otomatis.</p>
            </Card>
          ) : (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              {liveExams.map((exam) => (
                <Card key={exam.form_id} className="flex flex-col gap-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-bold text-text">{exam.title}</h3>
                      <span className="text-xs text-text-secondary">Creator: {exam.creator_name || 'Guru'}</span>
                    </div>
                    <Badge className="bg-emerald-500/15 text-emerald-600">
                      <Radio size={12} className="mr-1 inline animate-pulse" /> Live
                    </Badge>
                  </div>

                  <div className="grid grid-cols-3 gap-2 text-center rounded-lg bg-bg-secondary p-3">
                    <div>
                      <span className="text-[11px] text-text-secondary">Siswa Aktif</span>
                      <p className="text-lg font-bold text-primary">{exam.active_students ?? 0}</p>
                    </div>
                    <div>
                      <span className="text-[11px] text-text-secondary">Selesai Submit</span>
                      <p className="text-lg font-bold text-emerald-600">{exam.submitted_count ?? 0}</p>
                    </div>
                    <div>
                      <span className="text-[11px] text-text-secondary">Target Siswa</span>
                      <p className="text-lg font-bold text-text">{exam.total_target_students ?? 0}</p>
                    </div>
                  </div>

                  {exam.started_at && (
                    <span className="text-xs text-text-secondary">
                      Mulai: {formatDate(exam.started_at)}
                    </span>
                  )}
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB 4: Traffic History */}
      {activeTab === 'traffic-history' && (
        <div className="flex flex-col gap-6">
          <div className="flex items-center justify-between">
            <h3 className="font-semibold text-text">Riwayat Time-Series Traffic</h3>
            <div className="w-40">
              <Select
                value={historyDuration}
                onChange={(e) => setHistoryDuration(e.target.value)}
              >
                <option value="15m">15 Menit Terakhir</option>
                <option value="1h">1 Jam Terakhir</option>
                <option value="6h">6 Jam Terakhir</option>
                <option value="24h">24 Jam Terakhir</option>
              </Select>
            </div>
          </div>

          {trafficHistoryLoading ? (
            <FullPageSpinner />
          ) : !trafficHistory?.time_series?.length ? (
            <Card className="py-12 text-center text-text-secondary">
              <History size={40} className="mx-auto mb-2 opacity-50" />
              <p className="font-medium text-text">Belum ada data sampel riwayat traffic</p>
              <p className="text-xs mt-1">Data akan terkumpul seiring berjalannya request di platform.</p>
            </Card>
          ) : (
            <Card className="overflow-hidden !p-0">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead className="border-b border-border bg-bg-secondary text-xs font-semibold uppercase text-text-secondary">
                    <tr>
                      <th className="px-5 py-3">Waktu</th>
                      <th className="px-5 py-3">RPS</th>
                      <th className="px-5 py-3">Latency (ms)</th>
                      <th className="px-5 py-3">Jumlah Error</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {trafficHistory.time_series.map((point, idx) => (
                      <tr key={idx} className="hover:bg-bg-secondary/50">
                        <td className="px-5 py-3 font-mono text-text">{point.time}</td>
                        <td className="px-5 py-3 font-bold text-text">{point.rps?.toFixed(1)}</td>
                        <td className="px-5 py-3 font-medium text-emerald-600">{point.latency_ms?.toFixed(1)} ms</td>
                        <td className="px-5 py-3">
                          {point.errors > 0 ? (
                            <Badge className="bg-red-500/15 text-red-600 font-semibold">{point.errors} errors</Badge>
                          ) : (
                            <span className="text-xs text-text-secondary">0</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          )}
        </div>
      )}
    </div>
  );
}
