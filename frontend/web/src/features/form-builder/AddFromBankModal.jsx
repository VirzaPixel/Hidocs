import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Plus, Loader2, Library } from 'lucide-react';
import { Modal } from '../../shared/Modal';
import { Button, Input, Select, Badge, EmptyState } from '../../shared/ui';
import { questionBankApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';
import { questionTypeLabel } from '../../lib/utils';

export default function AddFromBankModal({ open, onClose, formId, onAdded }) {
  const [subject, setSubject] = useState('');
  const [addingId, setAddingId] = useState(null);
  const toast = useToast();

  const { data, isLoading } = useQuery({
    queryKey: ['question-bank', 'for-form', subject],
    queryFn: () => questionBankApi.list({ subject: subject || undefined, limit: 50 }),
    enabled: open,
  });

  const handleAdd = async (bankQuestionId) => {
    setAddingId(bankQuestionId);
    try {
      const question = await questionBankApi.addToForm(bankQuestionId, formId);
      toast.success('Soal ditambahkan ke form (salinan baru)');
      onAdded(question);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setAddingId(null);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Tambah dari Bank Soal" size="lg">
      <div className="flex flex-col gap-4">
        <Input
          placeholder="Filter mata pelajaran..."
          value={subject}
          onChange={(e) => setSubject(e.target.value)}
        />

        {isLoading ? (
          <div className="flex justify-center py-8">
            <Loader2 className="animate-spin text-primary" size={24} />
          </div>
        ) : !data?.items?.length ? (
          <EmptyState icon={<Library size={28} />} title="Bank soal masih kosong" description="Simpan soal ke bank dari halaman edit soal untuk memakainya di sini." />
        ) : (
          <div className="flex max-h-96 flex-col gap-2 overflow-y-auto">
            {data.items.map((bq) => (
              <div key={bq.id} className="flex items-start justify-between gap-3 rounded-lg border border-border p-3">
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-text">{bq.question_text}</p>
                  <div className="mt-1 flex flex-wrap gap-1.5">
                    <Badge>{questionTypeLabel(bq.question_type)}</Badge>
                    {bq.subject && <Badge className="bg-bg-secondary text-text-secondary">{bq.subject}</Badge>}
                    {bq.topic && <Badge className="bg-bg-secondary text-text-secondary">{bq.topic}</Badge>}
                  </div>
                </div>
                <Button size="sm" onClick={() => handleAdd(bq.id)} loading={addingId === bq.id}>
                  <Plus size={14} />
                  Tambah
                </Button>
              </div>
            ))}
          </div>
        )}
      </div>
    </Modal>
  );
}
