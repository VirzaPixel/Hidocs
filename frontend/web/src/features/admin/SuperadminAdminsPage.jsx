import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Shield, ShieldPlus, Search, Mail, Calendar, UserCheck } from 'lucide-react';
import { superadminApi } from '../../lib/api';
import { Button, Card, EmptyState, FullPageSpinner, Badge, Input } from '../../shared/ui';
import { Modal } from '../../shared/Modal';
import { useToast } from '../../shared/Toast';
import { formatDate } from '../../lib/utils';

export default function SuperadminAdminsPage() {
  const [search, setSearch] = useState('');
  const [createOpen, setCreateOpen] = useState(false);
  const toast = useToast();

  const { data: admins, isLoading } = useQuery({
    queryKey: ['superadmin-list-admins'],
    queryFn: superadminApi.listAdmins,
  });

  const filteredAdmins = admins?.filter((a) => {
    const query = search.toLowerCase();
    return a.name?.toLowerCase().includes(query) || a.email?.toLowerCase().includes(query);
  });

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold text-text">Manajemen Administrator</h1>
            <Badge className="bg-primary/15 text-primary font-semibold text-xs uppercase">
              Superadmin Exclusive
            </Badge>
          </div>
          <p className="text-sm text-text-secondary">
            Kelola daftar akun Administrator yang memiliki akses ke dashboard pengelolaan sistem
          </p>
        </div>
        <Button onClick={() => setCreateOpen(true)}>
          <ShieldPlus size={18} />
          Buat Admin Baru
        </Button>
      </div>

      {/* Search */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1">
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary" />
          <input
            type="text"
            placeholder="Cari admin berdasarkan nama atau email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-border bg-surface pl-10 pr-4 py-2 text-sm text-text placeholder:text-text-secondary focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/40"
          />
        </div>
      </div>

      {/* Content */}
      {isLoading ? (
        <FullPageSpinner />
      ) : !filteredAdmins?.length ? (
        <EmptyState
          icon={<Shield size={36} />}
          title={search ? 'Tidak ada admin yang cocok' : 'Belum ada akun Admin'}
          description={
            search ? 'Coba ganti pencarian.' : 'Buat akun Administrator pertama.'
          }
          action={
            !search && (
              <Button onClick={() => setCreateOpen(true)}>
                <ShieldPlus size={16} />
                Buat Admin Baru
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
                  <th className="px-5 py-3">Nama Admin</th>
                  <th className="px-5 py-3">Email</th>
                  <th className="px-5 py-3">Role</th>
                  <th className="px-5 py-3">Tanggal Dibuat</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filteredAdmins.map((a) => (
                  <tr key={a.id} className="hover:bg-bg-secondary/50 transition-colors">
                    <td className="px-5 py-3.5 font-medium text-text">
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-white font-bold">
                          {a.name?.[0]?.toUpperCase() || 'A'}
                        </div>
                        <div>
                          <p className="font-semibold text-text">{a.name}</p>
                          <span className="text-xs text-text-secondary font-mono">ID: {a.id?.slice(0, 8)}...</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 text-text-secondary">
                      <div className="flex items-center gap-1.5">
                        <Mail size={14} />
                        <span>{a.email}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <Badge className="bg-primary/15 text-primary font-semibold uppercase">
                        {a.role || 'ADMIN'}
                      </Badge>
                    </td>
                    <td className="px-5 py-3.5 text-text-secondary">
                      <div className="flex items-center gap-1.5">
                        <Calendar size={14} />
                        <span>{formatDate(a.created_at)}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Modal Buat Admin */}
      <CreateAdminModal open={createOpen} onClose={() => setCreateOpen(false)} />
    </div>
  );
}

function CreateAdminModal({ open, onClose }) {
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
      await superadminApi.createAdmin(form);
      toast.success(`Akun Admin ${form.name} berhasil dibuat`);
      queryClient.invalidateQueries({ queryKey: ['superadmin-list-admins'] });
      setForm({ name: '', email: '', password: '' });
      onClose();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Buat Akun Administrator Baru">
      <form onSubmit={onSubmit} className="flex flex-col gap-4">
        <Input
          label="Nama Lengkap Admin"
          placeholder="Contoh: Admin Utama"
          value={form.name}
          onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
          autoFocus
        />
        <Input
          label="Email Admin"
          type="email"
          placeholder="admin@hidocs.id"
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
          <ShieldPlus size={16} />
          Buat Akun Admin
        </Button>
      </form>
    </Modal>
  );
}
