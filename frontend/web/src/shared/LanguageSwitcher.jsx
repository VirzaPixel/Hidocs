import { useLangStore } from '../store/langStore';
import { cn } from '../lib/utils';

export default function LanguageSwitcher({ className }) {
  const { lang, setLang } = useLangStore();

  return (
    <div className={cn('flex items-center rounded-lg border border-border bg-bg-secondary p-0.5 text-xs font-semibold', className)}>
      <button
        type="button"
        onClick={() => setLang('id')}
        className={cn(
          'rounded-md px-2.5 py-1 transition-all',
          lang === 'id' ? 'bg-surface text-primary shadow-xs' : 'text-text-secondary hover:text-text'
        )}
        title="Bahasa Indonesia"
      >
        ID
      </button>
      <button
        type="button"
        onClick={() => setLang('en')}
        className={cn(
          'rounded-md px-2.5 py-1 transition-all',
          lang === 'en' ? 'bg-surface text-primary shadow-xs' : 'text-text-secondary hover:text-text'
        )}
        title="English"
      >
        EN
      </button>
    </div>
  );
}
