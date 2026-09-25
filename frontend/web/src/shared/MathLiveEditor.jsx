import { useState, useEffect, useRef, useMemo } from 'react';
import 'mathlive';
import { Keyboard, Calculator, Plus, Eye, Type, ChevronDown, ChevronUp, ClipboardPaste, Sparkles, X } from 'lucide-react';
import { renderMixedText } from './MathField';
import { parseClipboardMath, mathmlToLatex } from '../lib/mathmlToLatex';
import { useToast } from './Toast';

const QUICK_SYMBOLS = [
  { label: '½', insert: '\\frac{#?}{#?}', title: 'Pecahan' },
  { label: 'x²', insert: '^{2}', title: 'Pangkat 2' },
  { label: 'xⁿ', insert: '^{#?}', title: 'Pangkat n' },
  { label: '√x', insert: '\\sqrt{#?}', title: 'Akar kuadrat' },
  { label: 'ⁿ√x', insert: '\\nthroot{#?}{#?}', title: 'Akar n' },
  { label: 'xₙ', insert: '_{#?}', title: 'Subskrip' },
  { label: 'π', insert: '\\pi', title: 'Pi' },
  { label: '×', insert: '\\times', title: 'Perkalian' },
  { label: '÷', insert: '\\div', title: 'Pembagian' },
  { label: '±', insert: '\\pm', title: 'Plus Minus' },
  { label: '≤', insert: '\\leq', title: 'Kurang dari sama dengan' },
  { label: '≥', insert: '\\geq', title: 'Lebih dari sama dengan' },
  { label: '≠', insert: '\\neq', title: 'Tidak sama dengan' },
  { label: '∑', insert: '\\sum_{i=1}^{n}', title: 'Sigma / Sum' },
  { label: '∫', insert: '\\int', title: 'Integral' },
  { label: '∞', insert: '\\infty', title: 'Tak hingga' },
  { label: 'α', insert: '\\alpha', title: 'Alpha' },
  { label: 'θ', insert: '\\theta', title: 'Theta' },
];

export default function MathLiveEditor({ value = '', onChange, placeholder = 'Ketik kalimat pertanyaan, ruang spasi, enter, dan rumus matematika di sini...' }) {
  const mfRef = useRef(null);
  const textareaRef = useRef(null);
  const [showMathBuilder, setShowMathBuilder] = useState(false);
  const [formulaInput, setFormulaInput] = useState('');
  const [showPasteModal, setShowPasteModal] = useState(false);
  const [pasteRawInput, setPasteRawInput] = useState('');
  const toast = useToast();

  const preview = useMemo(() => renderMixedText(value || ''), [value]);

  useEffect(() => {
    const mf = mfRef.current;
    if (!mf) return;

    mf.mathVirtualKeyboardPolicy = 'auto';

    const handleInput = (e) => {
      setFormulaInput(e.target.value);
    };

    mf.addEventListener('input', handleInput);
    return () => {
      mf.removeEventListener('input', handleInput);
    };
  }, [showMathBuilder]);

  // Insert a math snippet directly into the main 1-box at cursor position
  const insertSnippetToMainText = (snippet, displayMode = false) => {
    const textarea = textareaRef.current;
    const start = textarea?.selectionStart ?? (value || '').length;
    const end = textarea?.selectionEnd ?? (value || '').length;
    const before = (value || '').slice(0, start);
    const after = (value || '').slice(end);

    const formatted = displayMode ? `\n\\[${snippet}\\]\n` : `\\(${snippet}\\)`;
    const newValue = `${before}${formatted}${after}`;
    onChange(newValue);

    requestAnimationFrame(() => {
      textarea?.focus();
      const newCursor = start + formatted.length;
      textarea?.setSelectionRange(newCursor, newCursor);
    });
  };

  const handlePaste = (e) => {
    const clipboardData = e.clipboardData;
    if (!clipboardData) return;

    const html = clipboardData.getData('text/html') || '';
    const text = clipboardData.getData('text/plain') || '';

    const convertedLatex = parseClipboardMath(html, text);
    if (convertedLatex) {
      e.preventDefault();
      insertSnippetToMainText(convertedLatex, false);
      toast.success('Rumus matematika berhasil disalin & dikonversi dari MathML / Word!');
    }
  };

  const handleConfirmPasteModal = () => {
    if (!pasteRawInput.trim()) return;
    const converted = parseClipboardMath(pasteRawInput, pasteRawInput) || mathmlToLatex(pasteRawInput);
    if (converted) {
      insertSnippetToMainText(converted, false);
      toast.success('Rumus MathML berhasil dikonversi ke soal!');
      setPasteRawInput('');
      setShowPasteModal(false);
    } else {
      toast.error('Tidak menemukan struktur MathML atau rumus yang valid pada teks yang ditempel.');
    }
  };

  const insertSymbolToMathLiveField = (snippet) => {
    if (mfRef.current) {
      mfRef.current.insert(snippet, { selectionMode: 'placeholder' });
      mfRef.current.focus();
      setFormulaInput(mfRef.current.value);
    } else {
      insertSnippetToMainText(snippet, false);
    }
  };

  const toggleVirtualKeyboard = () => {
    setShowMathBuilder(true);
    setTimeout(() => {
      if (window.mathVirtualKeyboard) {
        window.mathVirtualKeyboard.toggle();
      } else if (mfRef.current) {
        mfRef.current.focus();
      }
    }, 100);
  };

  const confirmInsertFormula = (displayMode = false) => {
    const formula = formulaInput.trim() || (mfRef.current ? mfRef.current.value.trim() : '');
    if (formula) {
      insertSnippetToMainText(formula, displayMode);
    }
    if (mfRef.current) {
      mfRef.current.value = '';
    }
    setFormulaInput('');
    setShowMathBuilder(false);
  };

  return (
    <div className="flex flex-col gap-3 rounded-xl border border-border bg-surface p-4 shadow-sm">
      {/* Unified Toolbar for 1 Question Box */}
      <div className="flex flex-wrap items-center justify-between gap-2 border-b border-border pb-2.5">
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="flex items-center gap-1 text-xs font-semibold text-text-secondary mr-1">
            <Calculator size={14} className="text-primary" /> Sisip Rumus:
          </span>
          {QUICK_SYMBOLS.map((s) => (
            <button
              key={s.label}
              type="button"
              onClick={() => insertSnippetToMainText(s.insert, false)}
              className="rounded border border-border bg-bg-secondary px-2 py-0.5 text-xs font-medium text-text hover:border-primary hover:bg-primary/10 hover:text-primary transition-colors active:scale-95"
              title={`Sisapkan ${s.title} ke teks pertanyaan`}
            >
              {s.label}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={() => setShowPasteModal(true)}
            className="flex items-center gap-1 rounded-lg border border-emerald-500/40 bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-600 dark:text-emerald-400 hover:bg-emerald-500/20 active:scale-95 transition-all shadow-2xs"
            title="Tempel kode MathML / XML rumus dari Word atau web luar"
          >
            <ClipboardPaste size={14} />
            <span>Tempel Rumus (Word / MathML)</span>
          </button>

          <button
            type="button"
            onClick={() => {
              setShowMathBuilder(!showMathBuilder);
              if (!showMathBuilder) toggleVirtualKeyboard();
            }}
            className="flex items-center gap-1.5 rounded-lg border border-primary/40 bg-primary/10 px-3 py-1 text-xs font-semibold text-primary hover:bg-primary/20 active:scale-95 transition-all shadow-2xs"
            title="Buka Papan Ketik Visual MathLive untuk menyusun rumus rumit"
          >
            <Keyboard size={14} />
            <span>Keyboard Visual MathLive</span>
            {showMathBuilder ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
          </button>
        </div>
      </div>

      {/* Optional Popover Visual MathLive Builder (opens when Keyboard Visual clicked) */}
      {showMathBuilder && (
        <div className="rounded-lg border border-primary/30 bg-primary/5 p-3.5 flex flex-col gap-2.5 shadow-inner">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-primary flex items-center gap-1">
              <Keyboard size={13} /> Susun Rumus Visual (MathLive):
            </span>
            <span className="text-[11px] text-text-secondary">
              Gunakan keyboard matematika visual di bawah untuk mengetik rumus rumit.
            </span>
          </div>

          <div className="flex flex-wrap items-center gap-1">
            {QUICK_SYMBOLS.map((s) => (
              <button
                key={s.label}
                type="button"
                onClick={() => insertSymbolToMathLiveField(s.insert)}
                className="rounded border border-border bg-surface px-2 py-0.5 text-xs font-medium text-text hover:border-primary transition-colors"
              >
                {s.label}
              </button>
            ))}
          </div>

          <div className="rounded-lg border border-border bg-surface p-1 focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/20">
            <math-field
              ref={mfRef}
              placeholder="Ketik rumus visual di sini..."
              style={{
                width: '100%',
                minHeight: '40px',
                fontSize: '1.1rem',
                outline: 'none',
                background: 'transparent',
              }}
            />
          </div>

          <div className="flex items-center gap-2 pt-1">
            <button
              type="button"
              onClick={() => confirmInsertFormula(false)}
              className="flex items-center gap-1 rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-white hover:bg-primary/90 active:scale-95"
            >
              <Plus size={14} /> Sisipkan ke Teks Pertanyaan \(...\)
            </button>
            <button
              type="button"
              onClick={() => confirmInsertFormula(true)}
              className="flex items-center gap-1 rounded-md border border-primary bg-surface px-3 py-1.5 text-xs font-medium text-primary hover:bg-primary/10 active:scale-95"
            >
              <Plus size={14} /> Sisipkan Baris Baru \[...\]
            </button>
            <button
              type="button"
              onClick={() => setShowMathBuilder(false)}
              className="ml-auto text-xs text-text-secondary hover:text-text"
            >
              Tutup
            </button>
          </div>
        </div>
      )}

      {/* 1 SINGLE UNIFIED QUESTION BOX */}
      <div className="flex flex-col gap-1.5">
        <label className="text-xs font-semibold text-text flex items-center gap-1">
          <Type size={14} className="text-primary" /> Kotak Soal & Pertanyaan (Gabungan Teks & Rumus):
        </label>
        <textarea
          ref={textareaRef}
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          onPaste={handlePaste}
          placeholder={placeholder || 'Ketik narasi soal di sini, tekan enter untuk baris baru, dan sisipkan rumus matematika...\n\nContoh:\nPerhatikan soal di bawah ini:\n\\(\\frac{1}{2} + \\frac{1}{3}\\)\nBerapakah hasil dari soal ini?'}
          rows={5}
          className="w-full rounded-lg border border-border bg-surface p-3 font-sans text-sm text-text placeholder:text-text-secondary focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 leading-relaxed"
        />
      </div>

      {/* LIVE PREVIEW (Hasil yang dilihat siswa) */}
      <div className="rounded-lg border border-border bg-bg-secondary p-3.5 flex flex-col gap-2">
        <div className="flex items-center justify-between text-xs font-semibold text-text-secondary border-b border-border/40 pb-1.5">
          <span className="flex items-center gap-1.5 text-primary">
            <Eye size={14} /> Pratinjau Tampilan Soal (Hasil yang Dilihat Siswa):
          </span>
        </div>
        {value ? (
          <div
            className="text-sm text-text leading-relaxed whitespace-pre-wrap pt-1 bg-surface p-3 rounded-md border border-border/50 shadow-xs"
            dangerouslySetInnerHTML={{ __html: preview }}
          />
        ) : (
          <div className="text-xs text-text-secondary italic pt-1">
            Belum ada teks soal. Ketik teks dan sisipkan rumus di atas untuk melihat pratinjau.
          </div>
        )}
      </div>

      {/* MODAL / DIALOG TEMPEL RUMUS (WORD / GOOGLE / MATHML) */}
      {showPasteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-fadeIn">
          <div className="w-full max-w-lg rounded-2xl border border-border bg-surface p-6 shadow-2xl flex flex-col gap-4">
            <div className="flex items-center justify-between border-b border-border pb-3">
              <div className="flex items-center gap-2">
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600">
                  <ClipboardPaste size={18} />
                </div>
                <div>
                  <h3 className="font-bold text-text text-sm">Tempel Rumus dari Word / Web Luar</h3>
                  <p className="text-[11px] text-text-secondary">Mendukung salinan persamaan Word, MathML XML, dan LaTeX</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowPasteModal(false)}
                className="rounded-lg p-1.5 text-text-secondary hover:bg-bg-secondary hover:text-text"
              >
                <X size={16} />
              </button>
            </div>

            <div className="flex flex-col gap-2 text-xs">
              <label className="font-semibold text-text">
                Tempel teks atau kode MathML rumus di sini (Ctrl+V):
              </label>
              <textarea
                rows={5}
                value={pasteRawInput}
                onChange={(e) => setPasteRawInput(e.target.value)}
                placeholder="Contoh: <math xmlns='http://www.w3.org/1998/Math/MathML'><mfrac><mn>1</mn><mn>2</mn></mfrac></math> atau salin langsung dari Word..."
                className="w-full rounded-xl border border-border bg-bg-secondary p-3 font-mono text-xs text-text focus:border-primary focus:bg-surface focus:outline-none"
                autoFocus
              />
              <p className="text-[11px] text-text-secondary leading-relaxed">
                <Sparkles size={12} className="inline text-emerald-500 mr-1" />
                Tips: Kamu juga bisa <strong>langsung menekan tombol Ctrl+V (Paste)</strong> di dalam kotak soal utama tanpa membuka dialog ini!
              </p>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-border">
              <button
                type="button"
                onClick={() => setShowPasteModal(false)}
                className="rounded-xl border border-border px-4 py-2 text-xs font-semibold text-text hover:bg-bg-secondary"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmPasteModal}
                className="flex items-center gap-1.5 rounded-xl bg-emerald-600 px-4 py-2 text-xs font-semibold text-white hover:bg-emerald-700 shadow-md active:scale-95"
              >
                <Sparkles size={14} />
                Konversi & Masukkan Rumus
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
