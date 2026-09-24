import { createContext, useCallback, useContext, useState } from 'react';
import { CheckCircle2, XCircle, Info, X } from 'lucide-react';
import { cn } from '../lib/utils';

const ToastContext = createContext(null);

let idCounter = 0;

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const remove = useCallback((id) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const push = useCallback(
    (message, type = 'info', duration = 4000) => {
      const id = ++idCounter;
      setToasts((prev) => [...prev, { id, message, type }]);
      if (duration) {
        setTimeout(() => remove(id), duration);
      }
    },
    [remove]
  );

  const toast = {
    success: (msg) => push(msg, 'success'),
    error: (msg) => push(msg, 'error'),
    info: (msg) => push(msg, 'info'),
  };

  return (
    <ToastContext.Provider value={toast}>
      {children}
      {/* Centered symmetrically at the top on both mobile and desktop */}
      <div className="pointer-events-none fixed top-5 left-1/2 -translate-x-1/2 z-[100] flex w-[calc(100%-2rem)] max-w-md flex-col items-center gap-2">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={cn(
              'pointer-events-auto flex w-full items-start gap-3 rounded-xl border px-4 py-3 shadow-xl backdrop-blur-md text-sm transition-all animate-in fade-in slide-in-from-top-3 duration-200',
              t.type === 'success' && 'border-success/30 bg-surface/95 text-success shadow-success/5',
              t.type === 'error' && 'border-danger/30 bg-surface/95 text-danger shadow-danger/5',
              t.type === 'info' && 'border-primary/30 bg-surface/95 text-primary shadow-primary/5'
            )}
          >
            {t.type === 'success' && <CheckCircle2 size={18} className="mt-0.5 shrink-0 text-success" />}
            {t.type === 'error' && <XCircle size={18} className="mt-0.5 shrink-0 text-danger" />}
            {t.type === 'info' && <Info size={18} className="mt-0.5 shrink-0 text-primary" />}
            <span className="flex-1 text-text leading-snug">{t.message}</span>
            <button onClick={() => remove(t.id)} className="text-text-secondary hover:text-text shrink-0 p-0.5 rounded-md hover:bg-bg-secondary">
              <X size={15} />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used within ToastProvider');
  return ctx;
}
