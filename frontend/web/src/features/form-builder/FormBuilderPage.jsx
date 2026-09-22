import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft, Plus, Library, Eye, BarChart3, CheckCircle2, RotateCcw, Loader2 } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Button, Input, Badge, Tabs, FullPageSpinner, EmptyState } from '../../shared/ui';
import QuestionEditor from './QuestionEditor';
import AddFromBankModal from './AddFromBankModal';
import FormSettingsPanel from './FormSettingsPanel';
import { useToast } from '../../shared/Toast';
import { FORM_STATUS_META, displayFormStatus } from '../../lib/utils';

const TABS = [
  { value: 'questions', label: 'Soal' },
  { value: 'settings', label: 'Pengaturan' },
];

export default function FormBuilderPage() {
  const { formId } = useParams();
  const navigate = useNavigate();
  const toast = useToast();
  const queryClient = useQueryClient();

  const [activeTab, setActiveTab] = useState('questions');
  const [questions, setQuestions] = useState(null);
  const [addingNew, setAddingNew] = useState(false);
  const [addFromBankOpen, setAddFromBankOpen] = useState(false);
  const [editingTitle, setEditingTitle] = useState(false);
  const [titleDraft, setTitleDraft] = useState('');
  const [publishing, setPublishing] = useState(false);

  const { data: form, isLoading } = useQuery({
    queryKey: ['form', formId],
    queryFn: () => formApi.getById(formId),
  });

  useEffect(() => {
    if (form && questions === null) {
      setQuestions(form.questions || []);
      setTitleDraft(form.title);
    }
  }, [form, questions]);

  const invalidateForm = () => queryClient.invalidateQueries({ queryKey: ['form', formId] });

  const handleSaveTitle = async () => {
    if (!titleDraft.trim()) {
      toast.error('Judul tidak boleh kosong');
      return;
    }
    try {
      await formApi.update(formId, {
        title: titleDraft,
        description: form.description || '',
        category: form.category || '',
        type: form.type,
        custom_url: form.custom_url,
        status: form.status,
        is_template: form.is_template,
      });
      setEditingTitle(false);
      invalidateForm();
      toast.success('Judul diperbarui');
    } catch (err) {
      toast.error(err.message);
    }
  };

  const handleTogglePublish = async () => {
    const nextStatus = form.status === 'ACTIVE' ? 'DRAFT' : 'ACTIVE';
    if (nextStatus === 'ACTIVE' && !questions?.length) {
      toast.error('Tambahkan minimal satu soal sebelum mempublikasikan form');
      return;
    }
    setPublishing(true);
    try {
      await formApi.update(formId, {
        title: form.title,
        description: form.description || '',
        category: form.category || '',
        type: form.type,
        custom_url: form.custom_url,
        status: nextStatus,
        is_template: form.is_template,
      });
      invalidateForm();
      toast.success(nextStatus === 'ACTIVE' ? 'Form dipublikasikan — siswa sudah bisa mengerjakan' : 'Form dikembalikan ke Draft');
    } catch (err) {
      toast.error(err.message);
    } finally {
      setPublishing(false);
    }
  };

  const handleQuestionSaved = (savedQuestion, wasNew) => {
    if (wasNew) {
      setQuestions((prev) => [...prev, savedQuestion]);
      setAddingNew(false);
    } else {
      setQuestions((prev) => prev.map((q) => (q.id === savedQuestion.id ? savedQuestion : q)));
    }
  };

  const handleQuestionDeleted = (id) => {
    setQuestions((prev) => prev.filter((q) => q.id !== id));
  };

  const handleBankAdded = (question) => {
    setQuestions((prev) => [...prev, question]);
  };

  if (isLoading || questions === null) return <FullPageSpinner />;
  if (!form) return null;

  const statusKey = displayFormStatus({ ...form, questions });
  const statusMeta = FORM_STATUS_META[statusKey] || FORM_STATUS_META.DRAFT;

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex min-w-0 flex-1 items-start gap-3">
          <button onClick={() => navigate('/dashboard')} className="mt-1.5 text-text-secondary hover:text-text">
            <ArrowLeft size={20} />
          </button>
          <div className="min-w-0 flex-1">
            {editingTitle ? (
              <div className="flex items-center gap-2">
                <Input
                  value={titleDraft}
                  onChange={(e) => setTitleDraft(e.target.value)}
                  autoFocus
                  className="text-lg font-bold"
                />
                <Button size="sm" onClick={handleSaveTitle}>
                  Simpan
                </Button>
                <Button size="sm" variant="outline" onClick={() => { setEditingTitle(false); setTitleDraft(form.title); }}>
                  Batal
                </Button>
              </div>
            ) : (
              <h1
                className="cursor-pointer text-2xl font-bold text-text hover:underline"
                onClick={() => setEditingTitle(true)}
                title="Klik untuk edit judul"
              >
                {form.title}
              </h1>
            )}
            <div className="mt-1 flex items-center gap-2">
              <Badge className={statusMeta.color}>{statusMeta.label}</Badge>
              <span className="text-xs text-text-secondary">{questions.length} soal</span>
            </div>
          </div>
        </div>

        <div className="flex flex-wrap gap-2">
          <Button variant="outline" size="sm" onClick={() => navigate(`/forms/${formId}/preview`)}>
            <Eye size={14} />
            Preview
          </Button>
          <Button variant="outline" size="sm" onClick={() => navigate(`/forms/${formId}/monitoring`)}>
            <BarChart3 size={14} />
            Monitoring
          </Button>
          <Button
            size="sm"
            variant={form.status === 'ACTIVE' ? 'outline' : 'primary'}
            onClick={handleTogglePublish}
            loading={publishing}
          >
            {form.status === 'ACTIVE' ? (
              <>
                <RotateCcw size={14} />
                Kembalikan ke Draft
              </>
            ) : (
              <>
                <CheckCircle2 size={14} />
                Publikasikan
              </>
            )}
          </Button>
        </div>
      </div>

      <Tabs tabs={TABS} active={activeTab} onChange={setActiveTab} />

      {activeTab === 'questions' ? (
        <div className="flex flex-col gap-3">
          {questions.length === 0 && !addingNew ? (
            <EmptyState
              title="Belum ada soal"
              description="Tambahkan soal pertama, atau ambil dari Bank Soal"
            />
          ) : (
            <>
              {questions.map((q, i) => (
                <QuestionEditor
                  key={q.id}
                  formId={formId}
                  question={q}
                  index={i}
                  onSaved={(saved) => handleQuestionSaved(saved, false)}
                  onDeleted={handleQuestionDeleted}
                />
              ))}
              {addingNew && (
                <QuestionEditor
                  key="new-question"
                  formId={formId}
                  question={null}
                  index={questions.length}
                  defaultExpanded
                  onSaved={(saved) => handleQuestionSaved(saved, true)}
                  onCancelNew={() => setAddingNew(false)}
                />
              )}
            </>
          )}

          <div className="flex gap-2 pt-1">
            <Button variant="outline" onClick={() => setAddingNew(true)} disabled={addingNew}>
              <Plus size={16} />
              Tambah Soal
            </Button>
            <Button variant="outline" onClick={() => setAddFromBankOpen(true)}>
              <Library size={16} />
              Dari Bank Soal
            </Button>
          </div>
        </div>
      ) : (
        <FormSettingsPanel formId={formId} settings={form.form_settings} onSaved={invalidateForm} />
      )}

      <AddFromBankModal
        open={addFromBankOpen}
        onClose={() => setAddFromBankOpen(false)}
        formId={formId}
        onAdded={handleBankAdded}
      />
    </div>
  );
}
