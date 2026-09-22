import { useRef, useState } from 'react';
import { Image, Music, Video, Upload, X, Loader2 } from 'lucide-react';
import { questionApi } from '../lib/api';
import { useToast } from './Toast';
import { cn, resolveMediaUrl } from '../lib/utils';

const ACCEPT = {
  IMAGE: 'image/png,image/jpeg,image/jpg,image/webp,image/gif',
  AUDIO: 'audio/mpeg,audio/mp3,audio/wav,audio/ogg',
  VIDEO: 'video/mp4,video/webm',
};

// mediaType: 'IMAGE' | 'AUDIO' | 'VIDEO'. Untuk IMAGE, pakai endpoint upload-image
// (khusus gambar, disimpan sebagai img_url). Untuk AUDIO/VIDEO pakai upload-media.
export default function MediaUploadField({ mediaType = 'IMAGE', value, onChange, label }) {
  const inputRef = useRef(null);
  const [loading, setLoading] = useState(false);
  const toast = useToast();

  const handleFile = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setLoading(true);
    try {
      let url;
      if (mediaType === 'IMAGE') {
        const res = await questionApi.uploadImage(file);
        url = res.img_url || res.url;
      } else {
        const res = await questionApi.uploadMedia(file);
        url = res.media_url;
      }
      onChange(url);
    } catch (err) {
      toast.error(err.message || 'Gagal mengunggah file');
    } finally {
      setLoading(false);
      if (inputRef.current) inputRef.current.value = '';
    }
  };

  const Icon = mediaType === 'IMAGE' ? Image : mediaType === 'AUDIO' ? Music : Video;

  return (
    <div className="flex flex-col gap-2">
      {label && <span className="text-sm font-medium text-text">{label}</span>}
      {value ? (
        <div className="flex items-center gap-3 rounded-lg border border-border bg-bg-secondary p-2">
          {mediaType === 'IMAGE' && (
            <img src={resolveMediaUrl(value)} alt="preview" className="h-16 w-16 rounded object-cover" />
          )}
          {mediaType === 'AUDIO' && <audio src={resolveMediaUrl(value)} controls className="h-10 max-w-[200px]" />}
          {mediaType === 'VIDEO' && <video src={resolveMediaUrl(value)} controls className="h-24 rounded" />}
          <button
            type="button"
            onClick={() => onChange(null)}
            className="ml-auto rounded p-1.5 text-text-secondary hover:bg-danger/10 hover:text-danger"
          >
            <X size={16} />
          </button>
        </div>
      ) : (
        <button
          type="button"
          onClick={() => inputRef.current?.click()}
          disabled={loading}
          className={cn(
            'flex items-center justify-center gap-2 rounded-lg border border-dashed border-border py-3 text-sm text-text-secondary hover:border-primary hover:text-primary'
          )}
        >
          {loading ? <Loader2 size={16} className="animate-spin" /> : <Upload size={16} />}
          <Icon size={16} />
          {loading ? 'Mengunggah...' : `Unggah ${mediaType === 'IMAGE' ? 'Gambar' : mediaType === 'AUDIO' ? 'Audio' : 'Video'}`}
        </button>
      )}
      <input
        ref={inputRef}
        type="file"
        accept={ACCEPT[mediaType]}
        className="hidden"
        onChange={handleFile}
      />
    </div>
  );
}
