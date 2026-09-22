import { Plus, Trash2 } from 'lucide-react';
import { Input } from './ui';

// Setiap "option" untuk tipe MATCHING merepresentasikan SATU pasangan:
// option_text = item kiri, match_target_text = item kanan yang harus dijodohkan.
// match_key dipakai backend/app mobile untuk memverifikasi pasangan tetap benar
// walau urutan tampil diacak — di sini cukup diisi index yang stabil.
export default function MatchingEditor({ pairs, onChange, minPairs = 2 }) {
  const update = (index, patch) => {
    onChange(pairs.map((p, i) => (i === index ? { ...p, ...patch } : p)));
  };

  const addPair = () => {
    const nextIndex = pairs.length + 1;
    onChange([
      ...pairs,
      {
        option_text: '',
        match_target_text: '',
        match_key: `pair-${nextIndex}-${Date.now()}`,
        is_correct: true,
        order_index: nextIndex,
      },
    ]);
  };

  const removePair = (index) => {
    if (pairs.length <= minPairs) return;
    onChange(pairs.filter((_, i) => i !== index).map((p, i) => ({ ...p, order_index: i + 1 })));
  };

  return (
    <div className="flex flex-col gap-2">
      <span className="text-sm font-medium text-text">Pasangan Jawaban</span>
      <div className="grid grid-cols-[1fr_auto_1fr_auto] items-center gap-2 text-xs font-medium text-text-secondary">
        <span>Item Kiri</span>
        <span />
        <span>Dijodohkan Dengan</span>
        <span />
      </div>
      {pairs.map((pair, i) => (
        <div key={pair.match_key || i} className="grid grid-cols-[1fr_auto_1fr_auto] items-center gap-2">
          <Input
            placeholder={`Item kiri ${i + 1}`}
            value={pair.option_text}
            onChange={(e) => update(i, { option_text: e.target.value })}
          />
          <span className="text-text-secondary">&harr;</span>
          <Input
            placeholder={`Pasangannya ${i + 1}`}
            value={pair.match_target_text || ''}
            onChange={(e) => update(i, { match_target_text: e.target.value })}
          />
          <button
            type="button"
            onClick={() => removePair(i)}
            disabled={pairs.length <= minPairs}
            className="text-text-secondary hover:text-danger disabled:opacity-30"
          >
            <Trash2 size={16} />
          </button>
        </div>
      ))}
      <button
        type="button"
        onClick={addPair}
        className="mt-1 flex items-center gap-1.5 self-start text-sm font-medium text-primary hover:underline"
      >
        <Plus size={14} />
        Tambah Pasangan
      </button>
    </div>
  );
}
