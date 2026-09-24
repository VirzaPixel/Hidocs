import { useMemo } from 'react';
import katex from 'katex';
import 'katex/dist/katex.min.css';
import { Textarea } from './ui';

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

// Render teks campuran: Teks narasi, blok kode program ber-highlight, inline code, dan rumus matematika LaTeX.
function renderMixedText(text) {
  if (!text) return '';

  // 1. Ekstrak blok kode markdown: ```language ... ```
  const codeBlockRegex = /(```[a-zA-Z0-9+#-]*\n?[\s\S]*?```)/g;
  const blocks = text.split(codeBlockRegex);

  return blocks
    .map((block) => {
      if (!block) return '';

      // Cek apakah blok ini adalah code fence ```...```
      if (block.startsWith('```') && block.endsWith('```') && block.length >= 6) {
        const firstLineEnd = block.indexOf('\n');
        let lang = 'code';
        let code = '';

        if (firstLineEnd !== -1) {
          lang = block.slice(3, firstLineEnd).trim() || 'code';
          code = block.slice(firstLineEnd + 1, -3);
        } else {
          // Tanpa newline (mis. ```javascript code...```)
          const match = block.match(/^```([a-zA-Z0-9+#-]*)\s*([\s\S]*?)```$/);
          if (match) {
            lang = match[1] || 'code';
            code = match[2] || '';
          } else {
            code = block.slice(3, -3);
          }
        }
        return renderCodeBox(code, lang);
      }

      // 2. Untuk teks non-blok-kode, proses inline code dan math
      return renderTextWithMathAndInlineCode(block);
    })
    .join('');
}

function renderTextWithMathAndInlineCode(text) {
  if (!text) return '';

  // Ekstrak rumus LaTeX
  const mathRegex = /(\$\$[\s\S]+?\$\$|\\\[[\s\S]+?\\\]|\\\([\s\S]+?\\\)|\\\$[\s\S]+?\\\$|\$[^\$\n]+\$)/g;
  const parts = text.split(mathRegex);

  return parts
    .map((part) => {
      if (!part) return '';

      let expression = null;
      let displayMode = false;

      if (part.startsWith('$$') && part.endsWith('$$') && part.length >= 4) {
        expression = part.slice(2, -2);
        displayMode = true;
      } else if (part.startsWith('\\[') && part.endsWith('\\]') && part.length >= 4) {
        expression = part.slice(2, -2);
        displayMode = true;
      } else if (part.startsWith('\\(') && part.endsWith('\\)') && part.length >= 4) {
        expression = part.slice(2, -2);
        displayMode = false;
      } else if (part.startsWith('$') && part.endsWith('$') && part.length >= 2) {
        expression = part.slice(1, -1);
        displayMode = false;
      }

      if (expression !== null) {
        try {
          return katex.renderToString(expression, {
            displayMode,
            throwOnError: false,
          });
        } catch {
          return escapeHtml(part);
        }
      }

      // Fallback LaTeX commands
      if (/\\(frac|sqrt|nthroot|sum|int|pi|pm|times|div|leq|geq|neq|alpha|beta|theta|infty)/.test(part)) {
        try {
          return katex.renderToString(part, { displayMode: false, throwOnError: false });
        } catch {
          return escapeHtml(part);
        }
      }

      // 3. Proses inline code `...` dan newline
      return renderInlineCodeAndText(part);
    })
    .join('');
}

function renderInlineCodeAndText(text) {
  if (!text) return '';
  const inlineRegex = /(`[^`\n]+`)/g;
  const segments = text.split(inlineRegex);

  return segments
    .map((seg) => {
      if (!seg) return '';
      if (seg.startsWith('`') && seg.endsWith('`') && seg.length >= 2) {
        const code = seg.slice(1, -1);
        return `<code class="rounded bg-slate-100 dark:bg-slate-800 px-1.5 py-0.5 font-mono text-[12px] font-semibold text-pink-600 dark:text-pink-400 border border-slate-200 dark:border-slate-700">${escapeHtml(code)}</code>`;
      }
      return escapeHtml(seg).replace(/\n/g, '<br />');
    })
    .join('');
}

function renderCodeBox(code, language = 'javascript') {
  const displayLang = (language || 'code').trim().toUpperCase();
  const highlighted = highlightSyntax(code.trim(), language);

  return `<div class="my-3 overflow-hidden rounded-xl border border-slate-700/80 bg-[#0f172a] shadow-lg text-left select-text">
    <div class="flex items-center justify-between border-b border-slate-800 bg-[#1e293b] px-3.5 py-2 text-xs select-none">
      <div class="flex items-center gap-2">
        <div class="flex items-center gap-1.5">
          <span class="inline-block h-2.5 w-2.5 rounded-full bg-[#ff5f56]"></span>
          <span class="inline-block h-2.5 w-2.5 rounded-full bg-[#ffbd2e]"></span>
          <span class="inline-block h-2.5 w-2.5 rounded-full bg-[#27c93f]"></span>
        </div>
        <span class="font-mono text-[11px] font-bold tracking-wider text-sky-400">${displayLang}</span>
      </div>
      <span class="font-mono text-[10px] text-slate-400">code snippet</span>
    </div>
    <pre class="overflow-x-auto p-4 font-mono text-[12px] leading-relaxed text-slate-100 bg-[#0f172a]"><code class="language-${escapeHtml(language)}">${highlighted}</code></pre>
  </div>`;
}

function highlightSyntax(code, lang = 'javascript') {
  if (!code) return '';

  const KEYWORDS_SET = new Set([
    'var', 'let', 'const', 'function', 'return', 'if', 'else', 'elif', 'for', 'while', 'do',
    'switch', 'case', 'break', 'continue', 'new', 'this', 'typeof', 'instanceof', 'class',
    'extends', 'super', 'import', 'export', 'default', 'from', 'as', 'async', 'await',
    'try', 'catch', 'finally', 'throw', 'yield', 'def', 'pass', 'lambda', 'with', 'in',
    'is', 'not', 'and', 'or', 'public', 'private', 'protected', 'static', 'void', 'int',
    'long', 'float', 'double', 'boolean', 'char', 'auto', 'struct', 'cout', 'cin', 'endl',
    'SELECT', 'FROM', 'WHERE', 'INSERT', 'INTO', 'UPDATE', 'DELETE', 'JOIN', 'GROUP', 'BY', 'ORDER'
  ]);

  const BUILTINS_SET = new Set([
    'console', 'log', 'warn', 'error', 'setTimeout', 'setInterval', 'clearTimeout',
    'clearInterval', 'print', 'len', 'range', 'append', 'push', 'pop', 'map', 'filter',
    'reduce', 'document', 'window', 'Math', 'JSON', 'parse', 'stringify', 'Array', 'Object',
    'String', 'Number', 'Boolean', 'Promise', 'fetch'
  ]);

  const BOOLEANS_SET = new Set([
    'true', 'false', 'null', 'undefined', 'None', 'True', 'False', 'nil'
  ]);

  // Single-pass Tokenizer:
  // 1: Komentar (//..., /*...*/, #..., --...)
  // 2: String ("...", '...', `...`)
  // 3: Angka (123, 3.14)
  // 4: Kata / Identifier (keyword, boolean, builtin, nama variabel)
  // 5: Multi-char operators (=>, ===, !==, ==, !=, <=, >=, &&, ||, ++, --, +=, -=)
  // 6: Single-char operators (+, -, *, /, %, <, >, =, !, &)
  // 7: Karakter lain (spasi, newline, kurung, titik koma)
  const tokenizerRegex = /(\/\/[^\n]*|\/\*[\s\S]*?\*\/|#[^\n]*|--[^\n]*)|("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)|(\b\d+(?:\.\d+)?\b)|([a-zA-Z_$][a-zA-Z0-9_$]*)|(=>|===|!==|==|!=|<=|>=|&&|\|\||\+\+|--|\+=|-=|\*=|\/=|%=)|([+\-*/%<>=!&|^~])|([\s\S])/g;

  let out = '';
  let match;

  while ((match = tokenizerRegex.exec(code)) !== null) {
    const [, comment, str, num, word, multiOp, singleOp, other] = match;

    if (comment !== undefined) {
      out += `<span style="color:#94a3b8;font-style:italic;">${escapeHtml(comment)}</span>`;
    } else if (str !== undefined) {
      out += `<span style="color:#4ade80;">${escapeHtml(str)}</span>`;
    } else if (num !== undefined) {
      out += `<span style="color:#fb923c;">${escapeHtml(num)}</span>`;
    } else if (word !== undefined) {
      if (KEYWORDS_SET.has(word)) {
        out += `<span style="color:#c084fc;font-weight:600;">${escapeHtml(word)}</span>`;
      } else if (BOOLEANS_SET.has(word)) {
        out += `<span style="color:#f472b6;font-weight:600;">${escapeHtml(word)}</span>`;
      } else if (BUILTINS_SET.has(word)) {
        out += `<span style="color:#38bdf8;">${escapeHtml(word)}</span>`;
      } else {
        out += escapeHtml(word);
      }
    } else if (multiOp !== undefined || singleOp !== undefined) {
      const op = multiOp || singleOp;
      out += `<span style="color:#67e8f9;">${escapeHtml(op)}</span>`;
    } else if (other !== undefined) {
      out += escapeHtml(other);
    }
  }

  return out;
}

function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

export { renderMixedText };
