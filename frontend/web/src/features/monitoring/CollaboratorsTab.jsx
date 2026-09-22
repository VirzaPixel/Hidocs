import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { UserPlus, Trash2 } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Card, Input, Button, EmptyState } from '../../shared/ui';
import { ConfirmDialog } from '../../shared/Modal';
import { useToast } from '../../shared/Toast';
import { formatDate } from '../../lib/utils';

export default function CollaboratorsTab({ formId }) {
  const [email, setEmail] = useState('');
  const [inviting, setInviting] = useState(false);
  const [removeTarget, setRemoveTarget] = useState(null);
  const toast = useToast();
  const queryClient = useQueryClient();

  const { data: collaborators, isLoading } = useQuery({
    queryKey: ['collaborators', formId],
    queryFn: () => formApi.listCollaborators(formId),
  });

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['collaborators', formId] });

  const handleInvite = async (e) => {
    e.preventDefault();
    if (!email.trim()) return;
    setInviting(true);
    try {
      await formApi.addCollaborator(formId, email.trim());
      toast.success(`${email} sekarang bisa memantau form ini`);
      setEmail('');
      invalidate();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setInviting(false);
    }
  };

  const handleRemove = async () => {
    try {
      await formApi.removeCollaborator(formId, removeTarget.user_id);
      toast.success('Akses monitoring dicabut');
      invalidate();
      setRemoveTarget(null);
    } catch (err) {
      toast.error(err.message);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <Card>
        <h3 className="font-semibold text-text">Bagikan Akses Monitoring</h3>
        <p className="mt-1 text-sm text-text-secondary">
          Guru lain yang kamu undang bisa melihat Live Monitoring, Respons, dan Analitik form ini —
          tapi TIDAK bisa mengedit soal, menilai, atau mengundang guru lain.
        </p>
        <form onSubmit={handleInvite} className="mt-3 flex gap-2">
          <Input
            type="email"
            placeholder="email guru pengawas"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="flex-1"
          />
          <Button type="submit" loading={inviting}>
            <UserPlus size={16} />
            Undang
          </Button>
        </form>
      </Card>

      {!isLoading && (!collaborators || collaborators.length === 0) ? (
        <EmptyState title="Belum ada guru lain yang diundang" />
      ) : (
        <div className="flex flex-col gap-2">
          {collaborators?.map((c) => (
            <Card key={c.user_id} className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-text">{c.name || c.email}</p>
                <p className="text-xs text-text-secondary">
                  {c.email} &middot; Ditambahkan {formatDate(c.created_at)}
                </p>
              </div>
              <button onClick={() => setRemoveTarget(c)} className="text-text-secondary hover:text-danger">
                <Trash2 size={16} />
              </button>
            </Card>
          ))}
        </div>
      )}

      <ConfirmDialog
        open={!!removeTarget}
        onClose={() => setRemoveTarget(null)}
        onConfirm={handleRemove}
        title="Cabut akses monitoring?"
        description={`${removeTarget?.email} tidak akan bisa lagi melihat data monitoring form ini.`}
      />
    </div>
  );
}
