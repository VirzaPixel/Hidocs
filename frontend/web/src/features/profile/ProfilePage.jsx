import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Save } from 'lucide-react';
import { userApi } from '../../lib/api';
import { Card, Input, Button, FullPageSpinner } from '../../shared/ui';
import MediaUploadField from '../../shared/MediaUploadField';
import { useToast } from '../../shared/Toast';
import { useAuthStore } from '../../store/authStore';
import { formatDate, resolveMediaUrl } from '../../lib/utils';

export default function ProfilePage() {
  const setUser = useAuthStore((s) => s.setUser);
  const toast = useToast();
  const [saving, setSaving] = useState(false);

  const { data: profile, isLoading, refetch } = useQuery({
    queryKey: ['profile'],
    queryFn: () => userApi.getMe(),
  });

  const [name, setName] = useState('');
  const [avatarUrl, setAvatarUrl] = useState(null);

  if (isLoading) return <FullPageSpinner />;
  if (!profile) return null;

  const currentName = name || profile.name;
  const currentAvatar = avatarUrl !== null ? avatarUrl : profile.avatar_url;

  const handleSave = async () => {
    setSaving(true);
    try {
      const updated = await userApi.updateMe({ name: currentName, avatar_url: currentAvatar || '' });
      setUser(updated);
      toast.success('Profil diperbarui');
      refetch();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="mx-auto flex w-full max-w-xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold text-text">Profil</h1>
        <p className="text-sm text-text-secondary">Kelola informasi akunmu</p>
      </div>

      <Card className="flex flex-col gap-4">
        <div className="flex flex-col items-center gap-3 sm:flex-row sm:items-center">
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
        <p className="text-xs text-text-secondary">Bergabung sejak {formatDate(profile.created_at)}</p>

        <Button onClick={handleSave} loading={saving} className="self-start">
          <Save size={16} />
          Simpan Perubahan
        </Button>
      </Card>
    </div>
  );
}
