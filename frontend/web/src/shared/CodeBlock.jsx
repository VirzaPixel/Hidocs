export function CodeBlock({ code, language = 'text', className = '' }) {
  if (!code) return null;
  return (
    <pre className={`rounded-lg bg-slate-900 p-4 text-xs font-mono text-slate-100 overflow-x-auto ${className}`}>
      <code>{code}</code>
    </pre>
  );
}
export default CodeBlock;
