import { useEffect, useMemo, useRef } from 'react';
import 'mathlive';
import 'mathlive/static.css';
import 'mathlive/fonts.css';
import { Textarea } from './ui';
import { renderMixedText } from './MathField';

export default function MathLiveField({ value, onChange, textareaId }) {
  const mathRef = useRef(null);

  useEffect(() => {
    const el = mathRef.current?.querySelector('math-field');
    if (!el) return undefined;
    el.menuVisible = false;
    const show = () => window.mathVirtualKeyboard?.show?.();
    const hide = () => window.mathVirtualKeyboard?.hide?.();
    el.addEventListener('focus', show);
    window.addEventListener('resize', hide);
    return () => {
      el.removeEventListener('focus', show);
      window.removeEventListener('resize', hide);
      hide();
    };
  }, []);

  const insertAtCursor = (latex) => {
    const cleaned = latex.replace(/\\placeholder\{\}/g, '').trim();
    if (!cleaned) return;
    const el = document.getElementById(textareaId);
    if (!el) {
      onChange(`${value}$${cleaned}$`);
      return;
    }
    const start = el.selectionStart ?? value.length;
    const end = el.selectionEnd ?? value.length;
    const next = `${value.slice(0, start)}$${cleaned}$${value.slice(end)}`;
    onChange(next);
    requestAnimationFrame(() => {
      el.focus();
      const pos = start + cleaned.length + 2;
      el.setSelectionRange(pos, pos);
    });
  };

  const handleMathInput = (evt) => {
    const latex = evt.target?.value ?? '';
    if (!latex) return;
    const isPlaceholderOnly = /^\\placeholder\{\}/.test(latex) || /^\\begin\{pmatrix\}.*\\end\{pmatrix\}$/.test(latex.trim());
    if (isPlaceholderOnly) return;
    insertAtCursor(latex);
    evt.target.value = '';
  };

  const previewHtml = useMemo(() => renderMixedText(value || '(pratinjau kosong)'), [value]);

  return (
    <div className="flex flex-col gap-2">
      <div ref={mathRef} className="flex flex-col gap-1 rounded-lg border border-border bg-white p-3">
        <math-field
          virtual-keyboard-mode="manual"
          virtual-keyboards="numeric symbols functions alphabetic"
          onInput={handleMathInput}
          style={{ width: '100%', minHeight: '40px', fontSize: '18px', lineHeight: '1.4', border: '1px solid #e5e7eb', borderRadius: '8px', padding: '8px 10px', background: '#fff', color: '#111', display: 'block' }}
        />
        <p className="text-xs text-text-secondary">Ketik rumus di kotak putih di atas — rumus tersisip otomatis ke teks soal sebagai bentuk matematika, bukan kode LaTeX.</p>
      </div>
      <div className="rounded-lg border border-border bg-bg-secondary p-3">
        <span className="mb-1 block text-xs font-medium text-text-secondary">Teks Soal (kombinasi teks biasa + rumus)</span>
        <Textarea id={textareaId} label="" value={value} onChange={(e) => onChange(e.target.value)} rows={3} placeholder="Contoh: Hitung hasil dari $\frac{1}{2} + \frac{1}{3}$" />
        <div className="mt-3 rounded-lg bg-white p-3">
          <span className="mb-1 block text-xs font-medium text-text-secondary">Pratinjau (matematika dirender langsung):</span>
          <div className="text-sm text-text" dangerouslySetInnerHTML={{ __html: previewHtml }} />
        </div>
      </div>
    </div>
  );
}
