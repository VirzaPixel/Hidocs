import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { UserPlus, Trash2, ShieldCheck, CheckCircle2 } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Card, Input, Button, EmptyState } from '../../shared/ui';
import { ConfirmDialog } from '../../shared/Modal';
import { useToast } from '../../shared/Toast';
import { useLangStore } from '../../store/langStore';
import { formatDate } from '../../lib/utils';

export default function CollaboratorsTab({ formId }) {
  const { t } = useLangStore();
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
      toast.success(`${email.trim()} langsung mendapatkan akses monitoring di Dashboard-nya!`);
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
      <Card className="flex flex-col gap-3">
        <div className="flex items-center gap-2">
          <ShieldCheck size={20} className="text-primary" />
          <h3 className="font-semibold text-text">{t('collab.shareMonitoringTitle', 'Bagikan Akses Monitoring')}</h3>
        </div>
        <p className="text-xs sm:text-sm text-text-secondary">
          {t('collab.shareMonitoringDesc', 'Guru lain yang kamu undang dapat langsung melihat Live Monitoring, Respons, dan Analitik form ini di dashboard mereka secara instan.')}
        </p>

        <div className="rounded-lg border border-primary/20 bg-primary/5 p-3 text-xs text-text-secondary flex items-start gap-2">
          <CheckCircle2 size={16} className="text-primary mt-0.5 shrink-0" />
          <span>
            <strong>UX Instan & Praktis:</strong> Begitu email guru dimasukkan, form ini otomatis muncul di tab Form Saya akun guru tersebut dengan lencana <em>Kolaborator</em>. Tidak perlu klik persetujuan berbelit-belit.
          </span>
        </div>

        <form onSubmit={handleInvite} className="mt-1 flex flex-col sm:flex-row gap-2">
          <Input
            type="email"
            placeholder={t('collab.emailPlaceholder', 'email guru pengawas')}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="flex-1"
          />
          <Button type="submit" loading={inviting} className="shrink-0">
            <UserPlus size={16} />
            {t('collab.inviteButton', 'Undang')}
          </Button>
        </form>
      </Card>

      {!isLoading && (!collaborators || collaborators.length === 0) ? (
        <EmptyState title={t('collab.empty', 'Belum ada guru lain yang diundang')} />
      ) : (
        <div className="flex flex-col gap-2">
          {collaborators?.map((c) => (
            <Card key={c.user_id} className="flex items-center justify-between p-3 sm:p-4">
              <div>
                <p className="text-sm font-medium text-text">{c.name || c.email}</p>
                <p className="text-xs text-text-secondary">
                  {c.email} &middot; Ditambahkan {formatDate(c.created_at)}
                </p>
              </div>
              <button
                onClick={() => setRemoveTarget(c)}
                className="text-text-secondary hover:text-danger p-1.5 rounded-md hover:bg-danger/10 transition-colors"
                title="Cabut akses"
              >
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
        title={t('collab.removeAccess', 'Cabut akses monitoring?')}
        description={`${removeTarget?.email} tidak akan bisa lagi melihat data monitoring form ini.`}
      />
    </div>
  );
}
