import { useState } from 'react';
import { useLocation, useNavigate, Link } from 'react-router-dom';
import AuthLayout from '../../shared/layouts/AuthLayout';
import { Button, Input } from '../../shared/ui';
import { authApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';

export default function ResetPasswordPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const toast = useToast();

  const [token, setToken] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const onSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await authApi.resetPassword({ token, new_password: newPassword });
      toast.success('Password berhasil direset, silakan masuk kembali');
      navigate('/login');
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout
      title="Reset Password"
      subtitle={
        location.state?.email
          ? `Masukkan kode dari email untuk ${location.state.email}`
          : 'Masukkan kode dari email dan password baru'
      }
    >
      <form onSubmit={onSubmit} className="flex flex-col gap-4">
        <Input
          label="Kode / Token Reset"
          value={token}
          onChange={(e) => setToken(e.target.value)}
          placeholder="Tempel kode dari email"
          required
        />
        <Input
          label="Password Baru"
          type="password"
          value={newPassword}
          onChange={(e) => setNewPassword(e.target.value)}
          placeholder="Minimal 6 karakter"
          minLength={6}
          required
        />
        <Button type="submit" loading={loading} className="w-full">
          Reset Password
        </Button>
      </form>
      <p className="mt-6 text-center text-sm text-text-secondary">
        <Link to="/login" className="text-primary hover:underline">
          Kembali ke halaman masuk
        </Link>
      </p>
    </AuthLayout>
  );
}
