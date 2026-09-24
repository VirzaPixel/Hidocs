import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import AuthLayout from '../../shared/layouts/AuthLayout';
import { Button, Input } from '../../shared/ui';
import { authApi } from '../../lib/api';
import { useAuthStore } from '../../store/authStore';
import { useToast } from '../../shared/Toast';

const schema = z.object({
  email: z.string().email('Email tidak valid'),
  password: z.string().min(1, 'Password wajib diisi'),
});

export default function LoginPage() {
  const navigate = useNavigate();
  const login = useAuthStore((s) => s.login);
  const toast = useToast();
  const [loading, setLoading] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm({ resolver: zodResolver(schema) });

  const onSubmit = async (values) => {
    setLoading(true);
    try {
      const res = await authApi.login(values);
      // Simpan access token + refresh token (refresh dipakai otomatis saat 401).
      login(res.token, res.user, res.refresh_token);
      toast.success('Berhasil masuk');
      if (res.user?.role === 'admin' || res.user?.role === 'superadmin') {
        navigate('/admin/dashboard');
      } else {
        navigate('/dashboard');
      }
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout title="Masuk" subtitle="Kelola form dan soal ujianmu">
      <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
        <Input label="Email" type="email" placeholder="email@example.com" error={errors.email?.message} {...register('email')} />
        <Input label="Password" type="password" placeholder="••••••••" error={errors.password?.message} {...register('password')} />
        <div className="flex justify-end">
          <Link to="/forgot-password" className="text-sm text-primary hover:underline">
            Lupa password?
          </Link>
        </div>
        <Button type="submit" loading={loading} className="w-full">
          Masuk
        </Button>
      </form>
      <p className="mt-6 text-center text-sm text-text-secondary">
        Belum punya akun?{' '}
        <Link to="/register" className="font-medium text-primary hover:underline">
          Daftar
        </Link>
      </p>
    </AuthLayout>
  );
}
