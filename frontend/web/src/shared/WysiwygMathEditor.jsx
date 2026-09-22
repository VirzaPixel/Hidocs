import 'mathlive/static.css';
import 'mathlive/fonts.css';
import { useEffect, useId, useRef } from 'react';

export default function WysiwygMathEditor({ value, onChange, placeholder = 'Ketik rumus di sini...' }) {
  const normalized = value || '';
  const stableId = useId().replace(/:/g, '');
  const mathFieldId = `mf-${stableId}`;
  const mathRef = useRef(null);

  useEffect(() => {
    const mf = mathRef.current || document.getElementById(mathFieldId);
    if (!mf) return;
    mf.addEventListener?.('focus', () => window.mathVirtualKeyboard?.show?.());
  }, [mathFieldId]);

  const showKeyboard = () => {
    const mf = mathRef.current || document.getElementById(mathFieldId);
    if (!mf) return;
    mf.focus?.();
    requestAnimationFrame(() => {
      try { mf.executeCommand?.('showVirtualKeyboard'); } catch { /* fallback */ }
      window.mathVirtualKeyboard?.show?.();
      mf.focus?.();
    });
  };

  return (
    <div className="flex flex-col rounded-lg border border-border bg-white">
      <math-field
        ref={mathRef}
        id={mathFieldId}
        virtual-keyboard-mode="manual"
        virtual-keyboards="numeric symbols functions alphabetic"
        onFocus={() => window.mathVirtualKeyboard?.show?.()}
        onInput={(evt) => {
          const latex = evt.target?.value ?? '';
          const cleaned = latex.replace(/\\placeholder\{\}/g, '').trim();
          if (!cleaned || /^\\begin\{pmatrix\}.*\\end\{pmatrix\}$/.test(cleaned)) return;
          onChange(`$${cleaned}$`);
          requestAnimationFrame(() => mathRef.current?.focus?.());
        }}
        style={{ width: '100%', minHeight: '80px', fontSize: '20px', border: 'none', padding: '12px', background: '#fff', color: '#111', display: 'block' }}
      >
        {normalized}
      </math-field>
      {(!value || !value.trim()) && <span className="px-3 pb-2 text-xs text-text-secondary/60">{placeholder}</span>}
      <button
        type="button"
        onClick={showKeyboard}
        className="mx-3 mb-2 flex w-fit items-center gap-1 rounded bg-primary px-3 py-1.5 text-xs font-medium text-white hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/40"
      >
        ⌨ Keyboard
      </button>
    </div>
  );
}

export function renderMixedHtml(text) {
  return text || '';
}
