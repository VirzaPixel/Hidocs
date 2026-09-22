import { useQuery } from '@tanstack/react-query';
import { Copy, Download, QrCode } from 'lucide-react';
import { formApi } from '../../lib/api';
import { Button } from '../../shared/ui';
import { useToast } from '../../shared/Toast';

export default function FormAccessPanel({ form }) {
  const toast = useToast();
  const shortCode = form.custom_url || form.id;
  const mobileUrl = `${window.location.origin}/f/${shortCode}`;
  const { data: qrUrl, isLoading, isError } = useQuery({
    queryKey: ['form-qr', shortCode],
    queryFn: async () => {
      const result = await formApi.getQrCode(shortCode);
      return result.qr_code_url;
    },
    enabled: Boolean(shortCode),
    staleTime: 5 * 60 * 1000,
  });

  async function copyUrl() {
    try {
      await navigator.clipboard.writeText(mobileUrl);
      toast.success('Tautan form disalin');
    } catch {
      toast.error('Tautan tidak dapat disalin. Salin manual dari kolom URL.');
    }
  }

  async function downloadQr() {
    if (!qrUrl) return;
    try {
      const response = await fetch(qrUrl);
      const blob = await response.blob();
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement('a');
      anchor.href = url;
      anchor.download = `${shortCode}-qr.png`;
      anchor.click();
      URL.revokeObjectURL(url);
    } catch {
      toast.error('QR code tidak dapat diunduh.');
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h2 className="flex items-center gap-2 text-base font-semibold text-text"><QrCode size={18} /> Akses aplikasi siswa</h2>
        <p className="mt-1 text-sm text-text-secondary">Bagikan tautan atau QR ini untuk membuka form di aplikasi Android.</p>
      </div>
      <div className="flex flex-col gap-2 sm:flex-row">
        <input readOnly value={mobileUrl} className="min-w-0 flex-1 rounded-lg border border-border bg-bg-secondary px-3 py-2 text-sm text-text" />
        <Button variant="outline" onClick={copyUrl}><Copy size={15} /> Salin tautan</Button>
      </div>
      <div className="flex flex-wrap items-center gap-4">
        {isLoading ? <span className="text-sm text-text-secondary">Menyiapkan QR code...</span> : qrUrl ? <img src={qrUrl} alt="QR code form" className="h-36 w-36 rounded-lg border border-border bg-white p-2" /> : <span className="text-sm text-text-secondary">{isError ? 'QR code gagal dibuat.' : 'QR code belum tersedia.'}</span>}
        <Button variant="outline" disabled={!qrUrl} onClick={downloadQr}><Download size={15} /> Unduh QR</Button>
      </div>
    </div>
  );
}
