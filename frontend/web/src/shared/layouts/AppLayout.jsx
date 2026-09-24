import { useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Library, UserCircle, Sun, Moon, LogOut, Menu, Users, FileText, Activity, ShieldCheck, Shield } from 'lucide-react';
import hidocsLogo from '../../assets/images/logo.png';
import { useAuthStore } from '../../store/authStore';
import { authApi } from '../../lib/api';
import { useTheme } from '../../lib/useTheme';
import { cn, resolveMediaUrl } from '../../lib/utils';
import { Badge } from '../ui';

const USER_NAV_ITEMS = [
  { to: '/dashboard', label: 'Form Saya', icon: LayoutDashboard },
  { to: '/question-bank', label: 'Bank Soal', icon: Library },
  { to: '/profile', label: 'Profil', icon: UserCircle },
];

const ADMIN_NAV_ITEMS = [
  { to: '/admin/dashboard', label: 'Ringkasan Admin', icon: ShieldCheck },
  { to: '/admin/creators', label: 'Kelola Creator', icon: Users },
  { to: '/admin/forms', label: 'Semua Form', icon: FileText },
  { to: '/admin/metrics', label: 'Telemetri & Metrik', icon: Activity },
];

const SUPERADMIN_NAV_ITEMS = [
  { to: '/superadmin/admins', label: 'Kelola Admin', icon: Shield },
];

export default function AppLayout() {
  const { user, logout, refreshToken } = useAuthStore();
  const { theme, toggleTheme } = useTheme();
  const navigate = useNavigate();
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleLogout = async () => {
    // Cabut refresh token di server dulu (best-effort) supaya token yang
    // tersimpan tidak bisa dipakai lagi walau sudah keluar aplikasi. Kalau
    // request gagal (server down), sesi lokal tetap dibersihkan.
    try {
      if (refreshToken) await authApi.logout(refreshToken);
    } catch {
      // diabaikan: logout lokal tetap jalan
    }
    logout();
    navigate('/login');
  };

  return (
    <div className="flex h-screen w-full overflow-hidden bg-bg">
      {/* Sidebar - desktop */}
      <aside className="hidden w-64 shrink-0 flex-col border-r border-border bg-surface md:flex">
        <SidebarContent user={user} onNavigate={() => {}} />
      </aside>

      {/* Sidebar - mobile drawer */}
      {mobileOpen && (
        <div className="fixed inset-0 z-40 md:hidden">
          <div className="absolute inset-0 bg-black/50" onClick={() => setMobileOpen(false)} />
          <aside className="relative z-10 flex h-full w-64 flex-col border-r border-border bg-surface">
            <SidebarContent user={user} onNavigate={() => setMobileOpen(false)} />
          </aside>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex h-16 shrink-0 items-center justify-between border-b border-border bg-surface px-4">
          <div className="flex items-center gap-3">
            <button
              className="rounded-lg p-2 text-text-secondary hover:bg-bg-secondary md:hidden"
              onClick={() => setMobileOpen(true)}
            >
              <Menu size={20} />
            </button>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={toggleTheme}
              className="rounded-lg p-2 text-text-secondary hover:bg-bg-secondary"
              title="Ganti tema"
            >
              {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
            </button>
            <div className="ml-1 flex items-center gap-2 rounded-lg px-2 py-1.5 hover:bg-bg-secondary">
              <button onClick={() => navigate('/profile')} className="flex h-8 w-8 items-center justify-center overflow-hidden rounded-full bg-primary/10 text-sm font-semibold text-primary" title="Buka profil">
                {user?.avatar_url ? <img src={resolveMediaUrl(user.avatar_url)} alt="Foto profil" className="h-full w-full object-cover" /> : user?.name?.[0]?.toUpperCase() || 'G'}
              </button>
              <div className="hidden flex-col sm:flex">
                <span className="text-sm font-medium text-text leading-tight">{user?.name}</span>
                {user?.role && user.role !== 'user' && (
                  <span className="text-[10px] font-semibold text-primary uppercase">{user.role}</span>
                )}
              </div>
            </div>
            <button
              onClick={handleLogout}
              className="rounded-lg p-2 text-text-secondary hover:bg-danger/10 hover:text-danger"
              title="Keluar"
            >
              <LogOut size={18} />
            </button>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto">
          <div className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}

function SidebarContent({ user, onNavigate }) {
  const isAdmin = user?.role === 'admin' || user?.role === 'superadmin';
  const isSuperAdmin = user?.role === 'superadmin';

  return (
    <>
      <div className="flex h-16 shrink-0 items-center justify-between border-b border-border px-5">
        <div className="flex items-center gap-2">
          <img src={hidocsLogo} alt="HiDocs" className="h-8 w-8 rounded-lg object-contain" />
          <span className="text-lg font-bold text-text">HiDocs</span>
        </div>
        {user?.role && user.role !== 'user' && (
          <Badge className="bg-primary/15 text-primary capitalize font-medium text-[11px]">
            {user.role}
          </Badge>
        )}
      </div>

      <nav className="flex-1 space-y-6 overflow-y-auto px-3 py-4">
        {isAdmin && (
          <div>
            <div className="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-text-secondary">
              Admin Panel
            </div>
            <div className="space-y-1">
              {ADMIN_NAV_ITEMS.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  onClick={onNavigate}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-primary/10 text-primary'
                        : 'text-text-secondary hover:bg-bg-secondary hover:text-text'
                    )
                  }
                >
                  <item.icon size={18} />
                  {item.label}
                </NavLink>
              ))}
            </div>
          </div>
        )}

        {isSuperAdmin && (
          <div>
            <div className="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-text-secondary">
              SuperAdmin
            </div>
            <div className="space-y-1">
              {SUPERADMIN_NAV_ITEMS.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  onClick={onNavigate}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-primary/10 text-primary'
                        : 'text-text-secondary hover:bg-bg-secondary hover:text-text'
                    )
                  }
                >
                  <item.icon size={18} />
                  {item.label}
                </NavLink>
              ))}
            </div>
          </div>
        )}

        <div>
          {isAdmin && (
            <div className="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-text-secondary">
              Creator Space
            </div>
          )}
          <div className="space-y-1">
            {USER_NAV_ITEMS.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={onNavigate}
                className={({ isActive }) =>
                  cn(
                    'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                    isActive
                      ? 'bg-primary/10 text-primary'
                      : 'text-text-secondary hover:bg-bg-secondary hover:text-text'
                  )
                }
              >
                <item.icon size={18} />
                {item.label}
              </NavLink>
            ))}
          </div>
        </div>
      </nav>

      <div className="border-t border-border px-5 py-4 text-xs text-text-secondary">
        HiDocs Form Maker
      </div>
    </>
  );
}

