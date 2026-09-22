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

const LANGS = [
  { key: 'javascript', label: 'JavaScript', load: javascript },
  { key: 'python', label: 'Python', load: python },
  { key: 'java', label: 'Java', load: java },
  { key: 'cpp', label: 'C/C++', load: cpp },
  { key: 'sql', label: 'SQL', load: sql },
  { key: 'html', label: 'HTML', load: html },
];

const getLang = (key) => (LANGS.find((l) => l.key === key) || LANGS[0]).load;

export default function CodeMirrorEditor({ value, onChange, language, onLanguageChange, placeholder = '// Tulis kode di sini (spasi & indentasi dihitung)' }) {
  const hostRef = useRef(null);
  const viewRef = useRef(null);

  useEffect(() => {
    if (!hostRef.current) return undefined;
    const shiftEnterExit = Prec.highest(
      keymap.of([
        {
          key: 'Shift-Enter',
          run: () => {
            document.activeElement?.blur();
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
      extensions: [
        getLang(language)(),
        shiftEnterExit,
        updateListener,
        EditorView.lineWrapping,
        oneDark,
        EditorView.theme({
          '&': { minHeight: '180px', fontSize: '13.5px', borderRadius: '8px' },
          '.cm-content': { fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace', padding: '12px' },
          '.cm-scroller': { overflow: 'auto' },
          '.cm-placeholder': { color: '#8b949e', fontStyle: 'normal' },
        }),
      ],
    });
    const view = new EditorView({ state, parent: hostRef.current });
    viewRef.current = view;
    return () => view.destroy();
  }, [language]);

  useEffect(() => {
    const view = viewRef.current;
    if (!view || view.state.doc.toString() === (value || '')) return;
    view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: value || '' } });
  }, [value]);

  return (
    <div className="flex flex-col overflow-hidden rounded-lg border border-[#30363d]">
      <div className="flex items-center justify-between border-b border-[#30363d] bg-[#161b22] px-3 py-1.5">
        <div className="flex items-center gap-1.5">
          <span className="h-2.5 w-2.5 rounded-full bg-[#ff5f57]" />
          <span className="h-2.5 w-2.5 rounded-full bg-[#febc2e]" />
          <span className="h-2.5 w-2.5 rounded-full bg-[#28c840]" />
        </div>
        <select
          value={language}
          onChange={(e) => onLanguageChange(e.target.value)}
          className="rounded bg-[#21262d] px-2 py-1 text-xs text-[#e6edf3]"
        >
          {LANGS.map((l) => (
            <option key={l.key} value={l.key}>{l.label}</option>
          ))}
        </select>
      </div>
      <div ref={hostRef} className="bg-[#0d1117]" style={{ minHeight: '180px' }} data-placeholder={placeholder} />
      <div className="border-t border-[#30363d] bg-[#161b22] px-3 py-1.5 text-[11px] text-[#8b949e]">
        Spasi &amp; Tab dihitung · sintaks berwarna · tekan <kbd className="rounded bg-[#21262d] px-1">Shift+Enter</kbd> untuk keluar dari blok
      </div>
    </div>
  );
}
