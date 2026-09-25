import { Navigate, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';

export default function PublicRoute() {
  const token = useAuthStore((s) => s.token);
  const user = useAuthStore((s) => s.user);

  if (token) {
    if (user?.role === 'admin' || user?.role === 'superadmin') {
      return <Navigate to="/admin/dashboard" replace />;
    }
    return <Navigate to="/dashboard" replace />;
  }

  return <Outlet />;
}
