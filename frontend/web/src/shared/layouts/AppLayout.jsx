import { useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Library, UserCircle, Sun, Moon, LogOut, Menu, X, FileText } from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { useTheme } from '../../lib/useTheme';
import { cn } from '../../lib/utils';

const NAV_ITEMS = [
  { to: '/dashboard', label: 'Form Saya', icon: LayoutDashboard },
  { to: '/question-bank', label: 'Bank Soal', icon: Library },
  { to: '/profile', label: 'Profil', icon: UserCircle },
];

export default function AppLayout() {
  const { user, logout } = useAuthStore();
  const { theme, toggleTheme } = useTheme();
  const navigate = useNavigate();
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="flex h-screen w-full overflow-hidden bg-bg">
      {/* Sidebar - desktop */}
      <aside className="hidden w-64 shrink-0 flex-col border-r border-border bg-surface md:flex">
        <SidebarContent onNavigate={() => {}} />
      </aside>

      {/* Sidebar - mobile drawer */}
      {mobileOpen && (
        <div className="fixed inset-0 z-40 md:hidden">
          <div className="absolute inset-0 bg-black/50" onClick={() => setMobileOpen(false)} />
          <aside className="relative z-10 flex h-full w-64 flex-col border-r border-border bg-surface">
            <SidebarContent onNavigate={() => setMobileOpen(false)} />
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
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-sm font-semibold text-primary">
                {user?.name?.[0]?.toUpperCase() || 'G'}
              </div>
              <span className="hidden text-sm font-medium text-text sm:block">{user?.name}</span>
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

function SidebarContent({ onNavigate }) {
  return (
    <>
      <div className="flex h-16 shrink-0 items-center gap-2 border-b border-border px-5">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-white">
          <FileText size={18} />
        </div>
        <span className="text-lg font-bold text-text">HiDocs</span>
      </div>
      <nav className="flex-1 space-y-1 px-3 py-4">
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            onClick={onNavigate}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
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
      </nav>
      <div className="border-t border-border px-5 py-4 text-xs text-text-secondary">
        HiDocs Form Maker
      </div>
    </>
  );
}
