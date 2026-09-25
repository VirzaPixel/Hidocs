import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Save, LogOut, Shield } from 'lucide-react';
import { userApi, authApi } from '../../lib/api';
import { Card, Input, Button, FullPageSpinner, Badge } from '../../shared/ui';
import { ConfirmDialog } from '../../shared/Modal';
import MediaUploadField from '../../shared/MediaUploadField';
import { useToast } from '../../shared/Toast';
import { useAuthStore } from '../../store/authStore';
import { formatDate, resolveMediaUrl } from '../../lib/utils';

export default function ProfilePage() {
  const { user, setUser, logout, refreshToken } = useAuthStore();
  const navigate = useNavigate();
  const toast = useToast();
  const [saving, setSaving] = useState(false);
  const [logoutConfirm, setLogoutConfirm] = useState(false);

  const { data: profile, isLoading, refetch } = useQuery({
    queryKey: ['profile'],
    queryFn: () => userApi.getMe(),
  });

  const [name, setName] = useState('');
  const [avatarUrl, setAvatarUrl] = useState(null);

  if (isLoading) return <FullPageSpinner />;
  if (!profile) return null;

  const currentName = name !== '' ? name : (profile.name || '');
  const currentAvatar = avatarUrl !== null ? avatarUrl : (profile.avatar_url || '');

  const handleSave = async () => {
    setSaving(true);
    try {
      const updated = await userApi.updateMe({ name: currentName, avatar_url: currentAvatar });
      setUser(updated);
      toast.success('Profil diperbarui');
      refetch();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = async () => {
    try {
      if (refreshToken) await authApi.logout(refreshToken);
    } catch {
      // ignore
    }
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <div className="mx-auto flex w-full max-w-xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold text-text">Account</h1>
        <p className="text-sm text-text-secondary">Kelola informasi akun dan preferensi sesi login</p>
      </div>

      <Card className="flex flex-col gap-4">
        <div className="flex flex-col items-center gap-4 sm:flex-row sm:items-center">
          <div className="flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-full bg-primary/10 text-xl font-semibold text-primary">
            {currentAvatar ? (
              <img src={resolveMediaUrl(currentAvatar)} alt="avatar" className="h-full w-full object-cover" />
            ) : (
              currentName?.[0]?.toUpperCase() || 'G'
            )}
          </div>
          <div className="w-full sm:max-w-xs">
            <MediaUploadField mediaType="IMAGE" value={currentAvatar} onChange={setAvatarUrl} label="Foto Profil" />
          </div>
        </div>

        <Input label="Nama Lengkap" value={currentName} onChange={(e) => setName(e.target.value)} />
        <Input label="Email" value={profile.email} disabled className="opacity-60" />

        <div className="flex items-center justify-between pt-1">
          <p className="text-xs text-text-secondary">Bergabung sejak {formatDate(profile.created_at)}</p>
          {profile.role && profile.role !== 'user' && (
            <Badge className="bg-primary/15 text-primary capitalize font-medium text-xs">
              Role: {profile.role}
            </Badge>
          )}
        </div>

        <Button onClick={handleSave} loading={saving} className="self-start mt-2">
          <Save size={16} />
          Simpan Perubahan
        </Button>
      </Card>

      {/* Sesi & Logout */}
      <Card className="flex flex-col gap-3 border-danger/20">
        <div>
          <h3 className="font-semibold text-text">Sesi Login</h3>
          <p className="text-xs text-text-secondary mt-0.5">
            Keluar dari sesi akun saat ini pada perangkat ini.
          </p>
        </div>
        <div className="pt-2">
          <Button
            type="button"
            variant="outline"
            onClick={() => setLogoutConfirm(true)}
            className="border-danger/30 text-danger hover:bg-danger/10 hover:border-danger self-start"
          >
            <LogOut size={16} />
            Keluar dari Akun (Logout)
          </Button>
        </div>
      </Card>

      <ConfirmDialog
        open={logoutConfirm}
        onClose={() => setLogoutConfirm(false)}
        onConfirm={handleLogout}
        title="Keluar dari Akun?"
        description="Kamu akan keluar dari akun ini dan diarahkan kembali ke halaman login."
      />
    </div>
  );
}
