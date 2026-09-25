import { useState } from 'react';
import { Copy, Check, QrCode, Download } from 'lucide-react';
import { Button, Input } from '../../shared/ui';
import { useToast } from '../../shared/Toast';

export default function FormAccessPanel({ form }) {
  const [copiedLink, setCopiedLink] = useState(false);
  const [copiedCode, setCopiedCode] = useState(false);
  const [downloadingQR, setDownloadingQR] = useState(false);
  const toast = useToast();

  const publicUrl = form?.custom_url
    ? `${window.location.origin}/exam/${form.custom_url}`
    : form?.short_code
    ? `${window.location.origin}/exam/${form.short_code}`
    : `${window.location.origin}/exam/${form?.id}`;

  const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=${encodeURIComponent(publicUrl)}&margin=15`;

  const handleCopyLink = () => {
    navigator.clipboard.writeText(publicUrl);
    setCopiedLink(true);
    toast.success('Tautan berhasil disalin');
    setTimeout(() => setCopiedLink(false), 2000);
  };

  const handleCopyCode = () => {
    if (!form?.short_code) return;
    navigator.clipboard.writeText(form.short_code);
    setCopiedCode(true);
    toast.success('Kode ujian berhasil disalin');
    setTimeout(() => setCopiedCode(false), 2000);
  };

  const handleDownloadQR = async () => {
    setDownloadingQR(true);
    try {
      const res = await fetch(qrImageUrl);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      const fileName = `qrcode-${form?.custom_url || form?.title?.toLowerCase().replace(/[^a-z0-9]/g, '-') || 'ujian'}.png`;
      a.download = fileName;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      toast.success('QR Code berhasil diunduh');
    } catch (err) {
      toast.error('Gagal mengunduh QR Code');
    } finally {
      setDownloadingQR(false);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col gap-1">
        <label className="text-sm font-medium text-text">Tautan Ujian Siswa</label>
        <div className="flex gap-2">
          <Input value={publicUrl} readOnly className="font-mono text-xs" />
          <Button variant="outline" onClick={handleCopyLink} className="shrink-0">
            {copiedLink ? <Check size={16} className="text-emerald-500" /> : <Copy size={16} />}
            {copiedLink ? 'Tersalin' : 'Salin'}
          </Button>
        </div>
      </div>

      {form?.short_code && (
        <div className="flex flex-col gap-1">
          <label className="text-sm font-medium text-text">Kode Akses Ujian (Short Code)</label>
          <div className="flex gap-2">
            <Input value={form.short_code} readOnly className="font-mono font-bold tracking-widest text-primary" />
            <Button variant="outline" onClick={handleCopyCode} className="shrink-0">
              {copiedCode ? <Check size={16} className="text-emerald-500" /> : <Copy size={16} />}
              {copiedCode ? 'Tersalin' : 'Salin'}
            </Button>
          </div>
        </div>
      )}

      {form?.form_settings?.is_token_protected && form?.form_settings?.exam_token && (
        <div className="rounded-lg bg-amber-500/10 p-3 text-xs text-amber-600 border border-amber-500/20">
          <p className="font-semibold">Token Proteksi Ujian:</p>
          <p className="mt-0.5 font-mono text-sm font-bold tracking-wider">{form.form_settings.exam_token}</p>
        </div>
      )}

      <div className="flex flex-col items-center justify-center gap-3 rounded-xl border border-border bg-bg-secondary p-4">
        <span className="text-xs font-semibold text-text-secondary flex items-center gap-1.5">
          <QrCode size={15} className="text-primary" />
          QR Code Ujian Siswa
        </span>
        <div className="rounded-xl bg-white p-2.5 shadow-sm border border-border">
          <img
            src={`https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${encodeURIComponent(publicUrl)}&margin=10`}
            alt="QR Code Ujian"
            className="h-36 w-36 object-contain"
          />
        </div>
        <p className="text-[11px] text-text-secondary text-center max-w-xs">
          Siswa dapat langsung memindai QR code ini di aplikasi mobile untuk masuk ke sesi ujian.
        </p>
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={handleDownloadQR}
          loading={downloadingQR}
          className="mt-1"
        >
          <Download size={15} />
          Download QR Code
        </Button>
      </div>
    </div>
  );
}
