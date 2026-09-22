import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ToastProvider } from './shared/Toast';
import ProtectedRoute from './routes/ProtectedRoute';
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
  return (
    <QueryClientProvider client={queryClient}>
      <ToastProvider>
        <BrowserRouter>
          <Routes>
            {/* Auth */}
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/verify-otp" element={<VerifyOtpPage />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/reset-password" element={<ResetPasswordPage />} />

            {/* Protected app */}
            <Route element={<ProtectedRoute />}>
              <Route element={<AppLayout />}>
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/question-bank" element={<QuestionBankPage />} />
                <Route path="/profile" element={<ProfilePage />} />
                <Route path="/forms/:formId" element={<FormBuilderPage />} />
                <Route path="/forms/:formId/preview" element={<StudentPreviewPage />} />
                <Route path="/forms/:formId/monitoring" element={<MonitoringPage />} />
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
