// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'HiDocs';

  @override
  String get appTagline => 'Form dinamis & kuis pintar';

  @override
  String get login => 'Masuk';

  @override
  String get register => 'Daftar';

  @override
  String get user => 'Pengguna';

  @override
  String get email => 'Email';

  @override
  String get password => 'Kata Sandi';

  @override
  String get confirmPassword => 'Konfirmasi Kata Sandi';

  @override
  String get fullName => 'Nama Lengkap';

  @override
  String get username => 'Username';

  @override
  String get createAccount => 'Buat Akun';

  @override
  String get dontHaveAccount => 'Belum punya akun? ';

  @override
  String get haveAccount => 'Sudah punya akun? ';

  @override
  String get signUpNow => 'Daftar sekarang';

  @override
  String get loginNow => 'Masuk sekarang';

  @override
  String get otpVerification => 'Verifikasi OTP';

  @override
  String get enterOtp => 'Masukkan kode OTP';

  @override
  String get verify => 'Verifikasi';

  @override
  String get resendCode => 'Kirim ulang kode';

  @override
  String get welcomeBack => 'Selamat datang kembali';

  @override
  String get backToLogin => 'Kembali ke Login';

  @override
  String get home => 'Beranda';

  @override
  String get history => 'Riwayat';

  @override
  String get settings => 'Pengaturan';

  @override
  String get about => 'Tentang';

  @override
  String get search => 'Cari';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get delete => 'Hapus';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Tutup';

  @override
  String get submit => 'Kirim';

  @override
  String get next => 'Berikutnya';

  @override
  String get previous => 'Sebelumnya';

  @override
  String get back => 'Kembali';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'Tidak';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get loading => 'Memuat...';

  @override
  String get optional => 'Opsional';

  @override
  String get required => 'Wajib';

  @override
  String get retry => 'Coba lagi';

  @override
  String get none => 'Tidak ada';

  @override
  String get all => 'Semua';

  @override
  String get searchPlaceholder => 'Cari...';

  @override
  String nQuestions(Object count) {
    return '$count soal';
  }

  @override
  String get active => 'Aktif';

  @override
  String get closed => 'Ditutup';

  @override
  String get inactive => 'Nonaktif';

  @override
  String get status => 'Status';

  @override
  String get type => 'Tipe';

  @override
  String get date => 'Tanggal';

  @override
  String get time => 'Waktu';

  @override
  String get language => 'Bahasa';

  @override
  String get language_switch_title => 'Bahasa / Language';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get english => 'English';

  @override
  String get question => 'Soal';

  @override
  String get fillForm => 'Isi Form';

  @override
  String get submitResponse => 'Kirim Jawaban';

  @override
  String get yourAnswers => 'Jawaban Anda';

  @override
  String get detail => 'Detail';

  @override
  String get score => 'Skor';

  @override
  String get points => 'Poin';

  @override
  String get totalScore => 'Total Skor';

  @override
  String get responses => 'Respons';

  @override
  String get chooseMultiple => 'Pilih lebih dari satu jawaban';

  @override
  String get notSelected => 'Belum dipilih';

  @override
  String outOfStars(Object max, Object value) {
    return '$value dari $max bintang';
  }

  @override
  String get flagged => 'Ditandai ragu-ragu';

  @override
  String get answered => 'Dijawab';

  @override
  String get notAnswered => 'Belum dijawab';

  @override
  String get current => 'Sekarang';

  @override
  String get questionNumber => 'Nomor Soal';

  @override
  String get questionsSummary => 'Ringkasan soal';

  @override
  String get colorScheme => 'Skema Warna';

  @override
  String get pickColorScheme => 'Pilih Tema Warna';

  @override
  String get pickColorSchemeSubtitle => 'Kustomisasi warna sendiri';

  @override
  String get customColor => 'Warna Kustom';

  @override
  String get customActive => 'Kustom aktif';

  @override
  String get pickColor => 'Pilih Warna';

  @override
  String get pickCustomColor => 'Pilih Warna Kustom';

  @override
  String get pickAnyColor => 'Pilih warna apa pun yang kamu mau';

  @override
  String get apply => 'Terapkan';

  @override
  String get editProfile => 'Edit Profil';

  @override
  String get emailCannotChange => 'Email tidak dapat diubah';

  @override
  String get profileUpdated => 'Profil berhasil diperbarui';

  @override
  String get logout => 'Keluar';

  @override
  String get account => 'Akun';

  @override
  String get appearance => 'Tampilan';

  @override
  String get others => 'Lainnya';

  @override
  String get profile => 'Profil';

  @override
  String get authTokenTitle => 'Token Akses';

  @override
  String get shareToken =>
      'Bagikan token ini kepada peserta. Token bersifat rahasia.';

  @override
  String get enterToken => 'Masukkan token akses';

  @override
  String get scanForm => 'Scan Form';

  @override
  String get scanInstruction => 'Arahkan kamera ke QR / barcode form';

  @override
  String get scanSuccess => 'Form ditemukan!';

  @override
  String get scanFailed => 'Barcode / link tidak valid. Coba lagi.';

  @override
  String get linkInput => 'Masukkan Link';

  @override
  String get enterFormLink => 'Masukkan link form';

  @override
  String get answerRequired =>
      'Mohon jawab semua pertanyaan wajib terlebih dahulu.';

  @override
  String get submitSuccess => 'Jawaban Anda berhasil dikirim.';

  @override
  String get thankYou => 'Terima Kasih!';

  @override
  String get timeUpAutoSubmit => 'Waktu habis! Jawaban Anda dikirim otomatis.';

  @override
  String get noHistory => 'Belum ada riwayat';

  @override
  String get member => 'Anggota';

  @override
  String memberSince(Object year) {
    return 'Bergabung sejak $year';
  }

  @override
  String get totalResponse => 'Total Respons';

  @override
  String get joined => 'Bergabung';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get uploadImage => 'Unggah Gambar';

  @override
  String get removeImage => 'Hapus Gambar';

  @override
  String get imagePickError => 'Gagal memuat gambar.';

  @override
  String get loginScreenTitle => 'Masuk ke Akun';

  @override
  String get loginScreenSubtitle => 'Silakan login untuk melanjutkan';

  @override
  String get wrongEmail => 'Email tidak valid';

  @override
  String get passMin6 => 'Minimal 6 karakter';

  @override
  String get signIn => 'Masuk';

  @override
  String get min3 => 'Minimum 3 karakter';

  @override
  String get min6 => 'Minimum 6 karakter';

  @override
  String get emailRequired => 'Email wajib diisi';

  @override
  String get passRequired => 'Kata sandi wajib diisi';

  @override
  String get userRequired => 'Username wajib diisi';

  @override
  String get nameRequired => 'Nama wajib diisi';

  @override
  String get invalidEmailFmt => 'Format email tidak valid';

  @override
  String get registerTitle => 'Daftar & Mulai';

  @override
  String get registerSubtitle => 'Mari bergabung bersama HiDocs!';

  @override
  String get verifyEmailBtn => 'Verifikasi Email';

  @override
  String get verifyCreate => 'Verifikasi OTP';

  @override
  String get otpCode => 'Kode OTP';

  @override
  String get otp6digit => 'Masukkan 6 digit kode OTP';

  @override
  String get otpDesc =>
      'Masukkan kode OTP 6 digit yang dikirim ke email berikut untuk menyelesaikan pendaftaran.';

  @override
  String get otp180 =>
      'Kode OTP berlaku selama 180 detik. Periksa juga folder spam email Anda.';

  @override
  String otpSentTo(Object email) {
    return 'Kode OTP telah dikirim ke $email.';
  }

  @override
  String get registerSuccessLogin => 'Pendaftaran berhasil! Silakan login.';

  @override
  String get backToRegister => 'Edit data pendaftaran';

  @override
  String get resendOtp => 'Kirim Ulang OTP';

  @override
  String resendInSec(Object s) {
    return 'Kirim ulang dalam $s detik';
  }

  @override
  String get emailPlaceholder => 'nama@domain.com';

  @override
  String get emailAddress => 'Alamat Email';

  @override
  String get emailExample => 'nama@domain.com';

  @override
  String get usernameHint => 'Pilih sebuah username';

  @override
  String get code6Hint => 'Masukkan kode 6 digit';

  @override
  String get fillWorkForm => 'Isi & kerjakan form';

  @override
  String get formDigitalPlatform => 'Platform form & ujian digital';

  @override
  String get greetHi => 'Halo, ';

  @override
  String get helloWave => 'Selamat datang 👋';

  @override
  String get noFormsYetU => 'Belum ada form yang diisi';

  @override
  String get noHistoryYet => 'Belum ada riwayat';

  @override
  String get noHistorySub => 'Form yang sudah kamu isi akan muncul di sini';

  @override
  String get lastHistory => 'Riwayat Terakhir';

  @override
  String get seeAll => 'Lihat semua';

  @override
  String get noResultFilter => 'Tidak ada form yang cocok';

  @override
  String get changeFilter => 'Coba ubah filter atau kata kunci.';

  @override
  String get noResponseYet => 'Belum ada respons';

  @override
  String get formImageGagal => 'Gambar gagal dimuat';

  @override
  String get formDetail => 'Detail Form';

  @override
  String get formInfoSub => 'Baca informasi di bawah sebelum mengisi form ini.';

  @override
  String get startFill => 'Mulai Mengisi Form';

  @override
  String get fillAsExam =>
      'Ini adalah form ujian. Pastikan kamu sudah siap sebelum memulai.';

  @override
  String get duration => 'Durasi';

  @override
  String timerMinutesStr(Object m) {
    return '$m menit';
  }

  @override
  String get closedStatus => 'Ditutup';

  @override
  String get activeStatus => 'Aktif';

  @override
  String get draftStatus => 'Nonaktif';

  @override
  String get noQuestionYet => 'Belum ada soal';

  @override
  String get whichToken => 'Diperlukan token dari pembuat form';

  @override
  String get timerStartNote =>
      'Waktu berjalan setelah form dimulai dan tidak bisa dihentikan.';

  @override
  String get examReadyNote => 'Pastikan kamu siap sebelum memulai.';

  @override
  String get autoSubmitNote => 'Jawaban dikirim otomatis saat waktu habis.';

  @override
  String get noQuestionsYetF => 'Form ini tidak memiliki soal.';

  @override
  String get pleaseWait => 'Mohon tunggu...';

  @override
  String get processing => 'Memproses...';

  @override
  String get emptyResults => 'Tidak ada hasil untuk ditampilkan.';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Urutkan';

  @override
  String get reset => 'Reset';

  @override
  String get formResult => 'Hasil Form';

  @override
  String get historyTitle => 'Riwayat';

  @override
  String get noHistoryU => 'Belum ada riwayat';

  @override
  String get historyAnswer => 'Detail Jawaban';

  @override
  String get historySubmitted => 'Dikirim';

  @override
  String get participant => 'Peserta';

  @override
  String valueScore(Object score) {
    return 'Nilai: $score';
  }

  @override
  String get noSubmissionHistory => 'Belum ada riwayat pengisian';

  @override
  String scorePct(Object score) {
    return 'Skor $score%';
  }

  @override
  String nilaiMax(Object max, Object score) {
    return 'Nilai: $score / $max';
  }

  @override
  String nilaiOnly(Object score) {
    return 'Nilai: $score';
  }

  @override
  String get answerLabel => 'Jawaban';

  @override
  String questionOf(Object c, Object total) {
    return 'Soal $c / $total';
  }

  @override
  String get questionNo => 'Nomor Soal';

  @override
  String get legendAnswer => 'Dijawab';

  @override
  String get legendFlag => 'Ragu-ragu';

  @override
  String get legendBlank => 'Belum';

  @override
  String get legendNow => 'Sekarang';

  @override
  String get flagForReview => 'Tandai ragu-ragu';

  @override
  String get flaggedReview => 'Ditandai ragu-ragu';

  @override
  String get unflag => 'Tanda ragu-ragu dihapus';

  @override
  String get flagAdded => 'Soal ditandai ragu-ragu';

  @override
  String flagCountNote(Object n) {
    return '$n soal ditandai ragu-ragu';
  }

  @override
  String get shortAnsHint => 'Tulis jawaban singkat...';

  @override
  String get typingAnsHint => 'Tulis jawaban Anda...';

  @override
  String get writeCodeHint => 'Tulis jawaban kode di sini...';

  @override
  String get writeFormulaHint => 'Tulis jawaban atau rumus...';

  @override
  String get leftCol => 'Kolom Kiri';

  @override
  String get rightCol => 'Kolom Kanan';

  @override
  String get choosePair => 'Pilih Pasangan';

  @override
  String get pick => 'Pilih...';

  @override
  String get clearChoice => 'Kosongkan';

  @override
  String get submitAnswer => 'Kirim Jawaban';

  @override
  String get timeUp => 'Waktu Habis';

  @override
  String get notAnsweredDash => '— Tidak dijawab —';

  @override
  String get preparingImages => 'Menyiapkan gambar soal...';

  @override
  String convertingImages(Object done, Object total) {
    return 'Mengubah soal menjadi gambar ($done/$total)';
  }

  @override
  String get zoomOut => 'Perkecil';

  @override
  String get zoomIn => 'Perbesar';

  @override
  String get failSendResp => 'Gagal mengirim jawaban. Periksa jaringan Anda.';

  @override
  String get backToHome => 'Kembali ke Beranda';

  @override
  String get askTokenFrom => 'Minta token dari pembuat form atau pengawas.';

  @override
  String get wrongToken => 'Token salah';

  @override
  String get tokenEnsureCorrect => ' — pastikan token benar';

  @override
  String get checking => 'Memeriksa...';

  @override
  String get continueAction => 'Lanjutkan';

  @override
  String get formAccessToken => 'Token Akses Form';

  @override
  String get hide => 'Sembunyikan';

  @override
  String get show => 'Tampilkan';

  @override
  String get tokenCopied => 'Token akses disalin';

  @override
  String get enterLinkFirst => 'Masukkan link form terlebih dahulu.';

  @override
  String get formNotFound => 'Form tidak ditemukan.';

  @override
  String get alreadySubmitted => 'Anda sudah mengisi form ini';

  @override
  String get pasteLinkToOpen =>
      'Tempel link form untuk membuka dan mengisinya.';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get loadingForm => 'Memuat Form...';

  @override
  String get infoExamTime => 'Waktu Ujian';

  @override
  String get infoToken => 'Token';

  @override
  String get afterSubmitCant =>
      'Setelah submit, kamu tidak bisa mengisi form ini lagi.';

  @override
  String get enterTokenStart => 'Masukkan Token & Mulai';

  @override
  String get hdImage => 'Gambar HD';

  @override
  String get statQuestions => 'Soal';

  @override
  String get themeCustomize => 'Kustom Tema';

  @override
  String get pilihBahasa => 'Pilih bahasa';

  @override
  String get themeImage => 'Gambar Header';

  @override
  String get themeImageDesc => 'Pakai foto sebagai latar header dashboard';

  @override
  String get themeReset => 'Kembalikan ke Tema Standar';

  @override
  String get themeResetPrompt =>
      'Atur ulang warna & gambar header ke tema standar HiDocs';

  @override
  String get themeResetConfirm => 'Yakin ingin mengembalikan tema ke standar?';

  @override
  String get themeResetDone => 'Tema berhasil dikembalikan ke standar';

  @override
  String get themeImagePicked => 'Gambar diterapkan sebagai tema';

  @override
  String get themePickImage => 'Pilih Gambar';

  @override
  String get themeRemoveImage => 'Hapus Gambar';

  @override
  String get pickImageFailed => 'Gagal membaca gambar yang dipilih';

  @override
  String get navLegendAnswered => 'Sudah dijawab';

  @override
  String get navLegendFlagged => 'Ditandai / Ragu-ragu';

  @override
  String get navLegendUnanswered => 'Belum dijawab';

  @override
  String get navLegendCurrent => 'Soal saat ini';

  @override
  String get flagQuestion => 'Tandai ragu-ragu';

  @override
  String get unflagQuestion => 'Hapus tanda ragu-ragu';

  @override
  String flaggedSummary(Object count) {
    return 'Soal ditandai: $count';
  }

  @override
  String answeredSummary(Object count) {
    return 'Sudah dijawab: $count';
  }

  @override
  String get tokenRequiredErr => 'Masukkan token ujian untuk melanjutkan';

  @override
  String get scoreCorrect => 'Benar';

  @override
  String get scoreIncorrect => 'Salah';

  @override
  String get scoreLabel => 'Nilai';

  @override
  String get scoreFinal => 'Nilai Akhir';

  @override
  String get questionPoint => 'Poin';

  @override
  String get questionAnswered => 'Terjawab';

  @override
  String get aboutApp => 'Tentang Aplikasi';

  @override
  String get madeWith => 'Dibuat dengan ❤';

  @override
  String get aboutDesc =>
      'HiDocs adalah platform form dinamis dan kuis otomatis berbasis web modern.';

  @override
  String get aboutHiDocsDesc =>
      'HiDocs! adalah aplikasi yang memudahkan pengguna untuk mengakses dan mengisi form digital, kuis, dan ujian online. Pengguna dapat mengakses form melalui link atau QR Code, mengirim jawaban dengan mudah, serta melihat riwayat pengisian dan hasil respons.';

  @override
  String get userFeaturesTitle => 'Fitur Pengguna';

  @override
  String get featAccessForms => 'Akses Form lewat Link atau QR Code';

  @override
  String get featFillForms => 'Isi Form';

  @override
  String get featViewHistory => 'Lihat Riwayat Pengisian';

  @override
  String get featOneTimeSubmission => 'Pengisian Satu Kali';

  @override
  String get thanksForUsing => 'Terima kasih telah menggunakan HiDocs!';

  @override
  String get connectionFailed => 'Koneksi gagal.';

  @override
  String get failedGeneric => 'Gagal';

  @override
  String get failedDot => 'Gagal.';

  @override
  String get networkError => 'Gagal terhubung. Periksa koneksi internet Anda.';

  @override
  String get tryAgain => 'Silakan coba lagi.';

  @override
  String get loadFailedConn => 'Gagal memuat. Periksa koneksi.';

  @override
  String errOccurred(Object error) {
    return 'Terjadi kesalahan: $error';
  }

  @override
  String failedErr(Object error) {
    return 'Gagal: $error';
  }

  @override
  String errorErr(Object error) {
    return 'Error: $error';
  }

  @override
  String get invalidEmail => 'Masukkan email yang valid';

  @override
  String get invalidPassword => 'Kata sandi minimal 8 karakter';

  @override
  String get requiredField => 'Kolom ini wajib diisi';

  @override
  String get fillAllFields => 'Mohon lengkapi semua kolom.';

  @override
  String get passwordNotMatch => 'Kata sandi tidak cocok';

  @override
  String get otpSentSuccess => 'Kode OTP baru telah dikirim ke email Anda.';

  @override
  String get otpInvalid => 'Kode OTP tidak valid atau sudah kedaluwarsa.';

  @override
  String get registerSuccess => 'Pendaftaran berhasil';

  @override
  String get accountCreated => 'Akun berhasil dibuat.';

  @override
  String get welcome => 'Selamat Datang!';

  @override
  String get loginSuccess => 'Login berhasil.';

  @override
  String get loginFailed => 'Login gagal. Periksa kembali data Anda.';

  @override
  String get copy => 'Salin';

  @override
  String get copied => 'Disalin ke clipboard';

  @override
  String get share => 'Bagikan';

  @override
  String get scanQrAction => 'Scan QR';

  @override
  String get pasteLinkAction => 'Tempel Link';

  @override
  String helloNameWave(Object name) {
    return 'Halo, $name 👋';
  }

  @override
  String get notFound => 'Tidak ditemukan';

  @override
  String get lightMode => 'Mode Terang';

  @override
  String get darkMode => 'Mode Gelap';

  @override
  String get accessRangeLabel => 'Rentang Akses';

  @override
  String get activateImmediatelySub => 'Form langsung aktif setelah disimpan';

  @override
  String get activateImmediatelyTitle => 'Aktifkan Sekarang';

  @override
  String get addAtLeastOneQuestion => 'Tambahkan minimal satu soal';

  @override
  String get addOptionLabel => 'Tambah Opsi';

  @override
  String get addQuestionLabel => 'Tambah Soal';

  @override
  String get assignPointsLabel => 'Beri Poin';

  @override
  String get closeLabel => 'Tutup';

  @override
  String get closeMustBeAfterOpen => 'Waktu tutup harus setelah waktu buka';

  @override
  String get closeTimeBeforeOpenTime =>
      'Waktu tutup tidak boleh sebelum waktu buka';

  @override
  String get codePlaceholder => 'Tulis kode di sini...';

  @override
  String get correctAnswerOptional => 'Jawaban benar (opsional)';

  @override
  String get createForm => 'Buat Form';

  @override
  String get customLinkHint => 'cth: kuis-matematika-10';

  @override
  String get customLinkLabel => 'Link Kustom';

  @override
  String get deleteOptionTooltip => 'Hapus opsi';

  @override
  String get deleteQuestionTooltip => 'Hapus soal';

  @override
  String get editBlockedHasResponses =>
      'Form tidak dapat diedit karena sudah ada respons';

  @override
  String get editForm => 'Edit Form';

  @override
  String get enterLatexFormula => 'Masukkan rumus LaTeX';

  @override
  String get examDurationHintText => 'Kosongkan jika tanpa batas waktu';

  @override
  String get examDurationLabel => 'Durasi Ujian';

  @override
  String get examModeSub => 'Dengan timer, nilai, dan jawaban benar';

  @override
  String get examModeTitle => 'Mode Ujian';

  @override
  String get failedToInsertImage => 'Gagal menyisipkan gambar';

  @override
  String get finishingUp => 'Menyelesaikan...';

  @override
  String get formBehaviorLabel => 'Perilaku Form';

  @override
  String get formCreatedSuccess => 'Form berhasil dibuat';

  @override
  String get formInformation => 'Informasi Form';

  @override
  String get formLinkDesc =>
      'Bagikan link ini agar orang lain bisa mengisi form';

  @override
  String get formLinkLabel => 'Link Form';

  @override
  String get formSaveError => 'Gagal menyimpan form';

  @override
  String get formTitleHint => 'cth: Kuis Matematika Bab 1';

  @override
  String get formTitleLabel => 'Judul Form';

  @override
  String get formTitleMinLength => 'Judul minimal 3 karakter';

  @override
  String get formTitleRequired => 'Judul form wajib diisi';

  @override
  String get formTypeSecurityMode => 'Tipe & Keamanan Form';

  @override
  String get formUpdatedSuccess => 'Form berhasil diperbarui';

  @override
  String get hideResultsSub => 'Peserta tidak melihat hasil';

  @override
  String get hideResultsTitle => 'Sembunyikan Hasil';

  @override
  String get hoursLabel => 'Jam';

  @override
  String get insertCodeTitle => 'Sisipkan Kode';

  @override
  String get insertCodeTooltip => 'Sisipkan kode';

  @override
  String get insertFormulaLabel => 'Sisipkan Rumus';

  @override
  String get insertImageTooltip => 'Sisipkan gambar';

  @override
  String get insertLabel => 'Sisipkan';

  @override
  String get insertMathTooltip => 'Sisipkan rumus matematika';

  @override
  String get invalidLatexFormula => 'Rumus LaTeX tidak valid';

  @override
  String get longTextHintNote => 'Jawaban teks panjang untuk uraian';

  @override
  String get mathFormulaTitle => 'Rumus Matematika';

  @override
  String get mathHintNote => 'Gunakan LaTeX untuk menulis rumus';

  @override
  String get minutesLabel => 'Menit';

  @override
  String get moveDown => 'Pindah ke bawah';

  @override
  String get moveUp => 'Pindah ke atas';

  @override
  String get mustBeLoggedInToCreateForm =>
      'Anda harus masuk untuk membuat form';

  @override
  String get noQuestionsYetSub => 'Ketuk tambah untuk membuat soal pertama';

  @override
  String get noQuestionsYetTitle => 'Belum ada soal';

  @override
  String get noTimeLimit => 'Tanpa batas waktu';

  @override
  String get ok => 'OK';

  @override
  String get oneTimeSubmitSub => 'Peserta hanya bisa mengisi sekali';

  @override
  String get oneTimeSubmitTitle => 'Isi Satu Kali';

  @override
  String get openLabel => 'Buka';

  @override
  String get openUnlimited => 'Buka tanpa batas waktu';

  @override
  String get optionTextHint => 'Teks opsi...';

  @override
  String get pointsMax100 => 'Poin maksimal 100';

  @override
  String get prepQuestionImages => 'Menyiapkan gambar soal...';

  @override
  String get previewLabel => 'Pratinjau';

  @override
  String get previewPlaceholder => 'Pratinjau akan tampil di sini';

  @override
  String get privateLabel => 'Privat';

  @override
  String get privateSublabel => 'Hanya dengan token akses';

  @override
  String get publicLabel => 'Publik';

  @override
  String get publicSublabel => 'Siapa pun dengan link bisa mengisi';

  @override
  String get qCodeInput => 'Input Kode';

  @override
  String get qCodeInputSub => 'Jawaban berupa kode program';

  @override
  String get qEssay => 'Esai';

  @override
  String get qEssaySub => 'Jawaban teks panjang';

  @override
  String get qImageChoice => 'Pilihan Gambar';

  @override
  String get qImageChoiceSub => 'Pilih salah satu gambar';

  @override
  String get qMathFormula => 'Rumus Matematika';

  @override
  String get qMathFormulaSub => 'Jawaban berupa rumus LaTeX';

  @override
  String get qMultipleChoice => 'Pilihan Ganda';

  @override
  String get qMultipleChoiceSub => 'Pilih satu atau beberapa jawaban';

  @override
  String get qRating => 'Rating';

  @override
  String get qRatingSub => 'Penilaian dengan bintang';

  @override
  String get qShortAnswer => 'Jawaban Singkat';

  @override
  String get qShortAnswerSub => 'Jawaban teks pendek';

  @override
  String get qYesNo => 'Ya / Tidak';

  @override
  String get qYesNoSub => 'Pilihan ya atau tidak';

  @override
  String get qCheckbox => 'Kotak Centang';

  @override
  String get qCheckboxSub => 'Pilih beberapa jawaban';

  @override
  String get qMatching => 'Menjodohkan';

  @override
  String get qMatchingSub => 'Jodohkan pasangan kiri-kanan';

  @override
  String get addPairLabel => 'Tambah Pasangan';

  @override
  String get matchingLeftHint => 'Kiri...';

  @override
  String get matchingRightHint => 'Kanan...';

  @override
  String get matchingHintNote =>
      'Tambahkan pasangan kiri-kanan. Peserta menjodohkan tiap item kiri ke jawaban kanan.';

  @override
  String get deletePairTooltip => 'Hapus pasangan';

  @override
  String get randomizeLinkTooltip => 'Acak link';

  @override
  String get requiredLabel => 'Wajib';

  @override
  String get resultVisibilityDesc =>
      'Atur apa yang dilihat peserta setelah submit';

  @override
  String get resultVisibilityLabel => 'Visibilitas Hasil';

  @override
  String get scheduleDesc => 'Atur jadwal buka dan tutup form';

  @override
  String get scheduleLabel => 'Jadwal';

  @override
  String get selectDate => 'Pilih tanggal';

  @override
  String get selectTime => 'Pilih waktu';

  @override
  String get sharingVisibilityDesc => 'Atur siapa yang bisa mengakses form';

  @override
  String get sharingVisibilityLabel => 'Visibilitas Berbagi';

  @override
  String get shortTextHintNote => 'Jawaban teks pendek satu baris';

  @override
  String get showResultAndScoreSub => 'Peserta melihat jawaban benar dan skor';

  @override
  String get showResultAndScoreTitle => 'Tampilkan Hasil & Skor';

  @override
  String get showResultOnlySub => 'Peserta hanya melihat jawaban benar';

  @override
  String get showResultOnlyTitle => 'Tampilkan Hasil Saja';

  @override
  String get shuffleOptionsSub => 'Urutan opsi diacak setiap peserta';

  @override
  String get shuffleOptionsTitle => 'Acak Opsi';

  @override
  String get shuffleQuestionsSub => 'Urutan soal diacak setiap peserta';

  @override
  String get shuffleQuestionsTitle => 'Acak Soal';

  @override
  String get signOut => 'Keluar';

  @override
  String get starsLabel => 'Bintang';

  @override
  String get starterCodeHint => 'Kode awal untuk peserta...';

  @override
  String get surveyModeSub => 'Tanpa nilai, fokus ke jawaban';

  @override
  String get surveyModeTitle => 'Mode Survei';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabQuestions => 'Soal';

  @override
  String get tabSettings => 'Pengaturan';

  @override
  String get timeAtLabel => 'pada';

  @override
  String get writeQuestionHere => 'Tulis pertanyaan di sini...';

  @override
  String accessDurationDays(Object count) {
    return '$count Hari';
  }

  @override
  String accessDurationDaysHours(Object days, Object hours) {
    return '$days Hari $hours Jam';
  }

  @override
  String accessDurationHours(Object count) {
    return '$count Jam';
  }

  @override
  String accessDurationHoursMins(Object hours, Object mins) {
    return '$hours Jam $mins Menit';
  }

  @override
  String accessDurationMins(Object count) {
    return '$count Menit';
  }

  @override
  String convertingQuestionsToImages(Object done, Object total) {
    return 'Mengonversi $done dari $total pertanyaan...';
  }

  @override
  String mcqNeedsCorrectAnswer(Object index) {
    return 'Soal $index butuh jawaban benar';
  }

  @override
  String questionContentEmpty(Object index) {
    return 'Isi soal $index masih kosong';
  }

  @override
  String get modeUser => 'Mode User';

  @override
  String get modeCreator => 'Mode Creator';

  @override
  String get modeUserDesc => 'Isi form dan lihat riwayat';

  @override
  String get modeCreatorDesc => 'Buat dan kelola form milik Anda';

  @override
  String get switchToMode => 'Beralih ke';

  @override
  String get examTokenTitle => 'Token Ujian';

  @override
  String get examTokenDesc =>
      'Umumkan token ini di kelas. Siswa memasukkan token untuk mulai ujian.';

  @override
  String get examTokenProtectedTitle => 'Proteksi Token';

  @override
  String get examTokenProtectedSub =>
      'Siswa wajib memasukkan token untuk mulai ujian';

  @override
  String get examTokenRegenerate => 'Acak Baru';

  @override
  String get examTokenCopied => 'Token ujian disalin';

  @override
  String get modeExam => 'UJIAN';

  @override
  String get modeSurvey => 'SURVEI';

  @override
  String get examBannerTitle => 'Mode ujian — perhatikan batasan';

  @override
  String get questionBank => 'Bank Soal';

  @override
  String get tabMyForms => 'Form Saya';

  @override
  String get tabTemplates => 'Template';

  @override
  String get takeFromBank => 'Ambil dari Bank Soal';

  @override
  String get noFormsBank => 'Belum ada form';

  @override
  String get noTemplatesBank => 'Belum ada template';

  @override
  String get noQuestionsInForm => 'Form ini belum memiliki soal';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get categoryHint => 'cth: Matematika, IPA';

  @override
  String addToFormCount(Object count) {
    return 'Tambah ke form ($count)';
  }

  @override
  String nOptions(Object count) {
    return '$count opsi';
  }

  @override
  String get filterAll => 'Semua';

  @override
  String get categoryFilterHint => 'Filter kategori';

  @override
  String get authFooterTagline =>
      'HiDocs • Formulir Dinamis & Platform Asesmen Cerdas';
}
