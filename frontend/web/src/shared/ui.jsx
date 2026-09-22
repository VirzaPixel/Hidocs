import { cn } from '../lib/utils';

export function Button({
  as: As = 'button',
  variant = 'primary',
  size = 'md',
  className,
  loading,
  disabled,
  children,
  ...props
}) {
  const base =
    'inline-flex items-center justify-center gap-2 rounded-lg font-medium transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50 disabled:opacity-50 disabled:cursor-not-allowed';
  const sizes = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-sm',
    lg: 'px-5 py-2.5 text-base',
    icon: 'p-2',
  };
  const variants = {
    primary: 'bg-primary text-white hover:bg-primary-hover',
    secondary: 'bg-bg-secondary text-text hover:bg-border border border-border',
    outline: 'border border-border text-text hover:bg-bg-secondary',
    ghost: 'text-text hover:bg-bg-secondary',
    danger: 'bg-danger text-white hover:opacity-90',
  };

  return (
    <As
      className={cn(base, sizes[size], variants[variant], className)}
      disabled={disabled || loading}
      {...props}
    >
      {loading && <Spinner size={16} />}
      {children}
    </As>
  );
}

export function Input({ label, error, hint, className, id, ...props }) {
  const inputId = id || props.name;
  return (
    <div className="flex flex-col gap-1">
      {label && (
        <label htmlFor={inputId} className="text-sm font-medium text-text">
          {label}
        </label>
      )}
      <input
        id={inputId}
        className={cn(
          'w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-secondary',
          'focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary',
          error && 'border-danger focus:ring-danger/30 focus:border-danger',
          className
        )}
        {...props}
      />
      {hint && !error && <span className="text-xs text-text-secondary">{hint}</span>}
      {error && <span className="text-xs text-danger">{error}</span>}
    </div>
  );
}

export function Textarea({ label, error, hint, className, id, rows = 4, ...props }) {
  const inputId = id || props.name;
  return (
    <div className="flex flex-col gap-1">
      {label && (
        <label htmlFor={inputId} className="text-sm font-medium text-text">
          {label}
        </label>
      )}
      <textarea
        id={inputId}
        rows={rows}
        className={cn(
          'w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-secondary resize-y',
          'focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary',
          error && 'border-danger focus:ring-danger/30 focus:border-danger',
          className
        )}
        {...props}
      />
      {hint && !error && <span className="text-xs text-text-secondary">{hint}</span>}
      {error && <span className="text-xs text-danger">{error}</span>}
    </div>
  );
}

export function Select({ label, error, className, id, children, ...props }) {
  const inputId = id || props.name;
  return (
    <div className="flex flex-col gap-1">
      {label && (
        <label htmlFor={inputId} className="text-sm font-medium text-text">
          {label}
        </label>
      )}
      <select
        id={inputId}
        className={cn(
          'w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text',
          'focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary',
          error && 'border-danger',
          className
        )}
        {...props}
      >
        {children}
      </select>
      {error && <span className="text-xs text-danger">{error}</span>}
    </div>
  );
}

export function Checkbox({ label, className, ...props }) {
  return (
    <label className={cn('inline-flex items-center gap-2 text-sm text-text cursor-pointer', className)}>
      <input
        type="checkbox"
        className="h-4 w-4 rounded border-border text-primary focus:ring-primary/40"
        {...props}
      />
      {label}
    </label>
  );
}

export function Toggle({ checked, onChange, label, disabled }) {
  return (
    <label className={cn('inline-flex items-center gap-2 cursor-pointer', disabled && 'opacity-50 cursor-not-allowed')}>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        disabled={disabled}
        onClick={() => onChange?.(!checked)}
        className={cn(
          'relative h-6 w-11 shrink-0 rounded-full transition-colors',
          checked ? 'bg-primary' : 'bg-border'
        )}
      >
        <span
          className={cn(
            'absolute top-0.5 left-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform',
            checked && 'translate-x-5'
          )}
        />
      </button>
      {label && <span className="text-sm text-text">{label}</span>}
    </label>
  );
}

export function Badge({ children, className }) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
        className || 'bg-primary/10 text-primary'
      )}
    >
      {children}
    </span>
  );
}

export function Spinner({ size = 20, className }) {
  return (
    <svg
      className={cn('animate-spin text-current', className)}
      style={{ width: size, height: size }}
      viewBox="0 0 24 24"
      fill="none"
    >
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
    </svg>
  );
}

export function FullPageSpinner() {
  return (
    <div className="flex h-full min-h-[40vh] w-full items-center justify-center">
      <Spinner size={32} className="text-primary" />
    </div>
  );
}

export function Card({ className, children, ...props }) {
  return (
    <div
      className={cn('rounded-xl border border-border bg-surface p-5 shadow-sm', className)}
      {...props}
    >
      {children}
    </div>
  );
}

export function EmptyState({ icon, title, description, action }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 rounded-xl border border-dashed border-border py-16 text-center">
      {icon && <div className="text-text-secondary">{icon}</div>}
      <div>
        <p className="font-medium text-text">{title}</p>
        {description && <p className="mt-1 text-sm text-text-secondary">{description}</p>}
      </div>
      {action}
    </div>
  );
}

export function Pagination({ total, limit, offset, onChange }) {
  const page = Math.floor(offset / limit) + 1;
  const totalPages = Math.max(1, Math.ceil(total / limit));

  if (totalPages <= 1) return null;

  return (
    <div className="flex items-center justify-between gap-3 pt-2">
      <span className="text-xs text-text-secondary">
        Halaman {page} dari {totalPages} &middot; {total} total
      </span>
      <div className="flex gap-2">
        <Button
          variant="outline"
          size="sm"
          disabled={page <= 1}
          onClick={() => onChange(Math.max(0, offset - limit))}
        >
          Sebelumnya
        </Button>
        <Button
          variant="outline"
          size="sm"
          disabled={page >= totalPages}
          onClick={() => onChange(offset + limit)}
        >
          Berikutnya
        </Button>
      </div>
    </div>
  );
}

export function Tabs({ tabs, active, onChange }) {
  return (
    <div className="flex gap-1 overflow-x-auto border-b border-border">
      {tabs.map((tab) => (
        <button
          key={tab.value}
          onClick={() => onChange(tab.value)}
          className={cn(
            'shrink-0 border-b-2 px-4 py-2.5 text-sm font-medium transition-colors',
            active === tab.value
              ? 'border-primary text-primary'
              : 'border-transparent text-text-secondary hover:text-text'
          )}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}
