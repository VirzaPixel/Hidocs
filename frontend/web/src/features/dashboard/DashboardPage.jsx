import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus, FileText, BarChart3, Trash2, Sparkles, Share2, Users } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Button, Card, EmptyState, FullPageSpinner, Badge, Tabs } from '../../shared/ui';
import { Modal } from '../../shared/Modal';
import { ConfirmDialog } from '../../shared/Modal';
import { Input, Textarea, Select } from '../../shared/ui';
import { useToast } from '../../shared/Toast';
import { useAuthStore } from '../../store/authStore';
import { useLangStore } from '../../store/langStore';
import { FORM_STATUS_META, displayFormStatus, formatDate, resolveMediaUrl } from '../../lib/utils';
import ImportMenu from './ImportMenu';
import FormAccessPanel from '../form-builder/FormAccessPanel';
import { useAIGenerationStore } from '../../store/aiGenerationStore';

export default function DashboardPage() {
  const { t } = useLangStore();
  const currentUser = useAuthStore((s) => s.user);
  const [statusFilter, setStatusFilter] = useState('');
  const [createOpen, setCreateOpen] = useState(false);
  const openAIModal = useAIGenerationStore((s) => s.openModal);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [shareTarget, setShareTarget] = useState(null);
  const navigate = useNavigate();
  const toast = useToast();
  const queryClient = useQueryClient();

  const STATUS_TABS = [
    { value: '', label: t('dashboard.all', 'Semua') },
    { value: 'DRAFT', label: t('dashboard.draft', 'Draft') },
    { value: 'ACTIVE', label: t('dashboard.active', 'Aktif') },
    { value: 'CLOSED', label: t('dashboard.closed', 'Ditutup') },
  ];

  const { data: forms, isLoading } = useQuery({
    queryKey: ['forms', statusFilter],
    queryFn: () => formApi.list(statusFilter ? { status: statusFilter } : {}),
  });

  const handleDelete = async () => {
    try {
      await formApi.remove(deleteTarget.id);
      toast.success(t('toast.deleted', 'Form berhasil dihapus'));
      queryClient.invalidateQueries({ queryKey: ['forms'] });
      setDeleteTarget(null);
    } catch (err) {
      toast.error(err.message);
    }
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-text">{t('dashboard.title', 'Form Saya')}</h1>
          <p className="text-xs sm:text-sm text-text-secondary">{t('dashboard.subtitle', 'Kelola form dan soal ujian yang kamu buat')}</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Button onClick={() => setCreateOpen(true)} className="text-xs sm:text-sm">
            <Plus size={16} />
            {t('dashboard.createNewForm', 'Buat Form Baru')}
          </Button>
          <ImportMenu />
          <Button variant="outline" onClick={openAIModal} className="text-xs sm:text-sm">
            <Sparkles size={16} />
            {t('dashboard.createWithAI', 'Buat dengan AI')}
          </Button>
        </div>
      </div>

      <div className="overflow-x-auto pb-1">
        <Tabs tabs={STATUS_TABS} active={statusFilter} onChange={setStatusFilter} />
      </div>

      {isLoading ? (
        <FullPageSpinner />
      ) : !forms?.length ? (
        <EmptyState
          icon={<FileText size={36} />}
          title={statusFilter ? `Tidak ada form berstatus "${STATUS_TABS.find((t) => t.value === statusFilter)?.label}"` : t('dashboard.noForms', 'Belum ada form')}
          description={
            statusFilter
              ? 'Coba pilih tab "Semua" untuk melihat semua form yang kamu punya.'
              : t('dashboard.noFormsDesc', 'Mulai buat form atau soal ujian pertamamu')
          }
          action={
            !statusFilter && (
              <Button onClick={() => setCreateOpen(true)}>
                <Plus size={16} />
                {t('dashboard.createNewForm', 'Buat Form Baru')}
              </Button>
            )
          }
        />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {forms.map((form) => {
            const statusKey = displayFormStatus(form);
            const statusMeta = FORM_STATUS_META[statusKey] || FORM_STATUS_META.DRAFT;
            const isOwner = !currentUser || form.user_id === currentUser.id;

            return (
              <Card key={form.id} className="flex flex-col gap-3 !p-0 overflow-hidden hover:shadow-md transition-shadow">
                {form.form_settings?.cover_image_url ? (
                  <img
                    src={resolveMediaUrl(form.form_settings.cover_image_url)}
                    alt=""
                    className="h-28 w-full object-cover"
                  />
                ) : (
                  <div className="flex h-28 w-full items-center justify-center bg-bg-secondary text-text-secondary">
                    <FileText size={28} />
                  </div>
                )}
                <div className="flex flex-1 flex-col gap-3 px-4 pb-4">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <Badge className={statusMeta.color}>{statusMeta.label}</Badge>
                      {!isOwner && (
                        <Badge className="bg-purple-100 text-purple-700 border-purple-200 dark:bg-purple-950/50 dark:text-purple-300 dark:border-purple-800 flex items-center gap-1">
                          <Users size={11} />
                          {t('dashboard.collaboratorBadge', 'Kolaborator')}
                        </Badge>
                      )}
                    </div>
                    {isOwner && (
                      <button
                        onClick={() => setDeleteTarget(form)}
                        className="text-text-secondary hover:text-danger p-1 rounded-md hover:bg-danger/10 transition-colors"
                        title="Hapus form"
                      >
                        <Trash2 size={16} />
                      </button>
                    )}
                  </div>

                  <button
                    onClick={() => {
                      if (isOwner) {
                        navigate(`/forms/${form.id}`);
                      } else {
                        navigate(`/forms/${form.id}/monitoring`);
                      }
                    }}
                    className="text-left"
                  >
                    <h3 className="font-semibold text-text line-clamp-2 hover:text-primary transition-colors">
                      {form.title}
                    </h3>
                    {form.description && (
                      <p className="mt-1 text-xs text-text-secondary line-clamp-2">{form.description}</p>
                    )}
                  </button>

                  <div className="flex items-center gap-2 text-xs text-text-secondary">
                    <span>{form.questions?.length || 0} {t('dashboard.questionsCount', 'soal')}</span>
                    <span>&middot;</span>
                    <span>{form.response_count || 0} {t('dashboard.responsesCount', 'respons')}</span>
                  </div>
                  <p className="text-[11px] text-text-secondary">
                    {t('dashboard.createdAt', 'Dibuat')} {formatDate(form.created_at)}
                  </p>

                  <div className="mt-auto grid grid-cols-3 gap-2 pt-1">
                    {isOwner ? (
                      <Button variant="outline" size="sm" onClick={() => navigate(`/forms/${form.id}`)} className="text-xs">
                        <FileText size={14} />
                        {t('dashboard.edit', 'Edit')}
                      </Button>
                    ) : (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => navigate(`/forms/${form.id}/preview`)}
                        className="text-xs"
                      >
                        <FileText size={14} />
                        Preview
                      </Button>
                    )}
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setShareTarget(form)}
                      title="Bagikan akses aplikasi siswa"
                      className="text-xs"
                    >
                      <Share2 size={14} />
                      {t('dashboard.share', 'Bagikan')}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => navigate(`/forms/${form.id}/monitoring`)}
                      className="text-xs"
                    >
                      <BarChart3 size={14} />
                      {t('dashboard.monitoring', 'Monitoring')}
                    </Button>
                  </div>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      <CreateFormModal open={createOpen} onClose={() => setCreateOpen(false)} />
      <Modal open={!!shareTarget} onClose={() => setShareTarget(null)} title="Bagikan akses aplikasi siswa">
        {shareTarget && (
          <FormAccessPanel
            form={shareTarget}
            onActivated={() => queryClient.invalidateQueries({ queryKey: ['forms'] })}
          />
        )}
      </Modal>

      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
        title={t('dashboard.deleteFormTitle', 'Hapus form ini?')}
        description={`"${deleteTarget?.title}" ${t('dashboard.deleteFormDesc', 'beserta seluruh soal dan respons akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.')}`}
      />
    </div>
  );
}

function CreateFormModal({ open, onClose }) {
  const { t } = useLangStore();
  const navigate = useNavigate();
  const toast = useToast();
  const [values, setValues] = useState({ title: '', description: '', category: '', type: 'EXAM' });
  const [loading, setLoading] = useState(false);

  const onSubmit = async (e) => {
    e.preventDefault();
    if (!values.title.trim()) {
      toast.error('Judul form wajib diisi');
      return;
    }
    setLoading(true);
    try {
      const form = await formApi.create(values);
      toast.success('Form berhasil dibuat');
      onClose();
      navigate(`/forms/${form.id}`);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title={t('dashboard.createNewForm', 'Buat Form Baru')}>
      <form onSubmit={onSubmit} className="flex flex-col gap-4">
        <Input
          label="Judul Form"
          placeholder="Contoh: Ulangan Harian IPA Bab 3"
          value={values.title}
          onChange={(e) => setValues((v) => ({ ...v, title: e.target.value }))}
          autoFocus
        />
        <Textarea
          label="Deskripsi (opsional)"
          placeholder="Petunjuk singkat untuk siswa"
          value={values.description}
          onChange={(e) => setValues((v) => ({ ...v, description: e.target.value }))}
          rows={3}
        />
        <Input
          label="Kategori (opsional)"
          placeholder="Contoh: IPA, Matematika, Bahasa Indonesia"
          value={values.category}
          onChange={(e) => setValues((v) => ({ ...v, category: e.target.value }))}
        />
        <Select
          label="Tipe"
          value={values.type}
          onChange={(e) => setValues((v) => ({ ...v, type: e.target.value }))}
        >
          <option value="EXAM">Ujian</option>
          <option value="SURVEY">Survei / Form Publik</option>
        </Select>
        <Button type="submit" loading={loading} className="mt-2 w-full">
          <Plus size={16} />
          Buat & Lanjut Edit
        </Button>
      </form>
    </Modal>
  );
}
