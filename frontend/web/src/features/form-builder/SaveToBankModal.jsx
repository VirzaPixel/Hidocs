import { useState } from 'react';
import { Modal } from '../../shared/Modal';
import { Button, Input, Select } from '../../shared/ui';
import { questionApi } from '../../lib/api';
import { useToast } from '../../shared/Toast';
import { DIFFICULTY_LEVELS } from '../../lib/utils';

export default function SaveToBankModal({ open, onClose, questionId }) {
  const [subject, setSubject] = useState('');
  const [topic, setTopic] = useState('');
  const [difficulty, setDifficulty] = useState('MEDIUM');
  const [loading, setLoading] = useState(false);
  const toast = useToast();

  const handleSave = async () => {
    setLoading(true);
    try {
      await questionApi.saveToBank(questionId, { subject, topic, difficulty });
      toast.success('Soal disimpan ke Bank Soal');
      onClose();
      setSubject('');
      setTopic('');
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Simpan ke Bank Soal"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Batal
          </Button>
          <Button onClick={handleSave} loading={loading}>
            Simpan
          </Button>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <p className="text-sm text-text-secondary">
          Soal akan disalin ke Bank Soal supaya bisa dipakai lagi di form lain nanti. Perubahan pada soal
          ini setelah disimpan TIDAK akan otomatis mengubah salinan di bank (begitu juga sebaliknya).
        </p>
        <Input label="Mata Pelajaran" placeholder="Contoh: Matematika" value={subject} onChange={(e) => setSubject(e.target.value)} />
        <Input label="Topik / Bab" placeholder="Contoh: Pecahan" value={topic} onChange={(e) => setTopic(e.target.value)} />
        <Select label="Tingkat Kesulitan" value={difficulty} onChange={(e) => setDifficulty(e.target.value)}>
          {DIFFICULTY_LEVELS.map((d) => (
            <option key={d.value} value={d.value}>
              {d.label}
            </option>
          ))}
        </Select>
      </div>
    </Modal>
  );
}
