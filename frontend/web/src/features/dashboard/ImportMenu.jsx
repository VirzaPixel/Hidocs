import { useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FileUp, Loader2, ChevronDown } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Button } from '../../shared/ui';
import { useToast } from '../../shared/Toast';
import { cn } from '../../lib/utils';
import ImportTemplateModal from './ImportTemplateModal';

const IMPORTERS = [
  { key: 'docx', label: 'Import dari Word (.docx)', accept: '.docx', fn: (file) => formApi.importDocx(file) },
  { key: 'excel', label: 'Import dari Excel (.xlsx/.csv)', accept: '.xlsx,.xls,.csv', fn: (file) => formApi.importExcel(file) },
  { key: 'pdf', label: 'Import dari PDF', accept: '.pdf', fn: (file) => formApi.importPdf(file) },
];

export default function ImportMenu() {
  const [open, setOpen] = useState(false);
  const [templateFor, setTemplateFor] = useState(null); // 'docx' | 'excel' | 'pdf' | null
  const [loadingKey, setLoadingKey] = useState(null);
  const fileInputs = useRef({});
  const navigate = useNavigate();
  const toast = useToast();

  const openTemplate = (key) => {
    setOpen(false);
    setTemplateFor(key);
  };

  const handleContinueFromTemplate = () => {
    const key = templateFor;
    setTemplateFor(null);
    fileInputs.current[key]?.click();
  };

  const handleFile = async (importer, e) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    setLoadingKey(importer.key);
    try {
      const form = await importer.fn(file);
      toast.success(`Form berhasil dibuat dari ${importer.label}. Soal & jawaban sudah otomatis terisi — cek ulang sebelum dipublikasikan.`);
      navigate(`/forms/${form.id}`);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoadingKey(null);
    }
  };

  return (
    <div className="relative">
      <Button variant="outline" onClick={() => setOpen((o) => !o)} disabled={!!loadingKey}>
        {loadingKey ? <Loader2 size={16} className="animate-spin" /> : <FileUp size={16} />}
        Import File
        <ChevronDown size={14} />
      </Button>
      {open && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setOpen(false)} />
          <div className="absolute right-0 z-20 mt-1 w-64 rounded-lg border border-border bg-surface py-1 shadow-lg">
            {IMPORTERS.map((imp) => (
              <button
                key={imp.key}
                onClick={() => openTemplate(imp.key)}
                className={cn('block w-full px-3 py-2 text-left text-sm text-text hover:bg-bg-secondary')}
              >
                {imp.label}
              </button>
            ))}
          </div>
        </>
      )}
      {IMPORTERS.map((imp) => (
        <input
          key={imp.key}
          ref={(el) => (fileInputs.current[imp.key] = el)}
          type="file"
          accept={imp.accept}
          className="hidden"
          onChange={(e) => handleFile(imp, e)}
        />
      ))}

      <ImportTemplateModal
        open={!!templateFor}
        type={templateFor}
        onClose={() => setTemplateFor(null)}
        onContinue={handleContinueFromTemplate}
      />
    </div>
  );
}
