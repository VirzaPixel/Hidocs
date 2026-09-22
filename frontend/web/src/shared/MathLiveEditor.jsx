import katex from 'katex';
import 'katex/dist/katex.min.css';
import { Suspense, lazy, useEffect, useState } from 'react';

const MathLiveFieldInner = lazy(() => import('./MathLiveFieldInner'));

const cleanLatex = (raw) => (raw || '')
  .replace(/\\placeholder\{\}/g, '')
  .replace(/\\begin\{pmatrix\}[\s\S]*?\\end\{pmatrix\}/g, '')
  .replace(/\\displaystyle/g, '')
  .replace(/\\textstyle/g, '')
  .trim();

const preview = (raw) => {
  const cleaned = cleanLatex(raw);
  if (!cleaned) return '';
  try {
    return katex.renderToString(cleaned, { throwOnError: false, displayMode: false });
  } catch {
    return '';
  }
};

export default function MathLiveEditor({ value, onChange, placeholder = 'Tulis rumus matematika di sini.' }) {
  const [latex, setLatex] = useState(value || '');
  const [kbOpen, setKbOpen] = useState(false);

  useEffect(() => {
    const next = value || '';
    if (next === latex) return undefined;
    const timer = setTimeout(() => setLatex(next), 0);
    return () => clearTimeout(timer);
  }, [value, latex]);

  useEffect(() => {
    const onKb = () => {
      try {
        const kb = document.querySelector('.ML__keyboard');
        setKbOpen(Boolean(kb && kb.offsetParent !== null));
      } catch {
        /* abaikan */
      }
    };
    onKb();
    const timer = setInterval(onKb, 400);
    return () => clearInterval(timer);
  }, []);

  const handleLatex = (next) => {
    setLatex(next);
    onChange(cleanLatex(next));
  };

  const showKeyboard = (e) => {
    e?.preventDefault();
    try {
      const field = document.querySelector('math-field');
      field?.focus?.();
      requestAnimationFrame(() => {
        try {
          field?.executeCommand?.('showVirtualKeyboard');
        } catch {
          /* abaikan */
        }
        try {
          window.mathVirtualKeyboard?.show?.();
        } catch {
          /* abaikan */
        }
        field?.focus?.();
      });
    } catch {
      /* abaikan */
    }
  };

  return (
    <div className="flex flex-col overflow-hidden rounded-lg border border-border bg-white">
      <div className="flex shrink-0 items-center gap-2 border-b border-border bg-bg-secondary px-2 py-1.5">
        <button
          type="button"
          data-math-kb-toggle
          onClick={showKeyboard}
          className="flex shrink-0 items-center gap-1 rounded bg-primary px-2.5 py-1 text-xs font-medium text-white hover:bg-primary/90"
          title="Buka keyboard virtual matematika"
        >
          ⌨ Keyboard
        </button>
        <span className="truncate text-xs text-text-secondary">Klik tombol Keyboard untuk mengetik rumus</span>
      </div>
      <Suspense fallback={<div className="px-3 py-6 text-sm text-text-secondary">Memuat editor rumus…</div>}>
        <MathLiveFieldInner value={latex} onLatex={handleLatex} />
      </Suspense>
      {placeholder && !String(latex || '').trim() && (
        <span className="px-3 pb-2 text-xs text-text-secondary/60">{placeholder}</span>
      )}
      {String(latex || '').trim() && (
        <div className="border-t border-border bg-bg-secondary p-3 text-sm">
          <span className="mb-1 block text-xs font-medium text-text-secondary">Pratinjau (bukan LaTeX):</span>
          <div
            className="rounded-md bg-white p-2"
            style={{ minHeight: '40px' }}
            dangerouslySetInnerHTML={{ __html: preview(latex) }}
          />
        </div>
      )}
      {kbOpen ? null : <span className="sr-only" aria-hidden="true" />}
    </div>
  );
}
