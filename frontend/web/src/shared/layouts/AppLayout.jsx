import { useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Library, UserCircle, Sun, Moon, Menu, Users, FileText, Activity, ShieldCheck, Shield, PenTool } from 'lucide-react';
import hidocsLogo from '../../assets/images/logo.png';
import { useAuthStore } from '../../store/authStore';
import { useTheme } from '../../lib/useTheme';
import { useLangStore } from '../../store/langStore';
import { cn, resolveMediaUrl } from '../../lib/utils';
import { Badge } from '../ui';
import LanguageSwitcher from '../LanguageSwitcher';
import AIGenerateModal from '../../features/dashboard/AIGenerateModal';
import AIGenerateFloatingWidget from '../../features/dashboard/AIGenerateFloatingWidget';

export default function AppLayout() {
  const { user } = useAuthStore();
  const { theme, toggleTheme } = useTheme();
  const { t } = useLangStore();
  const navigate = useNavigate();
  const [mobileOpen, setMobileOpen] = useState(false);

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
        <header className="flex h-16 shrink-0 items-center justify-between border-b border-border bg-surface px-3 sm:px-5">
          <div className="flex items-center gap-3">
            <button
              className="rounded-lg p-2 text-text-secondary hover:bg-bg-secondary md:hidden"
              onClick={() => setMobileOpen(true)}
              title="Menu"
            >
              <Menu size={20} />
            </button>
            <div className="flex items-center gap-2 md:hidden">
              <img src={hidocsLogo} alt="HiDocs" className="h-7 w-7 rounded-lg object-contain" />
              <span className="text-base font-bold text-text">HiDocs</span>
            </div>
          </div>

          <div className="flex items-center gap-2 sm:gap-3">
            <LanguageSwitcher />

            <button
              onClick={toggleTheme}
              className="rounded-lg p-2 text-text-secondary hover:bg-bg-secondary"
              title={theme === 'dark' ? 'Mode Terang' : 'Mode Gelap'}
            >
              {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
            </button>

            <button
              onClick={() => navigate('/profile')}
              className="flex items-center gap-2 rounded-lg px-2 py-1.5 hover:bg-bg-secondary transition-colors"
              title="Buka Account"
            >
              <div className="flex h-8 w-8 shrink-0 items-center justify-center overflow-hidden rounded-full bg-primary/10 text-sm font-semibold text-primary">
                {user?.avatar_url ? (
                  <img src={resolveMediaUrl(user.avatar_url)} alt="Foto profil" className="h-full w-full object-cover" />
                ) : (
                  user?.name?.[0]?.toUpperCase() || 'G'
                )}
              </div>
              <div className="hidden flex-col text-left sm:flex">
                <span className="text-sm font-medium text-text leading-tight line-clamp-1">{user?.name}</span>
                {user?.role && user.role !== 'user' && (
                  <span className="text-[10px] font-semibold text-primary uppercase">{user.role}</span>
                )}
              </div>
            </button>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto">
          <div className="mx-auto w-full max-w-6xl px-3 py-5 sm:px-6 sm:py-6">
            <Outlet />
          </div>
        </main>
      </div>

      {/* Global AI Modal and Background Progress Floating Card */}
      <AIGenerateModal />
      <AIGenerateFloatingWidget />
    </div>
  );
}

function SidebarContent({ user, onNavigate }) {
  const { t } = useLangStore();
  const isAdmin = user?.role === 'admin' || user?.role === 'superadmin';
  const isSuperAdmin = user?.role === 'superadmin';

  const userNavItems = [
    { to: '/dashboard', label: t('nav.myForms', 'Form Saya'), icon: LayoutDashboard },
    { to: '/take', label: t('nav.takeForm', 'Kerjakan Form'), icon: PenTool },
    { to: '/question-bank', label: t('nav.questionBank', 'Bank Soal'), icon: Library },
    { to: '/profile', label: t('nav.profile', 'Account'), icon: UserCircle },
  ];

  const adminNavItems = [
    { to: '/admin/dashboard', label: t('nav.adminOverview', 'Ringkasan Admin'), icon: ShieldCheck },
    { to: '/admin/creators', label: t('nav.manageCreators', 'Kelola Creator'), icon: Users },
    { to: '/admin/forms', label: t('nav.allForms', 'Semua Form'), icon: FileText },
    { to: '/admin/metrics', label: t('nav.metrics', 'Telemetri & Metrik'), icon: Activity },
  ];

  const superAdminNavItems = [
    { to: '/superadmin/admins', label: t('nav.manageAdmins', 'Kelola Admin'), icon: Shield },
  ];

  return (
    <>
      <div className="flex h-16 shrink-0 items-center justify-between border-b border-border px-5">
        <div className="flex items-center gap-2.5">
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
              {t('nav.adminPanel', 'Admin Panel')}
            </div>
            <div className="space-y-1">
              {adminNavItems.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  onClick={onNavigate}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-primary/10 text-primary font-semibold'
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
              {t('nav.superAdmin', 'SuperAdmin')}
            </div>
            <div className="space-y-1">
              {superAdminNavItems.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  onClick={onNavigate}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-primary/10 text-primary font-semibold'
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
              {t('nav.creatorSpace', 'Ruang Guru')}
            </div>
          )}
          <div className="space-y-1">
            {userNavItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={onNavigate}
                className={({ isActive }) =>
                  cn(
                    'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                    isActive
                      ? 'bg-primary/10 text-primary font-semibold'
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

      <div className="border-t border-border px-5 py-4 text-xs text-text-secondary flex items-center justify-between">
        <span>HiDocs Form Maker</span>
        <span className="text-[10px] opacity-60">v2.0</span>
      </div>
    </>
  );
}
