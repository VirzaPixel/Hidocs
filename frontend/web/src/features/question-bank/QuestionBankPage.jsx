import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus, Library, Trash2, Pencil } from 'lucide-react';
import { questionBankApi } from '../../lib/api';
import { Button, Input, Select, Badge, EmptyState, FullPageSpinner, Pagination, Card } from '../../shared/ui';
import { ConfirmDialog } from '../../shared/Modal';
import { useToast } from '../../shared/Toast';
import { DIFFICULTY_LEVELS, QUESTION_TYPES, questionTypeLabel } from '../../lib/utils';
import BankQuestionModal from './BankQuestionModal';

const LIMIT = 20;

export default function QuestionBankPage() {
  const [filters, setFilters] = useState({ subject: '', topic: '', difficulty: '', question_type: '' });
  const [offset, setOffset] = useState(0);
  const [editing, setEditing] = useState(null); // null = closed, {} = new, {...} = edit
  const [deleteTarget, setDeleteTarget] = useState(null);
  const toast = useToast();
  const queryClient = useQueryClient();

  const params = {
    ...Object.fromEntries(Object.entries(filters).filter(([, v]) => v)),
    limit: LIMIT,
    offset,
  };

  const { data, isLoading } = useQuery({
    queryKey: ['question-bank', params],
    queryFn: () => questionBankApi.list(params),
  });

  const updateFilter = (patch) => {
    setOffset(0);
    setFilters((f) => ({ ...f, ...patch }));
  };

  const handleDelete = async () => {
    try {
      await questionBankApi.remove(deleteTarget.id);
      toast.success('Soal dihapus dari bank');
      queryClient.invalidateQueries({ queryKey: ['question-bank'] });
      setDeleteTarget(null);
    } catch (err) {
      toast.error(err.message);
    }
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-text">Bank Soal</h1>
          <p className="text-sm text-text-secondary">Soal yang bisa dipakai ulang di form manapun</p>
        </div>
        <Button onClick={() => setEditing({})}>
          <Plus size={18} />
          Tambah Soal
        </Button>
      </div>

      <Card className="grid grid-cols-1 gap-3 sm:grid-cols-4">
        <Input placeholder="Mata pelajaran" value={filters.subject} onChange={(e) => updateFilter({ subject: e.target.value })} />
        <Input placeholder="Topik" value={filters.topic} onChange={(e) => updateFilter({ topic: e.target.value })} />
        <Select value={filters.difficulty} onChange={(e) => updateFilter({ difficulty: e.target.value })}>
          <option value="">Semua Kesulitan</option>
          {DIFFICULTY_LEVELS.map((d) => (
            <option key={d.value} value={d.value}>
              {d.label}
            </option>
          ))}
        </Select>
        <Select value={filters.question_type} onChange={(e) => updateFilter({ question_type: e.target.value })}>
          <option value="">Semua Tipe</option>
          {QUESTION_TYPES.map((t) => (
            <option key={t.value} value={t.value}>
              {t.label}
            </option>
          ))}
        </Select>
      </Card>

      {isLoading ? (
        <FullPageSpinner />
      ) : !data?.items?.length ? (
        <EmptyState
          icon={<Library size={36} />}
          title="Belum ada soal di bank"
          description="Tambahkan soal langsung di sini, atau simpan dari halaman edit form"
          action={
            <Button onClick={() => setEditing({})}>
              <Plus size={16} />
              Tambah Soal
            </Button>
          }
        />
      ) : (
        <div className="flex flex-col gap-2">
          {data.items.map((bq) => (
            <Card key={bq.id} className="flex items-start justify-between gap-3">
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium text-text">{bq.question_text}</p>
                <div className="mt-1.5 flex flex-wrap gap-1.5">
                  <Badge>{questionTypeLabel(bq.question_type)}</Badge>
                  {bq.subject && <Badge className="bg-bg-secondary text-text-secondary">{bq.subject}</Badge>}
                  {bq.topic && <Badge className="bg-bg-secondary text-text-secondary">{bq.topic}</Badge>}
                  <Badge className="bg-bg-secondary text-text-secondary">
                    {DIFFICULTY_LEVELS.find((d) => d.value === bq.difficulty)?.label || bq.difficulty}
                  </Badge>
                  <span className="text-xs text-text-secondary">{bq.points} poin</span>
                </div>
              </div>
              <div className="flex shrink-0 gap-1">
                <button onClick={() => setEditing(bq)} className="rounded p-2 text-text-secondary hover:bg-bg-secondary hover:text-primary">
                  <Pencil size={16} />
                </button>
                <button onClick={() => setDeleteTarget(bq)} className="rounded p-2 text-text-secondary hover:bg-danger/10 hover:text-danger">
                  <Trash2 size={16} />
                </button>
              </div>
            </Card>
          ))}
          <Pagination total={data.total} limit={LIMIT} offset={offset} onChange={setOffset} />
        </div>
      )}

      {editing !== null && (
        <BankQuestionModal
          open
          initial={editing.id ? editing : null}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null);
            queryClient.invalidateQueries({ queryKey: ['question-bank'] });
          }}
        />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
        title="Hapus soal ini dari bank?"
        description="Soal yang sudah pernah disalin ke form lain TIDAK akan ikut terhapus dari form tersebut."
      />
    </div>
  );
}
