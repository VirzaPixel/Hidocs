import 'uuid_utils.dart';

/// Membersihkan daftar jawaban sebelum dikirim ke `POST /forms/{id}/submit`
/// (dan ke `POST /public/responses/{id}/autosave`).
///
/// KENAPA INI PERLU
/// ----------------
/// Backend mem-binding `question_id` dan `selected_option_id` sebagai
/// `uuid.UUID`. Satu saja nilai yang tidak berbentuk UUID membuat
/// `ShouldBindJSON` gagal, lalu handler membalas
/// `400 "Invalid request payload"` — artinya **seluruh jawaban ikut hilang**,
/// bukan hanya baris yang rusak. Ini sudah dibuktikan langsung terhadap
/// binding Go: `selected_option_id: "o17y"` → `invalid UUID length: 4`.
///
/// Karena itu:
///   * baris dengan `question_id` non-UUID dibuang — server mana pun tidak
///     akan pernah bisa menyimpannya, jadi mengirimnya hanya merugikan;
///   * `selected_option_id` non-UUID dikosongkan (`null`) supaya
///     `answer_text` tetap bisa tersimpan alih-alih menolak semuanya.
///
/// Daftar baru dikembalikan; masukan tidak diubah.
List<Map<String, dynamic>> sanitizeSubmitAnswers(
  List<Map<String, dynamic>> answers,
) {
  final cleaned = <Map<String, dynamic>>[];

  for (final row in answers) {
    if (!isUuid(row['question_id'])) continue;

    final copy = Map<String, dynamic>.from(row);
    final optionId = copy['selected_option_id'];
    if (optionId != null && !isUuid(optionId)) {
      copy['selected_option_id'] = null;
    }
    cleaned.add(copy);
  }

  return cleaned;
}

/// `true` bila [answers] masih memuat minimal satu baris yang bisa disimpan
/// server (yaitu punya `question_id` berbentuk UUID).
bool hasStorableAnswer(List<Map<String, dynamic>> answers) =>
    answers.any((row) => isUuid(row['question_id']));
