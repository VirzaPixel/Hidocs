import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import AuthLayout from '../../shared/layouts/AuthLayout';
import { Button, Input } from '../../shared/ui';
import { authApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';

const schema = z.object({
  name: z.string().min(2, 'Nama minimal 2 karakter'),
  email: z.string().email('Email tidak valid'),
  password: z.string().min(6, 'Password minimal 6 karakter'),
});

export default function RegisterPage() {
  const navigate = useNavigate();
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
      const res = await authApi.register(values);
      toast.success('Kode OTP telah dikirim ke email kamu');
      navigate('/verify-otp', { state: { email: res?.email || values.email } });
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout title="Buat Akun Guru" subtitle="Mulai buat form dan soal ujian dalam hitungan menit">
      <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
        <Input label="Nama Lengkap" placeholder="Nama kamu" error={errors.name?.message} {...register('name')} />
        <Input label="Email" type="email" placeholder="email@example.com" error={errors.email?.message} {...register('email')} />
        <Input label="Password" type="password" placeholder="Minimal 6 karakter" error={errors.password?.message} {...register('password')} />
        <Button type="submit" loading={loading} className="w-full">
          Daftar
        </Button>
      </form>
      <p className="mt-6 text-center text-sm text-text-secondary">
        Sudah punya akun?{' '}
        <Link to="/login" className="font-medium text-primary hover:underline">
          Masuk
        </Link>
      </p>
    </AuthLayout>
  );
}
