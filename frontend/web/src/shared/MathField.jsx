import { useMemo } from 'react';
import katex from 'katex';
import 'katex/dist/katex.min.css';
import { Textarea } from './ui';

// Simbol umum yang sering dipakai di soal matematika sekolah — klik untuk sisip ke
// posisi kursor. Ini "keyboard matematika visual" yang dimaksud di rencana produk:
// guru tidak perlu tahu sintaks LaTeX, cukup klik simbol.
const SYMBOLS = [
  { label: '½', insert: '\\frac{}{}' },
  { label: 'x²', insert: '^{2}' },
  { label: 'xⁿ', insert: '^{}' },
  { label: '√', insert: '\\sqrt{}' },
  { label: 'π', insert: '\\pi' },
  { label: '×', insert: '\\times' },
  { label: '÷', insert: '\\div' },
  { label: '≤', insert: '\\leq' },
  { label: '≥', insert: '\\geq' },
  { label: '≠', insert: '\\neq' },
  { label: '±', insert: '\\pm' },
  { label: '∑', insert: '\\sum_{}^{}' },
  { label: '∫', insert: '\\int_{}^{}' },
  { label: 'α', insert: '\\alpha' },
  { label: 'θ', insert: '\\theta' },
];

// value disimpan sebagai teks yang berisi LaTeX diapit `$...$`, mis:
// "Berapa hasil dari $\\frac{1}{2} + \\frac{1}{3}$?" — dirender apa adanya di
// question_text (frontend cukup mem-parse & render bagian $...$ saat menampilkan).
export default function MathField({ value, onChange, textareaId }) {
  const insertSymbol = (snippet) => {
    const el = document.getElementById(textareaId);
    const start = el?.selectionStart ?? value.length;
    const end = el?.selectionEnd ?? value.length;
    const before = value.slice(0, start);
    const after = value.slice(end);
    const next = `${before}$${snippet}$${after}`;
    onChange(next);
    requestAnimationFrame(() => {
      el?.focus();
      const hasPlaceholder = snippet.indexOf('{}') !== -1;
      const cursor = hasPlaceholder ? start + 2 : start + snippet.length + 2;
      el?.setSelectionRange(cursor, cursor);
    });
  };

  const preview = useMemo(() => renderMixedText(value || ''), [value]);

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap gap-1.5 rounded-lg border border-border bg-bg-secondary p-2">
        {SYMBOLS.map((s) => (
          <button
            key={s.label}
            type="button"
            onClick={() => insertSymbol(s.insert)}
            className="rounded-md border border-border bg-surface px-2.5 py-1 text-sm font-medium text-text hover:border-primary hover:text-primary"
            title={s.insert}
          >
            {s.label}
          </button>
        ))}
      </div>
      <Textarea
        id={textareaId}
        label="Teks Soal (pakai simbol di atas, akan tersisip otomatis)"
        placeholder="Contoh: Hitung hasil dari $\frac{1}{2} + \frac{1}{3}$"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        rows={3}
      />
      {value && (
        <div className="rounded-lg border border-border bg-bg-secondary p-3">
          <span className="mb-1 block text-xs font-medium text-text-secondary">Pratinjau:</span>
          <div className="text-text" dangerouslySetInnerHTML={{ __html: preview }} />
        </div>
      )}
    </div>
  );
}

// Render teks biasa apa adanya, dan bagian yang diapit $...$ dirender KaTeX.
function renderMixedText(text) {
  const parts = text.split(/(\$[^$]+\$)/g);
  return parts
    .map((part) => {
      if (part.startsWith('$') && part.endsWith('$') && part.length > 2) {
        try {
          return katex.renderToString(part.slice(1, -1), { throwOnError: false });
        } catch {
          return escapeHtml(part);
        }
      }
      return escapeHtml(part);
    })
    .join('');
}

function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

export { renderMixedText };
