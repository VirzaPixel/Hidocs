import { create } from 'zustand';
import { aiApi } from '../lib/api';

let intervalId = null;

export const useAIGenerationStore = create((set, get) => ({
  modalOpen: false,
  isGenerating: false,
  progress: 0,
  stageMessage: '',
  elapsedSeconds: 0,
  questionCount: 0,
  result: null,
  error: null,

  openModal: () => set({ modalOpen: true }),
  closeModal: () => set({ modalOpen: false }),

  startGeneration: async (payload, totalQuestions, queryClient, navigate, toast) => {
    if (get().isGenerating) return;

    if (intervalId) clearInterval(intervalId);

    set({
      isGenerating: true,
      progress: 5,
      stageMessage: 'Menganalisis instruksi, topik, dan materi...',
      elapsedSeconds: 0,
      questionCount: totalQuestions || 0,
      result: null,
      error: null,
      modalOpen: true, // Tampilkan modal saat pertama kali start
    });

    const startTime = Date.now();
    intervalId = setInterval(() => {
      const seconds = Math.floor((Date.now() - startTime) / 1000);

      let nextProgress = 5;
      let nextMessage = 'Menganalisis instruksi, topik, dan materi...';

      if (seconds < 6) {
        nextProgress = 10 + Math.min(15, seconds * 2.5);
        nextMessage = 'Menganalisis instruksi, topik, dan materi...';
      } else if (seconds < 25) {
        nextProgress = 25 + Math.min(30, (seconds - 6) * 1.5);
        nextMessage = 'Merumuskan kisi-kisi soal, rumus LaTeX & kode program...';
      } else if (seconds < 60) {
        nextProgress = 55 + Math.min(30, (seconds - 25) * 0.85);
        nextMessage = 'Menyusun opsi pilihan jawaban, distractor & kunci...';
      } else {
        nextProgress = Math.min(95, 85 + (seconds - 60) * 0.1);
        nextMessage = 'Memvalidasi JSON & menyimpan form ke database...';
      }

      set({
        elapsedSeconds: seconds,
        progress: Math.round(nextProgress),
        stageMessage: nextMessage,
      });
    }, 500);

    try {
      const res = await aiApi.generateForm(payload);
      if (intervalId) clearInterval(intervalId);

      set({
        isGenerating: false,
        progress: 100,
        stageMessage: 'Form berhasil dibuat!',
        result: res,
        error: null,
      });

      if (queryClient) {
        await queryClient.invalidateQueries({ queryKey: ['forms'] });
      }

      if (toast) {
        toast.success('Form AI berhasil dibuat!');
      }

      return res;
    } catch (err) {
      if (intervalId) clearInterval(intervalId);
      const errorMsg = err?.response?.data?.message || err.message || 'Gagal membuat form AI';
      set({
        isGenerating: false,
        progress: 0,
        stageMessage: '',
        error: errorMsg,
        result: null,
      });

      if (toast) {
        toast.error(errorMsg);
      }
    }
  },

  dismiss: () => {
    if (intervalId) clearInterval(intervalId);
    set({
      isGenerating: false,
      progress: 0,
      stageMessage: '',
      elapsedSeconds: 0,
      result: null,
      error: null,
      modalOpen: false,
    });
  },
}));
