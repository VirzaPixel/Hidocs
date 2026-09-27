/// Pola UUID dalam bentuk teks (8-4-4-4-12 heksadesimal) — format yang sama
/// dengan yang dibuat backend dan diterima `uuid.Parse` di Go.
final RegExp uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// `true` bila [value] berbentuk UUID yang bisa diterima backend.
///
/// Dipakai untuk menyaring payload sebelum dikirim: field seperti
/// `question_id` dan `selected_option_id` di-binding Go sebagai `uuid.UUID`,
/// dan SATU nilai non-UUID membuat `ShouldBindJSON` menolak seluruh body
/// dengan `400 "Invalid request payload"`.
bool isUuid(Object? value) {
  final text = (value ?? '').toString().trim();
  return text.isNotEmpty && uuidPattern.hasMatch(text);
}
