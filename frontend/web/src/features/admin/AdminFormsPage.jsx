import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Search, FileText, Trash2, Calendar, User, CheckCircle, Clock } from 'lucide-react';
import { adminApi } from '../../lib/api';
import { Button, Card, EmptyState, FullPageSpinner, Badge } from '../../shared/ui';
import { ConfirmDialog } from '../../shared/Modal';
import { useToast } from '../../shared/Toast';
import { formatDate } from '../../lib/utils';

export default function AdminFormsPage() {
  const [search, setSearch] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);
  const toast = useToast();
  const queryClient = useQueryClient();

  const { data: forms, isLoading } = useQuery({
    queryKey: ['admin-all-forms'],
    queryFn: adminApi.listAllForms,
  });

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      await adminApi.deleteForm(deleteTarget.id);
      toast.success(`Form "${deleteTarget.title}" berhasil dihapus oleh admin`);
      queryClient.invalidateQueries({ queryKey: ['admin-all-forms'] });
      queryClient.invalidateQueries({ queryKey: ['admin-stats'] });
      setDeleteTarget(null);
    } catch (err) {
      toast.error(err.message);
    }
  };

  const filteredForms = forms?.filter((f) => {
    const query = search.toLowerCase();
    const titleMatch = f.title?.toLowerCase().includes(query);
    const creatorMatch = f.creator_name?.toLowerCase().includes(query) || f.user?.name?.toLowerCase().includes(query);
    const categoryMatch = f.category?.toLowerCase().includes(query);
    return titleMatch || creatorMatch || categoryMatch;
  });

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Manajemen Semua Form</h1>
          <p className="text-sm text-text-secondary">
            Pantau dan kelola seluruh form & ujian yang ada di platform HiDocs
          </p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1">
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary" />
          <input
            type="text"
            placeholder="Cari judul form, nama creator, atau kategori..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-border bg-surface pl-10 pr-4 py-2 text-sm text-text placeholder:text-text-secondary focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/40"
          />
        </div>
      </div>

      {/* Content */}
      {isLoading ? (
        <FullPageSpinner />
      ) : !filteredForms?.length ? (
        <EmptyState
          icon={<FileText size={36} />}
          title={search ? 'Tidak ada form yang cocok' : 'Belum ada form di sistem'}
          description={
            search
              ? 'Coba ganti kata kunci pencarian.'
              : 'Belum ada form atau ujian yang dibuat oleh creator.'
          }
        />
      ) : (
        <Card className="overflow-hidden !p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-border bg-bg-secondary text-xs font-semibold uppercase text-text-secondary">
                <tr>
                  <th className="px-5 py-3">Judul Form</th>
                  <th className="px-5 py-3">Pembuat (Creator)</th>
                  <th className="px-5 py-3">Kategori & Tipe</th>
                  <th className="px-5 py-3">Jumlah Soal</th>
                  <th className="px-5 py-3">Respons</th>
                  <th className="px-5 py-3">Status</th>
                  <th className="px-5 py-3 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filteredForms.map((f) => (
                  <tr key={f.id} className="hover:bg-bg-secondary/50 transition-colors">
                    <td className="px-5 py-3.5">
                      <div>
                        <p className="font-semibold text-text line-clamp-1">{f.title}</p>
                        {f.description && (
                          <p className="text-xs text-text-secondary line-clamp-1">{f.description}</p>
                        )}
                        <span className="text-[11px] text-text-secondary font-mono">Dibuat {formatDate(f.created_at)}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 text-text">
                      <div className="flex items-center gap-1.5 font-medium">
                        <User size={14} className="text-text-secondary" />
                        <span>{f.creator_name || f.user?.name || 'Unknown'}</span>
                      </div>
                      <span className="text-xs text-text-secondary">{f.creator_email || f.user?.email}</span>
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="flex flex-col gap-1">
                        <Badge className="w-fit bg-primary/10 text-primary">
                          {f.category || 'Umum'}
                        </Badge>
                        <span className="text-xs text-text-secondary uppercase">{f.type || 'EXAM'}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 font-medium text-text">
                      {f.questions?.length ?? f.question_count ?? 0} Soal
                    </td>
                    <td className="px-5 py-3.5 font-medium text-text">
                      {f.response_count ?? 0} pengerjaan
                    </td>
                    <td className="px-5 py-3.5">
                      {f.status === 'PUBLISHED' || f.is_published ? (
                        <Badge className="bg-emerald-500/15 text-emerald-600 font-medium">
                          <CheckCircle size={12} className="mr-1 inline" /> Publik
                        </Badge>
                      ) : (
                        <Badge className="bg-slate-500/15 text-slate-600 font-medium">
                          <Clock size={12} className="mr-1 inline" /> Draft / Private
                        </Badge>
                      )}
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-danger hover:bg-danger/10 hover:text-danger"
                        onClick={() => setDeleteTarget(f)}
                        title="Hapus form ini (Admin Override)"
                      >
                        <Trash2 size={16} />
                        Hapus
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Dialog Konfirmasi Hapus Form */}
      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
        title="Hapus Form (Hak Akses Admin)?"
        description={`Anda akan menghapus form "${deleteTarget?.title}" secara permanen beserta seluruh soal dan respons peserta. Tindakan ini tidak dapat dibatalkan.`}
      />
    </div>
  );
}
