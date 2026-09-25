import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Html5Qrcode } from 'html5-qrcode';
import { Link2, QrCode, ArrowRight, Camera, Image, AlertCircle, Sparkles, CheckCircle2 } from 'lucide-react';
import { Button, Input, Card, Badge } from '../../shared/ui';
import { useToast } from '../../shared/Toast';
import { useLangStore } from '../../store/langStore';

function extractFormIdentifier(input) {
  if (!input) return '';
  const trimmed = input.trim();
  
  // If it contains /exam/ or /forms/ in a URL or path
  const examUrlMatch = trimmed.match(/\/exam\/([^/?#]+)/i);
  if (examUrlMatch && examUrlMatch[1]) {
    return examUrlMatch[1];
  }

  const formsUrlMatch = trimmed.match(/\/forms\/([^/?#]+)/i);
  if (formsUrlMatch && formsUrlMatch[1]) {
    return formsUrlMatch[1];
  }

  // If it's a raw URL without /exam/, extract last non-empty path segment
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    try {
      const parsed = new URL(trimmed);
      const segments = parsed.pathname.split('/').filter(Boolean);
      if (segments.length > 0) return segments[segments.length - 1];
    } catch {
      // ignore
    }
  }

  // Otherwise return trimmed value (short code, custom url slug, or ID)
  return trimmed;
}

export default function TakeFormPortalPage() {
  const { t } = useLangStore();
  const navigate = useNavigate();
  const toast = useToast();

  const [activeTab, setActiveTab] = useState('link'); // 'link' | 'qr'
  const [formInput, setFormInput] = useState('');
  const [cameraActive, setCameraActive] = useState(false);
  const [scanningError, setScanningError] = useState('');
  const [scannedResult, setScannedResult] = useState('');
  
  const qrScannerRef = useRef(null);
  const qrRegionId = 'qr-reader-portal-region';

  const handleSubmitLink = (e) => {
    e?.preventDefault?.();
    const identifier = extractFormIdentifier(formInput);
    if (!identifier) {
      toast.error('Silakan masukkan tautan atau kode form ujian');
      return;
    }
    navigate(`/exam/${identifier}`);
  };

  const startCameraScanner = async () => {
    setScanningError('');
    setScannedResult('');
    setCameraActive(true);

    // Wait for DOM element
    setTimeout(async () => {
      try {
        if (qrScannerRef.current) {
          try {
            await qrScannerRef.current.stop();
          } catch {
            // ignore
          }
        }

        const html5QrCode = new Html5Qrcode(qrRegionId);
        qrScannerRef.current = html5QrCode;

        await html5QrCode.start(
          { facingMode: 'environment' },
          {
            fps: 10,
            qrbox: { width: 250, height: 250 },
            aspectRatio: 1.0,
          },
          (decodedText) => {
            const identifier = extractFormIdentifier(decodedText);
            setScannedResult(identifier);
            toast.success('QR Code berhasil dipindai!');
            html5QrCode.stop().then(() => {
              setCameraActive(false);
              navigate(`/exam/${identifier}`);
            }).catch(() => {
              navigate(`/exam/${identifier}`);
            });
          },
          () => {
            // scan failure callback on every frame (ignored)
          }
        );
      } catch (err) {
        setScanningError(err?.message || 'Tidak dapat mengakses kamera. Pastikan izin kamera telah diberikan.');
        setCameraActive(false);
      }
    }, 150);
  };

  const stopCameraScanner = async () => {
    if (qrScannerRef.current) {
      try {
        await qrScannerRef.current.stop();
      } catch {
        // ignore
      }
      qrScannerRef.current = null;
    }
    setCameraActive(false);
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      const html5QrCode = new Html5Qrcode('qr-file-dummy');
      const result = await html5QrCode.scanFile(file, true);
      const identifier = extractFormIdentifier(result);
      toast.success('QR Code dari gambar berhasil dipindai!');
      navigate(`/exam/${identifier}`);
    } catch {
      toast.error('Tidak dapat menemukan QR Code pada gambar yang dipilih.');
    }
  };

  useEffect(() => {
    return () => {
      if (qrScannerRef.current) {
        qrScannerRef.current.stop().catch(() => {});
      }
    };
  }, []);

  return (
    <div className="flex flex-col gap-6 max-w-2xl mx-auto py-2 sm:py-6">
      {/* Header */}
      <div className="text-center space-y-2">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-semibold">
          <Sparkles size={14} />
          Portal Pengerjaan Ujian
        </div>
        <h1 className="text-2xl sm:text-3xl font-bold text-text tracking-tight">
          Kerjakan Form & Ujian
        </h1>
        <p className="text-sm text-text-secondary max-w-md mx-auto">
          Silakan masukkan link form, kode ujian, atau pindai QR Code yang diberikan oleh guru/creator untuk memulai sesi ujian.
        </p>
      </div>

      {/* Mode Selector Tabs */}
      <div className="flex p-1 bg-bg-secondary rounded-xl border border-border">
        <button
          type="button"
          onClick={() => {
            stopCameraScanner();
            setActiveTab('link');
          }}
          className={`flex-1 flex items-center justify-center gap-2 py-2.5 text-sm font-medium rounded-lg transition-all ${
            activeTab === 'link'
              ? 'bg-surface text-primary shadow-sm font-semibold'
              : 'text-text-secondary hover:text-text'
          }`}
        >
          <Link2 size={16} />
          Masukkan Link / Kode
        </button>
        <button
          type="button"
          onClick={() => {
            setActiveTab('qr');
          }}
          className={`flex-1 flex items-center justify-center gap-2 py-2.5 text-sm font-medium rounded-lg transition-all ${
            activeTab === 'qr'
              ? 'bg-surface text-primary shadow-sm font-semibold'
              : 'text-text-secondary hover:text-text'
          }`}
        >
          <QrCode size={16} />
          Scan Code QR
        </button>
      </div>

      {/* Tab 1: Input Link / Code */}
      {activeTab === 'link' && (
        <Card className="flex flex-col gap-5 p-5 sm:p-6 border-primary/20 shadow-sm">
          <form onSubmit={handleSubmitLink} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-semibold text-text flex items-center gap-2">
                <Link2 size={16} className="text-primary" />
                Tautan / Kode Form Ujian
              </label>
              <Input
                value={formInput}
                onChange={(e) => setFormInput(e.target.value)}
                placeholder="Contoh: https://hidocs.id/exam/ipa-8a atau ABCD-1234"
                className="text-sm font-mono"
                autoFocus
              />
              <span className="text-[11px] text-text-secondary">
                Dapat berupa link lengkap form, custom url slug, atau short code 8 digit.
              </span>
            </div>

            <Button
              type="submit"
              variant="primary"
              size="lg"
              disabled={!formInput.trim()}
              className="w-full justify-center gap-2 font-semibold shadow-md shadow-primary/20"
            >
              Mulai Pengerjaan Ujian
              <ArrowRight size={18} />
            </Button>
          </form>

          <div className="rounded-xl bg-bg-secondary p-3.5 border border-border flex items-start gap-3 text-xs text-text-secondary">
            <AlertCircle size={16} className="text-primary shrink-0 mt-0.5" />
            <div>
              <p className="font-medium text-text">Petunjuk Pengerjaan:</p>
              <p className="mt-0.5 leading-relaxed">
                Pastikan kamu memiliki koneksi internet yang stabil. Jika ujian memerlukan token atau data identitas, siapkan sebelum memulai.
              </p>
            </div>
          </div>
        </Card>
      )}

      {/* Tab 2: Scan QR Code */}
      {activeTab === 'qr' && (
        <Card className="flex flex-col gap-5 p-5 sm:p-6 border-primary/20 shadow-sm">
          <div className="text-center space-y-1">
            <h3 className="font-semibold text-text text-base">Pindai QR Code Ujian</h3>
            <p className="text-xs text-text-secondary">
              Arahkan kamera ke QR code yang ditampilkan guru di layar proyektor atau lembar soal.
            </p>
          </div>

          <div className="flex flex-col items-center justify-center gap-4">
            {cameraActive ? (
              <div className="w-full flex flex-col items-center gap-3">
                <div
                  id={qrRegionId}
                  className="w-full max-w-[320px] aspect-square rounded-2xl overflow-hidden border-2 border-primary shadow-lg bg-black"
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={stopCameraScanner}
                  className="text-xs"
                >
                  Tutup Kamera
                </Button>
              </div>
            ) : (
              <div className="w-full max-w-sm aspect-video rounded-2xl border-2 border-dashed border-border bg-bg-secondary flex flex-col items-center justify-center p-6 text-center gap-3">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 text-primary">
                  <Camera size={24} />
                </div>
                <div>
                  <p className="text-sm font-semibold text-text">Kamera Siap Digunakan</p>
                  <p className="text-xs text-text-secondary mt-0.5">
                    Klik tombol di bawah untuk membuka kamera dan memindai QR code secara langsung.
                  </p>
                </div>
                <Button
                  type="button"
                  variant="primary"
                  size="sm"
                  onClick={startCameraScanner}
                  className="gap-2 text-xs"
                >
                  <Camera size={14} />
                  Buka Kamera Scanner
                </Button>
              </div>
            )}

            {scanningError && (
              <div className="w-full rounded-xl bg-red-500/10 border border-red-500/20 p-3 text-xs text-red-600 flex items-center gap-2">
                <AlertCircle size={16} className="shrink-0" />
                <span>{scanningError}</span>
              </div>
            )}

            {/* Fallback File Upload */}
            <div className="w-full pt-3 border-t border-border flex flex-col items-center gap-2">
              <span className="text-xs text-text-secondary">Atau unggah gambar QR Code:</span>
              <label className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg border border-border bg-surface text-xs font-medium text-text cursor-pointer hover:bg-bg-secondary transition-colors">
                <Image size={14} className="text-primary" />
                <span>Pilih Gambar QR dari Perangkat</span>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleFileUpload}
                  className="hidden"
                />
              </label>
              <div id="qr-file-dummy" className="hidden" />
            </div>
          </div>
        </Card>
      )}
    </div>
  );
}
