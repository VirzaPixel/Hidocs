import 'mathlive';
import 'mathlive/static.css';
import 'mathlive/fonts.css';
import { useEffect, useRef } from 'react';

export default function MathLiveFieldInner({ value, onLatex }) {
  const fieldRef = useRef(null);

  useEffect(() => {
    try {
      if (window.mathVirtualKeyboard && !window.mathVirtualKeyboard.layouts) {
        window.mathVirtualKeyboard.layouts = ['numeric', 'symbols', 'functions', 'alphabetic'];
      }
    } catch {
      /* abaikan */
    }
  }, []);

  useEffect(() => {
    const field = fieldRef.current;
    if (!field || typeof field.addEventListener !== 'function') return undefined;
    const showKb = () => {
      try {
        window.mathVirtualKeyboard?.show?.();
      } catch {
        /* abaikan */
      }
    };
    const sync = () => {
      try {
        onLatex((field.value || '').toString());
      } catch {
        /* abaikan */
      }
    };
    field.addEventListener('input', sync);
    field.addEventListener('focus', showKb);
    return () => {
      field.removeEventListener('input', sync);
      field.removeEventListener('focus', showKb);
    };
  }, [onLatex]);

  useEffect(() => {
    const f = fieldRef.current;
    if (f && f.value !== (value || '')) {
      try {
        f.value = value || '';
      } catch {
        /* abaikan */
      }
    }
  }, [value]);

  return (
    <math-field
      ref={fieldRef}
      virtual-keyboard-mode="manual"
      virtual-keyboards="numeric symbols functions alphabetic"
      onInput={() => {}}
      className="block w-full"
      style={{
        width: '100%',
        minHeight: '96px',
        maxHeight: '220px',
        overflowY: 'auto',
        fontSize: '20px',
        background: '#fff',
        color: '#111',
        padding: '12px 14px',
        border: 'none',
        outline: 'none',
        boxSizing: 'border-box',
        display: 'block',
      }}
    >
      {value || ''}
    </math-field>
  );
}
