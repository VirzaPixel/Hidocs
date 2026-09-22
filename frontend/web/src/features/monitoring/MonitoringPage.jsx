import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Download, Loader2 } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Tabs, Button, FullPageSpinner, Badge } from '../../shared/ui';
import { FORM_STATUS_META, downloadExport } from '../../lib/utils';
import { useToast } from '../../shared/Toast';
import { useAuthStore } from '../../store/authStore';
import LiveTab from './LiveTab';
import ResponsesTab from './ResponsesTab';
import AnalyticsTab from './AnalyticsTab';
import GradingTab from './GradingTab';
import CollaboratorsTab from './CollaboratorsTab';

function buildTabs(isOwner) {
  const base = [
    { value: 'live', label: 'Live Monitoring' },
    { value: 'responses', label: 'Respons' },
    { value: 'analytics', label: 'Analitik' },
    { value: 'grading', label: 'Penilaian Esai' },
  ];
  // Kelola akses share-monitoring cuma boleh dilakukan pemilik form — backend
  // menolak (403) kalau kolaborator ikut mencoba invite/list/remove kolaborator lain.
  if (isOwner) base.push({ value: 'collaborators', label: 'Bagikan Monitoring' });
  return base;
}

export default function MonitoringPage() {
  const { formId } = useParams();
  const navigate = useNavigate();
  const toast = useToast();
  const currentUser = useAuthStore((s) => s.user);
  const [activeTab, setActiveTab] = useState('live');
  const [exporting, setExporting] = useState(false);

  const { data: form, isLoading } = useQuery({
    queryKey: ['form', formId],
    queryFn: () => formApi.getById(formId),
  });

  const isOwner = !!form && !!currentUser && form.user_id === currentUser.id;
  const tabs = buildTabs(isOwner);

  const handleExport = async () => {
    setExporting(true);
    try {
      await downloadExport(formId, form?.title);
    } catch (err) {
      toast.error(err.message || 'Gagal mengunduh hasil');
    } finally {
      setExporting(false);
    }
  };

  if (isLoading) return <FullPageSpinner />;
  if (!form) return null;

  const statusMeta = FORM_STATUS_META[form.status] || FORM_STATUS_META.DRAFT;

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex items-start gap-3">
          <button onClick={() => navigate(`/forms/${formId}`)} className="mt-1.5 text-text-secondary hover:text-text">
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-text">{form.title}</h1>
            <div className="mt-1 flex items-center gap-2">
              <Badge className={statusMeta.color}>{statusMeta.label}</Badge>
              <span className="text-xs text-text-secondary">{form.response_count || 0} respons masuk</span>
            </div>
          </div>
        </div>
        <Button variant="outline" onClick={handleExport} loading={exporting}>
          <Download size={16} />
          Ekspor Hasil
        </Button>
      </div>

      <Tabs tabs={tabs} active={activeTab} onChange={setActiveTab} />

      {activeTab === 'live' && <LiveTab formId={formId} />}
      {activeTab === 'responses' && <ResponsesTab formId={formId} />}
      {activeTab === 'analytics' && <AnalyticsTab formId={formId} />}
      {activeTab === 'grading' && <GradingTab formId={formId} />}
      {activeTab === 'collaborators' && isOwner && <CollaboratorsTab formId={formId} />}
    </div>
  );
}
