import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ToastProvider } from './shared/Toast';
import ProtectedRoute from './routes/ProtectedRoute';
import PublicRoute from './routes/PublicRoute';
import AppLayout from './shared/layouts/AppLayout';

import LoginPage from './features/auth/LoginPage';
import RegisterPage from './features/auth/RegisterPage';
import VerifyOtpPage from './features/auth/VerifyOtpPage';
import ForgotPasswordPage from './features/auth/ForgotPasswordPage';
import ResetPasswordPage from './features/auth/ResetPasswordPage';

import DashboardPage from './features/dashboard/DashboardPage';
import FormBuilderPage from './features/form-builder/FormBuilderPage';
import QuestionBankPage from './features/question-bank/QuestionBankPage';
import MonitoringPage from './features/monitoring/MonitoringPage';
import StudentPreviewPage from './features/preview/StudentPreviewPage';
import ProfilePage from './features/profile/ProfilePage';
import TakeFormPortalPage from './features/take/TakeFormPortalPage';
import ExamTakePage from './features/take/ExamTakePage';

import AdminDashboardPage from './features/admin/AdminDashboardPage';
import CreatorManagementPage from './features/admin/CreatorManagementPage';
import AdminFormsPage from './features/admin/AdminFormsPage';
import AdminMetricsPage from './features/admin/AdminMetricsPage';
import SuperadminAdminsPage from './features/admin/SuperadminAdminsPage';
import { useTheme } from './lib/useTheme';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 15000,
    },
  },
});

export default function App() {
  useTheme();

  return (
    <QueryClientProvider client={queryClient}>
      <ToastProvider>
        <BrowserRouter>
          <Routes>
            {/* Public Exam Taker Route */}
            <Route path="/exam/:identifier" element={<ExamTakePage />} />

            {/* Public Auth Routes */}
            <Route element={<PublicRoute />}>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />
              <Route path="/verify-otp" element={<VerifyOtpPage />} />
              <Route path="/forgot-password" element={<ForgotPasswordPage />} />
              <Route path="/reset-password" element={<ResetPasswordPage />} />
            </Route>

            {/* Protected app - All Logged In Users */}
            <Route element={<ProtectedRoute />}>
              <Route element={<AppLayout />}>
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/take" element={<TakeFormPortalPage />} />
                <Route path="/question-bank" element={<QuestionBankPage />} />
                <Route path="/profile" element={<ProfilePage />} />
                <Route path="/forms/:formId" element={<FormBuilderPage />} />
                <Route path="/forms/:formId/preview" element={<StudentPreviewPage />} />
                <Route path="/forms/:formId/monitoring" element={<MonitoringPage />} />
              </Route>
            </Route>

            {/* Protected app - Admin & SuperAdmin Exclusive */}
            <Route element={<ProtectedRoute allowedRoles={['admin', 'superadmin']} />}>
              <Route element={<AppLayout />}>
                <Route path="/admin/dashboard" element={<AdminDashboardPage />} />
                <Route path="/admin/creators" element={<CreatorManagementPage />} />
                <Route path="/admin/forms" element={<AdminFormsPage />} />
                <Route path="/admin/metrics" element={<AdminMetricsPage />} />
              </Route>
            </Route>

            {/* Protected app - SuperAdmin Exclusive */}
            <Route element={<ProtectedRoute allowedRoles={['superadmin']} />}>
              <Route element={<AppLayout />}>
                <Route path="/superadmin/admins" element={<SuperadminAdminsPage />} />
              </Route>
            </Route>

            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </QueryClientProvider>
  );
}

