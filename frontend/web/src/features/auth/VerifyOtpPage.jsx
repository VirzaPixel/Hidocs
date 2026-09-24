import { useEffect, useState } from 'react';
import { useLocation, useNavigate, Link } from 'react-router-dom';
import AuthLayout from '../../shared/layouts/AuthLayout';
import { Button, Input } from '../../shared/ui';
import { authApi } from '../../lib/api';
import { useAuthStore } from '../../store/authStore';
import { useToast } from '../../shared/Toast';

export default function VerifyOtpPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const login = useAuthStore((s) => s.login);
  const toast = useToast();

  const email = location.state?.email || '';
  const [otpCode, setOtpCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [countdown, setCountdown] = useState(180);

  useEffect(() => {
    if (countdown <= 0) return;
    const t = setInterval(() => setCountdown((c) => c - 1), 1000);
    return () => clearInterval(t);
  }, [countdown]);

  if (!email) {
    return (
      <AuthLayout title="Verifikasi OTP" subtitle="Sesi tidak valid">
        <p className="text-sm text-text-secondary">
          Silakan mulai dari halaman{' '}
          <Link to="/register" className="text-primary hover:underline">
            pendaftaran
          </Link>{' '}
          terlebih dahulu.
        </p>
      </AuthLayout>
    );
  }

  const onSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await authApi.verifyOtp({ email, otp_code: otpCode });
      login(res.token, res.user, res.refresh_token);
      toast.success('Akun berhasil diverifikasi');
      navigate('/dashboard');
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  const onResend = async () => {
    setResending(true);
    try {
      await authApi.resendOtp({ email });
      setCountdown(180);
      toast.success('Kode OTP baru telah dikirim');
    } catch (err) {
      toast.error(err.message);
    } finally {
      setResending(false);
    }
  };

  return (
    <AuthLayout title="Verifikasi Email" subtitle={`Masukkan 6 digit kode yang dikirim ke ${email}`}>
      <form onSubmit={onSubmit} className="flex flex-col gap-4">
        <Input
          label="Kode OTP"
          inputMode="numeric"
          maxLength={6}
          placeholder="123456"
          value={otpCode}
          onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ''))}
          className="text-center text-lg tracking-[0.5em]"
        />
        <Button type="submit" loading={loading} disabled={otpCode.length !== 6} className="w-full">
          Verifikasi
        </Button>
      </form>
      <div className="mt-4 text-center text-sm text-text-secondary">
        {countdown > 0 ? (
          <span>Kirim ulang kode dalam {countdown} detik</span>
        ) : (
          <button onClick={onResend} disabled={resending} className="font-medium text-primary hover:underline disabled:opacity-50">
            {resending ? 'Mengirim...' : 'Kirim ulang kode OTP'}
          </button>
        )}
      </div>
    </AuthLayout>
  );
}
