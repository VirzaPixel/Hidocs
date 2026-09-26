/// Penerjemah pesan error backend menjadi kalimat yang bisa ditindaklanjuti.
///
/// MASALAH YANG DIPERBAIKI
/// -----------------------
/// Backend membalas `400` dengan `message: "Invalid request payload"` untuk
/// SEMUA kegagalan `ShouldBindJSON` — entah itu email responden kosong, ID
/// non-UUID, tipe angka yang salah, atau tanggal tidak valid. Sebab sebenarnya
/// ada di field `errors`, tetapi klien dulu membuang field itu sehingga
/// pengguna hanya melihat kalimat buntu tanpa petunjuk apa pun.
///
/// Fungsi ini memakai `errors` untuk menghasilkan pesan yang menjelaskan
/// MASALAHNYA dan LANGKAH PERBAIKANNYA, sambil tetap menyertakan teks asli
/// server supaya teknisi bisa menelusuri.
///
/// Sengaja memakai teks Indonesia langsung (bukan l10n) agar konsisten dengan
/// pesan bawaan lain di [ApiClient] seperti 'Koneksi timeout...'.
String describeApiError(
  String message,
  Object? detail, {
  int? statusCode,
}) {
  final rawDetail = detail?.toString().trim() ?? '';
  final haystack = '$message $rawDetail'.toLowerCase();

  String withDetail(String human) =>
      rawDetail.isEmpty ? human : '$human\n\nDetail server: $rawDetail';

  // --- Urutan penting: cek penyebab spesifik sebelum pesan umum. ---------

  // 1. Field wajib kosong. Yang paling sering: `respondent_email` karena
  //    pengguna membuka form tanpa login.
  if (haystack.contains('respondentemail') ||
      haystack.contains('respondent_email')) {
    if (haystack.contains('email')) {
      return withDetail(
        'Data jawaban belum lengkap: identitas email responden tidak '
        'terbaca oleh server. Pastikan Anda SUDAH MASUK (login) dengan akun '
        'yang punya email sebelum mengirim jawaban, lalu coba lagi.',
      );
    }
  }

  // 2. ID bukan UUID. Field `question_id` / `selected_option_id` di-binding Go
  //    sebagai uuid.UUID, jadi satu nilai buruk menolak SELURUH payload.
  if (haystack.contains('invalid uuid') ||
      haystack.contains('uuid length') ||
      haystack.contains('cannot unmarshal') && haystack.contains('uuid')) {
    return withDetail(
      'Data jawaban ditolak server karena memuat ID yang tidak valid '
      '(bukan format UUID). Biasanya ini terjadi bila jawaban lama masih '
      'menyimpan teks seperti "yes"/"no" alih-alih ID pilihan. Muat ulang '
      'soal, jawab kembali pertanyaan tersebut, lalu kirim ulang.',
    );
  }

  // 3. Tipe data salah (angka dikirim sebagai teks/pecahan, atau sebaliknya).
  if (haystack.contains('cannot unmarshal')) {
    return withDetail(
      'Server menolak format salah satu jawaban (tipe datanya tidak cocok — '
      'mis. angka terkirim sebagai teks). Perbarui aplikasi ke versi terbaru; '
      'bila masih gagal, laporkan soal nomor berapa yang bermasalah.',
    );
  }

  // 4. Tanggal tidak valid pada pengaturan form.
  if (haystack.contains('parsing time') ||
      haystack.contains("cannot parse") && haystack.contains('time')) {
    return withDetail(
      'Format jadwal (tanggal/jam) form tidak valid. Periksa kembali waktu '
      'buka dan waktu tutup form, lalu simpan ulang.',
    );
  }

  // 5. Field wajib lain yang kosong.
  if (haystack.contains("failed on the 'required' tag")) {
    // Cari field spesifik yang kosong untuk pesan lebih tepat.
    if (haystack.contains('questiontext') || haystack.contains('question_text')) {
      return withDetail(
        'Teks soal wajib diisi dan tidak boleh kosong. '
        'Isi pertanyaan untuk setiap soal, lalu simpan ulang.',
      );
    }
    if (haystack.contains('questiontype') || haystack.contains('question_type')) {
      return withDetail(
        'Tipe soal tidak dikenali server. '
        'Coba hapus soal tersebut lalu tambahkan ulang dengan tipe yang sesuai.',
      );
    }
    if (haystack.contains('optiontext') || haystack.contains('option_text')) {
      return withDetail(
        'Teks pilihan jawaban tidak boleh kosong. '
        'Isi semua opsi pada soal pilihan ganda / ya-tidak, lalu simpan ulang.',
      );
    }
    return withDetail(
      'Ada data wajib yang belum terisi sehingga server menolaknya. '
      'Lengkapi dulu (mis. judul form atau teks soal), lalu simpan ulang.',
    );
  }

  if (haystack.contains("failed on the 'gte' tag") ||
      haystack.contains("failed on the 'oneof' tag") ||
      haystack.contains("failed on the 'email' tag")) {
    return withDetail(
      'Ada nilai yang tidak sesuai aturan server (mis. poin negatif, pilihan '
      'yang tidak dikenal, atau email tidak valid). Perbaiki nilai tersebut '
      'lalu simpan ulang.',
    );
  }

  // --- Pesan domain backend yang sudah spesifik ------------------------

  const known = <String, String>{
    'form not found': 'Form tidak ditemukan. Pastikan tautan atau kode form '
        'benar dan form belum dihapus.',
    'form is closed or not active':
        'Form ini sedang ditutup atau tidak aktif, sehingga jawaban tidak '
            'dapat dikirim. Hubungi pembuat form atau pengawas.',
    'exam has not started yet':
        'Ujian belum dimulai. Tunggu sampai waktu buka yang ditentukan.',
    'exam time limit has passed':
        'Waktu ujian sudah berakhir. Jawaban tidak dapat dikirim lagi.',
    'maximum submission limit has been reached for this form':
        'Batas jumlah pengisian untuk form ini sudah tercapai.',
    'you have already submitted a response for this form':
        'Anda sudah pernah mengirim jawaban untuk form ini.',
    'invalid exam passcode/token':
        'Token ujian salah. Periksa kembali token dari pengawas.',
    'unauthorized access': 'Sesi Anda tidak valid. Silakan masuk ulang.',
    'access forbidden': 'Anda tidak punya izin untuk tindakan ini.',
    'refresh token has been revoked or already used':
        'Sesi Anda sudah berakhir karena token dipakai di perangkat lain. '
            'Silakan masuk ulang.',
    'invalid or expired refresh token':
        'Sesi Anda sudah berakhir. Silakan masuk ulang.',
  };

  for (final entry in known.entries) {
    if (haystack.contains(entry.key)) return entry.value;
  }

  // Pesan yang sudah ramah (mis. dari service bisnis) dibiarkan apa adanya,
  // tetapi detail teknis tetap dilampirkan bila server mengirimkannya.
  if (rawDetail.isNotEmpty && !message.contains(rawDetail)) {
    return '$message\n\nDetail server: $rawDetail';
  }

  return message;
}
