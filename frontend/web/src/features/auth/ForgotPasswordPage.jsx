import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import AuthLayout from '../../shared/layouts/AuthLayout';
import { Button, Input } from '../../shared/ui';
import { authApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const toast = useToast();
  const navigate = useNavigate();

  const onSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await authApi.forgotPassword({ email });
      setSent(true);
      toast.success('Instruksi reset password telah dikirim ke email kamu');
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (sent) {
    return (
      <AuthLayout title="Cek Email Kamu" subtitle="Kami telah mengirim tautan/kode untuk reset password">
        <Button className="w-full" onClick={() => navigate('/reset-password', { state: { email } })}>
          Sudah dapat kodenya? Reset sekarang
        </Button>
        <p className="mt-4 text-center text-sm text-text-secondary">
          <Link to="/login" className="text-primary hover:underline">
            Kembali ke halaman masuk
          </Link>
        </p>
      </AuthLayout>
    );
  }

  return (
    <AuthLayout title="Lupa Password" subtitle="Masukkan email akunmu, kami akan kirim instruksi reset">
      <form onSubmit={onSubmit} className="flex flex-col gap-4">
        <Input
          label="Email"
          type="email"
          placeholder="guru@sekolah.sch.id"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <Button type="submit" loading={loading} className="w-full">
          Kirim Instruksi
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
