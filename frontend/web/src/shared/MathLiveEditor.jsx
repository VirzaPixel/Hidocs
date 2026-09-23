export default function MathLiveEditor({ value, onChange, placeholder = 'Tulis rumus Math / LaTeX...' }) {
  return (
    <div className="flex flex-col gap-1">
      <input
        type="text"
        value={value || ''}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full rounded-lg border border-border bg-surface px-3 py-2 font-mono text-sm text-text placeholder:text-text-secondary focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/40"
      />
    </div>
  );
}
