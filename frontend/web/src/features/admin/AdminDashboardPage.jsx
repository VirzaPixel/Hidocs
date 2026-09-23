import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import {
  Users,
  UserCheck,
  FileText,
  Radio,
  BarChart2,
  Activity,
  Cpu,
  Database,
  ArrowRight,
  ShieldCheck,
} from 'lucide-react';
import { adminApi, metricsApi } from '../../lib/api';
import { Card, Button, FullPageSpinner, Badge } from '../../shared/ui';
import { useAuthStore } from '../../store/authStore';

export default function AdminDashboardPage() {
  const navigate = useNavigate();
  const user = useAuthStore((s) => s.user);

  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['admin-stats'],
    queryFn: adminApi.getDashboardStats,
    refetchInterval: 15000,
  });

  const { data: realtime, isLoading: realtimeLoading } = useQuery({
    queryKey: ['admin-metrics-realtime'],
    queryFn: metricsApi.getRealtimeMetrics,
    refetchInterval: 5000,
  });

  const { data: system } = useQuery({
    queryKey: ['admin-metrics-system'],
    queryFn: metricsApi.getSystemMetrics,
    refetchInterval: 10000,
  });

  if (statsLoading || realtimeLoading) {
    return <FullPageSpinner />;
  }

  const realtimeData = realtime || {};
  const systemData = system || {};

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold text-text">Dashboard Admin</h1>
            <Badge className="bg-primary/15 text-primary font-semibold text-xs">
              {user?.role?.toUpperCase()}
            </Badge>
          </div>
          <p className="text-sm text-text-secondary">
            Pantau aktivitas sistem, metrik telemetri, dan kelola pengguna HiDocs
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => navigate('/admin/creators')}>
            <Users size={16} />
            Kelola Creator
          </Button>
          <Button variant="outline" onClick={() => navigate('/admin/metrics')}>
            <Activity size={16} />
            Metrik Telemetri
          </Button>
        </div>
      </div>

      {/* Global Stats Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <Card className="flex items-center gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary">
            <Users size={24} />
          </div>
          <div>
            <p className="text-xs text-text-secondary">Total Pengguna</p>
            <p className="text-2xl font-bold text-text">{stats?.total_users ?? 0}</p>
          </div>
        </Card>

        <Card className="flex items-center gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-blue-500/10 text-blue-500">
            <UserCheck size={24} />
          </div>
          <div>
            <p className="text-xs text-text-secondary">Form Creator</p>
            <p className="text-2xl font-bold text-text">{stats?.total_creators ?? 0}</p>
          </div>
        </Card>

        <Card className="flex items-center gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-amber-500/10 text-amber-500">
            <FileText size={24} />
          </div>
          <div>
            <p className="text-xs text-text-secondary">Total Form</p>
            <p className="text-2xl font-bold text-text">{stats?.total_forms ?? 0}</p>
          </div>
        </Card>

        <Card className="flex items-center gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-500">
            <Radio size={24} />
          </div>
          <div>
            <p className="text-xs text-text-secondary">Ujian Live</p>
            <p className="text-2xl font-bold text-text">{stats?.active_exams ?? 0}</p>
          </div>
        </Card>

        <Card className="flex items-center gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-purple-500/10 text-purple-500">
            <BarChart2 size={24} />
          </div>
          <div>
            <p className="text-xs text-text-secondary">Total Respons</p>
            <p className="text-2xl font-bold text-text">{stats?.total_responses ?? 0}</p>
          </div>
        </Card>
      </div>

      {/* Realtime Telemetry Snapshot */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card className="flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Activity className="text-primary" size={20} />
              <h2 className="font-semibold text-text">Telemetri Lalu Lintas Realtime</h2>
            </div>
            <Button variant="ghost" size="sm" onClick={() => navigate('/admin/metrics')}>
              Detail <ArrowRight size={14} />
            </Button>
          </div>

          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            <div className="rounded-lg bg-bg-secondary p-3">
              <span className="text-xs text-text-secondary">Requests / Detik</span>
              <p className="mt-1 text-xl font-bold text-text">
                {realtimeData.requests_per_second?.toFixed(1) ?? '0.0'} RPS
              </p>
            </div>
            <div className="rounded-lg bg-bg-secondary p-3">
              <span className="text-xs text-text-secondary">Siswa Aktif</span>
              <p className="mt-1 text-xl font-bold text-text">
                {realtimeData.active_users ?? 0}
              </p>
            </div>
            <div className="rounded-lg bg-bg-secondary p-3">
              <span className="text-xs text-text-secondary">Latency P95</span>
              <p className="mt-1 text-xl font-bold text-text">
                {realtimeData.p95_response_time_ms?.toFixed(1) ?? realtimeData.latency?.p95_ms?.toFixed(1) ?? '0.0'} ms
              </p>
            </div>
            <div className="rounded-lg bg-bg-secondary p-3">
              <span className="text-xs text-text-secondary">Pengiriman / Menit</span>
              <p className="mt-1 text-xl font-bold text-text">
                {realtimeData.submissions_per_minute ?? 0}
              </p>
            </div>
            <div className="rounded-lg bg-bg-secondary p-3">
              <span className="text-xs text-text-secondary">Submissions Hari Ini</span>
              <p className="mt-1 text-xl font-bold text-text">
                {realtimeData.total_submissions_today ?? 0}
              </p>
            </div>
            <div className="rounded-lg bg-bg-secondary p-3">
              <span className="text-xs text-text-secondary">Error Rate</span>
              <p className="mt-1 text-xl font-bold text-text">
                {realtimeData.error_rate_percent?.toFixed(2) ?? '0.00'}%
              </p>
            </div>
          </div>
        </Card>

        <Card className="flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Cpu className="text-primary" size={20} />
              <h2 className="font-semibold text-text">Kesehatan Performa Server</h2>
            </div>
            <Button variant="ghost" size="sm" onClick={() => navigate('/admin/metrics')}>
              Detail <ArrowRight size={14} />
            </Button>
          </div>

          <div className="grid grid-cols-2 gap-3 sm:grid-cols-2">
            <div className="rounded-lg bg-bg-secondary p-3">
              <span className="text-xs text-text-secondary">CPU Usage</span>
              <p className="mt-1 text-xl font-bold text-text">
                {systemData.cpu?.usage_percent?.toFixed(1) ?? '0.0'}%
              </p>
              <span className="text-[11px] text-text-secondary">
                {systemData.cpu?.cores ?? 0} Cores
              </span>
            </div>
            <div className="rounded-lg bg-bg-secondary p-3">
              <span className="text-xs text-text-secondary">RAM Allocated</span>
              <p className="mt-1 text-xl font-bold text-text">
                {systemData.memory?.alloc_mb?.toFixed(1) ?? '0.0'} MB
              </p>
              <span className="text-[11px] text-text-secondary">
                GC Cycles: {systemData.memory?.gc_cycles ?? 0}
              </span>
            </div>
            <div className="rounded-lg bg-bg-secondary p-3">
              <div className="flex items-center gap-1.5 text-xs text-text-secondary">
                <Database size={14} />
                <span>Koneksi DB Aktif</span>
              </div>
              <p className="mt-1 text-xl font-bold text-text">
                {systemData.database_pool?.active_connections ?? 0} / {systemData.database_pool?.max_open_connections ?? 0}
              </p>
            </div>
            <div className="rounded-lg bg-bg-secondary p-3">
              <span className="text-xs text-text-secondary">Active Goroutines</span>
              <p className="mt-1 text-xl font-bold text-text">
                {systemData.goroutines_count ?? 0}
              </p>
            </div>
          </div>
        </Card>
      </div>

      {/* Quick Action Navigation Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <Card
          className="group flex cursor-pointer items-center justify-between hover:border-primary transition-colors"
          onClick={() => navigate('/admin/creators')}
        >
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <UserCheck size={20} />
            </div>
            <div>
              <h3 className="font-semibold text-text">Manajemen Creator</h3>
              <p className="text-xs text-text-secondary">Lihat, tambah, & kelola status akun guru</p>
            </div>
          </div>
          <ArrowRight size={18} className="text-text-secondary group-hover:text-primary transition-colors" />
        </Card>

        <Card
          className="group flex cursor-pointer items-center justify-between hover:border-primary transition-colors"
          onClick={() => navigate('/admin/forms')}
        >
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-500/10 text-amber-500">
              <FileText size={20} />
            </div>
            <div>
              <h3 className="font-semibold text-text">Manajemen Form & Ujian</h3>
              <p className="text-xs text-text-secondary">Lihat & kelola semua form di sistem</p>
            </div>
          </div>
          <ArrowRight size={18} className="text-text-secondary group-hover:text-primary transition-colors" />
        </Card>

        <Card
          className="group flex cursor-pointer items-center justify-between hover:border-primary transition-colors"
          onClick={() => navigate('/admin/metrics')}
        >
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-500">
              <Activity size={20} />
            </div>
            <div>
              <h3 className="font-semibold text-text">Laporan Telemetri</h3>
              <p className="text-xs text-text-secondary">Pantau RPS, latency, & live exams</p>
            </div>
          </div>
          <ArrowRight size={18} className="text-text-secondary group-hover:text-primary transition-colors" />
        </Card>

        {user?.role === 'superadmin' && (
          <Card
            className="group flex cursor-pointer items-center justify-between border-primary/30 bg-primary/5 hover:border-primary transition-colors sm:col-span-2 lg:col-span-3"
            onClick={() => navigate('/superadmin/admins')}
          >
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-white">
                <ShieldCheck size={20} />
              </div>
              <div>
                <h3 className="font-semibold text-text">SuperAdmin Panel: Kelola Administrator</h3>
                <p className="text-xs text-text-secondary">Buat dan pantau akun dengan role Admin di seluruh platform</p>
              </div>
            </div>
            <ArrowRight size={18} className="text-primary" />
          </Card>
        )}
      </div>
    </div>
  );
}
