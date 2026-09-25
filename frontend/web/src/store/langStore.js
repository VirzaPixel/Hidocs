import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export const translations = {
  id: {
    // Navigation & Sidebar
    nav: {
      myForms: 'Form Saya',
      takeForm: 'Kerjakan Form',
      questionBank: 'Bank Soal',
      profile: 'Account',
      adminOverview: 'Ringkasan Admin',
      manageCreators: 'Kelola Creator',
      allForms: 'Semua Form',
      metrics: 'Telemetri & Metrik',
      manageAdmins: 'Kelola Admin',
      logout: 'Kelola Akun / Keluar',
      logoutButton: 'Keluar',
      language: 'Bahasa',
      theme: 'Tema Tampilan',
      adminPanel: 'Admin Panel',
      superAdmin: 'SuperAdmin',
      creatorSpace: 'Ruang Guru',
    },
    // Dashboard
    dashboard: {
      title: 'Form Saya',
      subtitle: 'Kelola form dan soal ujian yang kamu buat',
      createNewForm: 'Buat Form Baru',
      createWithAI: 'Buat dengan AI',
      importWord: 'Word (.docx)',
      importExcel: 'Excel (.xlsx)',
      importPdf: 'PDF Dokumen',
      importMenu: 'Import Dokumen',
      all: 'Semua',
      draft: 'Draft',
      active: 'Aktif',
      closed: 'Ditutup',
      noForms: 'Belum ada form',
      noFormsDesc: 'Mulai buat form atau soal ujian pertamamu',
      questionsCount: 'soal',
      responsesCount: 'respons',
      createdAt: 'Dibuat',
      edit: 'Edit',
      share: 'Bagikan',
      monitoring: 'Monitoring',
      collaboratorBadge: 'Kolaborator',
      deleteFormTitle: 'Hapus form ini?',
      deleteFormDesc: 'seluruh soal dan respons akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
    },
    // Form Builder & Settings
    builder: {
      editorTab: 'Editor Soal',
      settingsTab: 'Pengaturan',
      shareTab: 'Bagikan',
      monitoringTab: 'Monitoring',
      previewTab: 'Preview Siswa',
      saveChanges: 'Simpan',
      saving: 'Menyimpan...',
      unsavedChanges: 'Ada perubahan belum disimpan',
    },
    settings: {
      accessLinkTitle: 'Tautan Akses Form',
      customUrl: 'Custom URL',
      customUrlHint: 'Gunakan huruf kecil, angka, dan tanda hubung.',
      randomizeUrl: 'Acak URL',
      resetToTitleUrl: 'Reset ke Judul',
      scheduleTitle: 'Waktu & Durasi Ujian',
      durationMinutes: 'Durasi Pengerjaan (menit)',
      startTime: 'Mulai',
      endTime: 'Selesai',
      autoActivate: 'Aktifkan otomatis begitu jadwal mulai tiba',
      attemptsTitle: 'Batas Percobaan',
      oneTimeSubmission: 'Satu kali pengerjaan (mode sederhana)',
      maxAttempts: 'Batas jumlah percobaan (0 = tidak dibatasi)',
      securityTitle: 'Keamanan & Navigasi',
      randomizeQuestions: 'Acak urutan soal per siswa',
      randomizeOptions: 'Acak urutan opsi jawaban per siswa',
      allowBacktrack: 'Izinkan siswa kembali ke soal sebelumnya',
      showQuestionNumber: 'Tampilkan nomor soal ke siswa',
      fullscreenMode: 'Wajibkan mode kunci layar (pinned) di aplikasi mobile',
      tokenTitle: 'Token Akses (opsional)',
      tokenProtected: 'Wajibkan kode token untuk masuk ujian',
      tokenCode: 'Kode Token Ujian',
      randomizeToken: 'Acak Token',
      resetToken: 'Reset / Standar',
      clearToken: 'Kosongkan',
      themeTitle: 'Kustomisasi Tema & Tampilan',
      themeDesc: 'Pilih warna tema dan gaya huruf untuk tampilan ujian di aplikasi siswa.',
      themeColor: 'Warna Tema / Aksen',
      fontFamily: 'Gaya Font',
      headerPreview: 'Header Ujian',
      questionPreview: 'Contoh Soal Pilihan Ganda',
      saveSettings: 'Simpan Pengaturan',
      settingsSaved: 'Pengaturan form berhasil disimpan',
      bannerTitle: 'Banner / Cover Form',
      bannerDesc: 'Gambar ini tampil di kartu form pada halaman Form Saya.',
    },
    // Collaborator
    collab: {
      shareMonitoringTitle: 'Bagikan Akses Monitoring',
      shareMonitoringDesc: 'Guru lain yang kamu undang dapat langsung melihat Live Monitoring, Respons, dan Analitik form ini di dashboard mereka secara instan.',
      emailPlaceholder: 'email guru pengawas',
      inviteButton: 'Undang',
      empty: 'Belum ada guru lain yang diundang',
      removeAccess: 'Cabut akses monitoring?',
    },
    // Toast
    toast: {
      loginSuccess: 'Berhasil masuk',
      saved: 'Berhasil disimpan',
      deleted: 'Berhasil dihapus',
      error: 'Terjadi kesalahan',
    },
  },
  en: {
    // Navigation & Sidebar
    nav: {
      myForms: 'My Forms',
      takeForm: 'Take Form',
      questionBank: 'Question Bank',
      profile: 'Profile',
      adminOverview: 'Admin Overview',
      manageCreators: 'Manage Creators',
      allForms: 'All Forms',
      metrics: 'Metrics & Telemetry',
      manageAdmins: 'Manage Admins',
      logout: 'Account / Logout',
      logoutButton: 'Logout',
      language: 'Language',
      theme: 'Display Theme',
      adminPanel: 'Admin Panel',
      superAdmin: 'SuperAdmin',
      creatorSpace: 'Teacher Space',
    },
    // Dashboard
    dashboard: {
      title: 'My Forms',
      subtitle: 'Manage your forms and exam questions',
      createNewForm: 'New Form',
      createWithAI: 'Generate with AI',
      importWord: 'Word (.docx)',
      importExcel: 'Excel (.xlsx)',
      importPdf: 'PDF Document',
      importMenu: 'Import Document',
      all: 'All',
      draft: 'Draft',
      active: 'Active',
      closed: 'Closed',
      noForms: 'No forms yet',
      noFormsDesc: 'Start creating your first form or exam questions',
      questionsCount: 'questions',
      responsesCount: 'responses',
      createdAt: 'Created',
      edit: 'Edit',
      share: 'Share',
      monitoring: 'Monitoring',
      collaboratorBadge: 'Collaborator',
      deleteFormTitle: 'Delete this form?',
      deleteFormDesc: 'all questions and student responses will be permanently removed. This action cannot be undone.',
    },
    // Form Builder & Settings
    builder: {
      editorTab: 'Question Editor',
      settingsTab: 'Settings',
      shareTab: 'Share',
      monitoringTab: 'Monitoring',
      previewTab: 'Student Preview',
      saveChanges: 'Save',
      saving: 'Saving...',
      unsavedChanges: 'You have unsaved changes',
    },
    settings: {
      accessLinkTitle: 'Form Access Link',
      customUrl: 'Custom URL',
      customUrlHint: 'Use lowercase letters, numbers, and hyphens.',
      randomizeUrl: 'Randomize URL',
      resetToTitleUrl: 'Reset to Title',
      scheduleTitle: 'Exam Schedule & Duration',
      durationMinutes: 'Duration (minutes)',
      startTime: 'Start Time',
      endTime: 'End Time',
      autoActivate: 'Activate automatically when scheduled start arrives',
      attemptsTitle: 'Attempt Limits',
      oneTimeSubmission: 'Single submission (simple mode)',
      maxAttempts: 'Max attempts (0 = unlimited)',
      securityTitle: 'Security & Navigation',
      randomizeQuestions: 'Shuffle questions per student',
      randomizeOptions: 'Shuffle answer options per student',
      allowBacktrack: 'Allow students to return to previous questions',
      showQuestionNumber: 'Show question numbers to students',
      fullscreenMode: 'Require screen pin / lock mode on mobile app',
      tokenTitle: 'Access Token (Optional)',
      tokenProtected: 'Require token code to take exam',
      tokenCode: 'Exam Token Code',
      randomizeToken: 'Randomize Token',
      resetToken: 'Reset / Standard',
      clearToken: 'Clear Token',
      themeTitle: 'Theme Customization & Colors',
      themeDesc: 'Customize accent color, header color, and typography for the student exam view.',
      themeColor: 'Theme / Accent Color',
      fontFamily: 'Font Family',
      headerPreview: 'Exam Header',
      questionPreview: 'Sample Multiple Choice Question',
      saveSettings: 'Save Settings',
      settingsSaved: 'Form settings saved successfully',
      bannerTitle: 'Form Cover Banner',
      bannerDesc: 'This image is displayed on the form card in your dashboard.',
    },
    // Collaborator
    collab: {
      shareMonitoringTitle: 'Share Monitoring Access',
      shareMonitoringDesc: 'Invited teachers will immediately see Live Monitoring, Responses, and Analytics for this exam in their dashboard.',
      emailPlaceholder: 'supervisor teacher email',
      inviteButton: 'Invite',
      empty: 'No teachers invited yet',
      removeAccess: 'Revoke monitoring access?',
    },
    // Toast
    toast: {
      loginSuccess: 'Signed in successfully',
      saved: 'Saved successfully',
      deleted: 'Deleted successfully',
      error: 'An error occurred',
    },
  },
};

export const useLangStore = create(
  persist(
    (set, get) => ({
      lang: 'id',
      setLang: (lang) => set({ lang }),
      t: (keyPath, fallback = '') => {
        const lang = get().lang || 'id';
        const keys = keyPath.split('.');
        let current = translations[lang] || translations.id;
        for (const k of keys) {
          if (current && typeof current === 'object' && k in current) {
            current = current[k];
          } else {
            // fallback to indonesian
            let fallbackVal = translations.id;
            for (const fk of keys) {
              if (fallbackVal && typeof fallbackVal === 'object' && fk in fallbackVal) {
                fallbackVal = fallbackVal[fk];
              } else {
                return fallback || keyPath;
              }
            }
            return typeof fallbackVal === 'string' ? fallbackVal : fallback || keyPath;
          }
        }
        return typeof current === 'string' ? current : fallback || keyPath;
      },
    }),
    {
      name: 'hidocs_lang',
    }
  )
);
