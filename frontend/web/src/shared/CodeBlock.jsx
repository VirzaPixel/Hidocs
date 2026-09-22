import { useEffect, useRef } from 'react';
import { EditorView, keymap } from '@codemirror/view';
import { EditorState, Prec } from '@codemirror/state';
import { javascript } from '@codemirror/lang-javascript';
import { python } from '@codemirror/lang-python';
import { java } from '@codemirror/lang-java';
import { cpp } from '@codemirror/lang-cpp';
import { sql } from '@codemirror/lang-sql';
import { html } from '@codemirror/lang-html';
import { oneDark } from '@codemirror/theme-one-dark';

const langMap = { javascript, python, java, c: cpp, cpp, go: cpp, sql, html };

export function CodeBlock({ value, codeLanguage }) {
  const hostRef = useRef(null);
  const viewRef = useRef(null);
  const normalized = value || '';
  useEffect(() => {
    if (!hostRef.current) return undefined;
    const lang = langMap[codeLanguage] || javascript;
    const state = EditorState.create({
      doc: normalized,
      extensions: [lang(), EditorView.editable.of(false), EditorView.theme({ '&': { maxHeight: '260px' }, '.cm-scroller': { overflow: 'auto' } }), EditorView.lineWrapping, oneDark],
    });
    const view = new EditorView({ state, parent: hostRef.current });
    viewRef.current = view;
    return () => view.destroy();
  }, [codeLanguage, normalized]);
  useEffect(() => {
    const view = viewRef.current;
    if (!view) return;
    view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: normalized } });
  }, [normalized]);
  return <div ref={hostRef} className="overflow-hidden rounded-lg border border-[#30363d]" />;
}

export function CodeEditorField({ value, onChange, codeLanguage, onLanguageChange, onExitBlock }) {
  const hostRef = useRef(null);
  const viewRef = useRef(null);

  useEffect(() => {
    if (!hostRef.current) return undefined;
    const lang = langMap[codeLanguage] || javascript;
    const shiftEnterExit = Prec.highest(
      keymap.of([
        {
          key: 'Shift-Enter',
          run: () => {
            onExitBlock?.();
            document.getElementById('code-question-textarea')?.focus();
            return true;
          },
        },
      ]),
    );
    const updateListener = EditorView.updateListener.of((upd) => {
      if (upd.docChanged) onChange(upd.state.doc.toString());
    });
    const state = EditorState.create({
      doc: value || '',
      extensions: [lang(), shiftEnterExit, updateListener, EditorView.lineWrapping, oneDark, EditorView.theme({ '&': { minHeight: '140px', fontSize: '13px' }, '.cm-content': { fontFamily: 'ui-monospace, monospace' }, '.cm-scroller': { overflow: 'auto' } })],
    });
    const view = new EditorView({ state, parent: hostRef.current });
    viewRef.current = view;
    return () => view.destroy();
  }, [codeLanguage, onChange, onExitBlock, value]);

  useEffect(() => {
    const view = viewRef.current;
    if (!view || view.state.doc.toString() === (value || '')) return;
    view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: value || '' } });
  }, [value]);

  const langs = ['javascript', 'python', 'java', 'c', 'cpp', 'go', 'sql', 'html'];
  return (
    <div className="flex flex-col gap-2">
      <div className="overflow-hidden rounded-xl border border-[#30363d] bg-[#0d1117]">
        <div className="flex items-center justify-between border-b border-[#30363d] bg-[#161b22] px-3 py-1.5">
          <span className="text-xs font-medium text-[#8b949e]">Blok Kode — Shift+Enter untuk lanjut ke pertanyaan</span>
          <select value={codeLanguage} onChange={(e) => onLanguageChange(e.target.value)} className="rounded bg-[#21262d] px-2 py-1 text-xs text-[#e6edf3]">
            <option value="">Otomatis</option>
            {langs.map((l) => (
              <option key={l} value={l}>{l}</option>
            ))}
          </select>
        </div>
        <div ref={hostRef} />
      </div>
      <p className="text-xs text-text-secondary">Tulis kode di blok terminal hitam di atas (spasi/tab dihitung, syntax highlight aktif). Tekan <kbd className="rounded bg-bg-secondary px-1">Shift+Enter</kbd> untuk keluar dan menulis pertanyaan.</p>
    </div>
  );
}
