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
      <div className="fixed bottom-4 right-4 z-[100] flex w-full max-w-sm flex-col gap-2">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={cn(
              'flex items-start gap-2 rounded-lg border px-4 py-3 shadow-lg text-sm bg-surface',
              t.type === 'success' && 'border-success/30 text-success',
              t.type === 'error' && 'border-danger/30 text-danger',
              t.type === 'info' && 'border-primary/30 text-primary'
            )}
          >
            {t.type === 'success' && <CheckCircle2 size={18} className="mt-0.5 shrink-0" />}
            {t.type === 'error' && <XCircle size={18} className="mt-0.5 shrink-0" />}
            {t.type === 'info' && <Info size={18} className="mt-0.5 shrink-0" />}
            <span className="flex-1 text-text">{t.message}</span>
            <button onClick={() => remove(t.id)} className="text-text-secondary hover:text-text">
              <X size={14} />
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
