import { useEditor, EditorContent } from '@tiptap/react';
import { StarterKit } from '@tiptap/starter-kit';
import { Underline } from '@tiptap/extension-underline';
import { TextStyle } from '@tiptap/extension-text-style';
import { Color } from '@tiptap/extension-color';
import { FontFamily } from '@tiptap/extension-font-family';
import { Placeholder } from '@tiptap/extension-placeholder';
import { Bold, Italic, UnderlineIcon, Palette, Type } from 'lucide-react';
import { useState } from 'react';

export default function ModeTextEditor({ value, onChange, placeholder = 'Tulis pertanyaan di sini...' }) {
  const [active, setActive] = useState({ bold: false, italic: false, underline: false });
  const editor = useEditor({
    extensions: [StarterKit.configure({ heading: false, horizontalRule: false, code: false, codeBlock: false }), Underline, TextStyle, FontFamily, Color, Placeholder.configure({ placeholder })],
    content: value ? `<p>${value}</p>` : '<p></p>',
    editorProps: { attributes: { class: 'min-h-[80px] p-3 text-sm text-text focus:outline-none' } },
    onUpdate: ({ editor: ed }) => {
      const html = ed.getHTML();
      const text = html.replace(/<\/p><p>/g, '\n').replace(/<[^>]+>/g, '').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
      onChange(text);
    },
    onSelectionUpdate: ({ editor: ed }) => setActive({ bold: ed.isActive('bold'), italic: ed.isActive('italic'), underline: ed.isActive('underline') }),
    onTransaction: ({ editor: ed }) => setActive({ bold: ed.isActive('bold'), italic: ed.isActive('italic'), underline: ed.isActive('underline') }),
  });
  if (!editor) return null;
  const toggleMark = (mark) => {
    editor.chain().focus()[`toggle${mark}`]().run();
    setActive((prev) => ({ ...prev, [mark.toLowerCase()]: !prev[mark.toLowerCase()] }));
  };
  return (
    <div className="flex flex-col rounded-lg border border-border bg-surface">
      <div className="flex flex-wrap gap-1 border-b border-border bg-bg-secondary px-2 py-1.5">
        <button type="button" onPointerDown={(e) => { e.preventDefault(); toggleMark('Bold'); }} className={`rounded p-1.5 ${active.bold ? 'bg-primary text-white' : 'text-text-secondary hover:bg-surface'}`} aria-pressed={active.bold} title="Bold (Ctrl+B)"><Bold size={14} /></button>
        <button type="button" onPointerDown={(e) => { e.preventDefault(); toggleMark('Italic'); }} className={`rounded p-1.5 ${active.italic ? 'bg-primary text-white' : 'text-text-secondary hover:bg-surface'}`} aria-pressed={active.italic} title="Italic (Ctrl+I)"><Italic size={14} /></button>
        <button type="button" onPointerDown={(e) => { e.preventDefault(); toggleMark('Underline'); }} className={`rounded p-1.5 ${active.underline ? 'bg-primary text-white' : 'text-text-secondary hover:bg-surface'}`} aria-pressed={active.underline} title="Underline (Ctrl+U)"><UnderlineIcon size={14} /></button>
        <span className="mx-1 h-4 w-px bg-border" />
        <button type="button" onPointerDown={(e) => { e.preventDefault(); editor.chain().focus().setColor('#ef4444').run(); }} className="rounded p-1.5 text-text-secondary hover:bg-surface"><Palette size={14} /></button>
        <button type="button" onPointerDown={(e) => { e.preventDefault(); editor.chain().focus().setFontFamily('serif').run(); }} className="rounded p-1.5 text-text-secondary hover:bg-surface"><Type size={14} /></button>
      </div>
      <EditorContent editor={editor} />
    </div>
  );
}
