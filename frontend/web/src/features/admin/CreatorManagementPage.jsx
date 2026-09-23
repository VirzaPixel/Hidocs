import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus, Search, UserCheck, UserX, UserPlus, Mail, Calendar } from 'lucide-react';
import { adminApi } from '../../lib/api';
import { Button, Card, EmptyState, FullPageSpinner, Badge, Input, Toggle } from '../../shared/ui';
import { Modal } from '../../shared/Modal';
import { useToast } from '../../shared/Toast';
import { formatDate } from '../../lib/utils';

export default function CreatorManagementPage() {
  const [search, setSearch] = useState('');
  const [createOpen, setCreateOpen] = useState(false);
  const toast = useToast();
  const queryClient = useQueryClient();

  const { data: creators, isLoading } = useQuery({
    queryKey: ['admin-creators'],
    queryFn: adminApi.listCreators,
  });

  const handleToggleStatus = async (creator) => {
    const newStatus = !creator.is_active;
    try {
      await adminApi.updateCreatorStatus(creator.id, newStatus);
      toast.success(`Status ${creator.name} berhasil diubah menjadi ${newStatus ? 'Aktif' : 'Nonaktif'}`);
      queryClient.invalidateQueries({ queryKey: ['admin-creators'] });
    } catch (err) {
      toast.error(err.message);
    }
  };

  const filteredCreators = creators?.filter((c) => {
    const query = search.toLowerCase();
    return c.name?.toLowerCase().includes(query) || c.email?.toLowerCase().includes(query);
  });

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Manajemen Form Creator</h1>
          <p className="text-sm text-text-secondary">Kelola daftar pembuat form/soal (guru/dosen) dan status keaktifan akun</p>
        </div>
        <Button onClick={() => setCreateOpen(true)}>
          <UserPlus size={18} />
          Tambah Creator Baru
        </Button>
      </div>

      {/* Filter & Search */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1">
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary" />
          <input
            type="text"
            placeholder="Cari berdasarkan nama atau email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-border bg-surface pl-10 pr-4 py-2 text-sm text-text placeholder:text-text-secondary focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/40"
          />
        </div>
      </div>

      {/* Content */}
      {isLoading ? (
        <FullPageSpinner />
      ) : !filteredCreators?.length ? (
        <EmptyState
          icon={<UserCheck size={36} />}
          title={search ? 'Tidak ada creator yang cocok' : 'Belum ada akun creator'}
          description={
            search
              ? `Coba kata kunci pencarian yang lain.`
              : 'Tambahkan akun guru/creator pertama ke dalam sistem.'
          }
          action={
            !search && (
              <Button onClick={() => setCreateOpen(true)}>
                <UserPlus size={16} />
                Tambah Creator Baru
              </Button>
            )
          }
        />
      ) : (
        <Card className="overflow-hidden !p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-border bg-bg-secondary text-xs font-semibold uppercase text-text-secondary">
                <tr>
                  <th className="px-5 py-3">Nama Creator</th>
                  <th className="px-5 py-3">Email</th>
                  <th className="px-5 py-3">Tanggal Dibuat</th>
                  <th className="px-5 py-3">Status</th>
                  <th className="px-5 py-3 text-right">Aksi Keaktifan</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filteredCreators.map((c) => (
                  <tr key={c.id} className="hover:bg-bg-secondary/50 transition-colors">
                    <td className="px-5 py-3.5 font-medium text-text">
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 font-bold text-primary">
                          {c.name?.[0]?.toUpperCase() || 'C'}
                        </div>
                        <div>
                          <p className="font-semibold text-text">{c.name}</p>
                          <span className="text-xs text-text-secondary font-mono">ID: {c.id?.slice(0, 8)}...</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 text-text-secondary">
                      <div className="flex items-center gap-1.5">
                        <Mail size={14} />
                        <span>{c.email}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 text-text-secondary">
                      <div className="flex items-center gap-1.5">
                        <Calendar size={14} />
                        <span>{formatDate(c.created_at)}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      {c.is_active ? (
                        <Badge className="bg-emerald-500/15 text-emerald-600 font-medium">
                          <UserCheck size={12} className="mr-1 inline" /> Aktif
                        </Badge>
                      ) : (
                        <Badge className="bg-red-500/15 text-red-600 font-medium">
                          <UserX size={12} className="mr-1 inline" /> Nonaktif
                        </Badge>
                      )}
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <div className="inline-flex items-center gap-2">
                        <span className="text-xs text-text-secondary">
                          {c.is_active ? 'Aktif' : 'Nonaktif'}
                        </span>
                        <Toggle
                          checked={c.is_active}
                          onChange={() => handleToggleStatus(c)}
                        />
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Modal Tambah Creator */}
      <CreateCreatorModal open={createOpen} onClose={() => setCreateOpen(false)} />
    </div>
  );
}

function CreateCreatorModal({ open, onClose }) {
  const toast = useToast();
  const queryClient = useQueryClient();
  const [form, setForm] = useState({ name: '', email: '', password: '' });
  const [loading, setLoading] = useState(false);

  const onSubmit = async (e) => {
    e.preventDefault();
    if (!form.name.trim() || !form.email.trim() || !form.password.trim()) {
      toast.error('Semua kolom wajib diisi');
      return;
    }
    if (form.password.length < 6) {
      toast.error('Password minimal 6 karakter');
      return;
    }

    setLoading(true);
    try {
      await adminApi.createCreator(form);
      toast.success(`Akun creator ${form.name} berhasil dibuat`);
      queryClient.invalidateQueries({ queryKey: ['admin-creators'] });
      queryClient.invalidateQueries({ queryKey: ['admin-stats'] });
      setForm({ name: '', email: '', password: '' });
      onClose();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Tambah Form Creator Baru">
      <form onSubmit={onSubmit} className="flex flex-col gap-4">
        <Input
          label="Nama Lengkap"
          placeholder="Contoh: Dra. Sri Wahyuni"
          value={form.name}
          onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
          autoFocus
        />
        <Input
          label="Email"
          type="email"
          placeholder="guru@sekolah.sch.id"
          value={form.email}
          onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
        />
        <Input
          label="Password"
          type="password"
          placeholder="Minimal 6 karakter"
          value={form.password}
          onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
        />
        <Button type="submit" loading={loading} className="mt-2 w-full">
          <UserPlus size={16} />
          Buat Akun Creator
        </Button>
      </form>
    </Modal>
  );
}
