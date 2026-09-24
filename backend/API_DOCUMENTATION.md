# 📘 HiDocs API Documentation (Form & Exam Maker)

Dokumentasi resmi seluruh endpoint API untuk sistem backend **HiDocs (Form & Exam Maker)**.  
Dokumen ini melampirkan detail **HTTP Method**, **Endpoint URL**, **Header**, **Query Parameter**, **Request Body (JSON / Multipart)**, serta **Expected Response (Success & Error)** secara lengkap dan terstruktur.

---

## 📌 1. Standar & Ketentuan Umum API

- **Base URL**: `http://localhost:8080/api/v1`
- **Content-Type**: `application/json` (kecuali upload file menggunakan `multipart/form-data`)
- **Authentication**: Menggunakan **Bearer Token JWT** pada Header `Authorization`.
  ```http
  Authorization: Bearer <ACCESS_TOKEN>
  ```
- **Pola Token (Access + Refresh)**:
  - `access_token` — umur pendek (**default 60 menit**, `JWT_ACCESS_EXPIRE_MINUTES`), dipakai di **semua** endpoint protected.
  - `refresh_token` — umur panjang (**default 336 jam = 14 hari**, `JWT_REFRESH_EXPIRE_HOURS`), **hanya** boleh dikirim ke `POST /api/v1/auth/refresh`.
  - Saat access token kedaluwarsa, server membalas `401`. Klien cukup memanggil `/auth/refresh` dengan `refresh_token` untuk mendapat pasangan token baru (tanpa login ulang). Refresh token bersifat **sekali pakai** (dirotasi) dan bisa dicabut lewat `/auth/logout`.
  - Field `token` (legacy) tetap dikirim dan isinya sama dengan `access_token`, supaya klien lama tetap kompatibel.
- **ExamBro Compatibility Header** *(Opsional untuk Ujian Aman)*:
  ```http
  X-Exambro-Token: <SECURE_BROWSER_TOKEN>
  ```

### Standard Response Envelope Format

#### Success Response
```json
{
  "success": true,
  "message": "Pesan sukses deskriptif",
  "data": { ... }
}
```

#### Error Response
```json
{
  "success": false,
  "message": "Pesan kesalahan deskriptif",
  "errors": "Detail error (string / object)"
}
```

---

## 🔑 2. Autentikasi & Manajemen Akun

### 2.1 Register User Baru
- **Endpoint**: `POST /api/v1/auth/register`
- **Auth**: Public
- **Request Body**:
```json
{
  "name": "Budi Santoso",
  "email": "budi@school.id",
  "password": "password123"
}
```
- **Expected Response (201 Created)**:
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "e3b8a1c9-7d8e-4f1a-9b2c-3d4e5f6a7b8c",
      "name": "Budi Santoso",
      "email": "budi@school.id",
      "role": "user",
      "is_active": true,
      "created_at": "2026-07-30T06:45:00Z"
    }
  }
}
```

---

### 2.2 Login User
- **Endpoint**: `POST /api/v1/auth/login`
- **Auth**: Public
- **Request Body**:
```json
{
  "email": "budi@school.id",
  "password": "password123"
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "user": {
      "id": "e3b8a1c9-7d8e-4f1a-9b2c-3d4e5f6a7b8c",
      "name": "Budi Santoso",
      "email": "budi@school.id",
      "role": "user",
      "avatar_url": "https://cdn.hidocs.id/avatars/budi.jpg",
      "is_active": true,
      "created_at": "2026-07-30T06:45:00Z"
    }
  }
}
```
> `expires_in` adalah umur **access token** dalam detik. Respons `POST /api/v1/auth/verify-otp` memakai format `data` yang sama.

---

### 2.3 Refresh Access Token (Perpanjang Sesi Otomatis)
- **Endpoint**: `POST /api/v1/auth/refresh`
- **Auth**: Public (cukup bawa `refresh_token`)
- **Request Body**:
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```
- **Expected Response (200 OK)**: `data` berisi pasangan token baru (`token`, `access_token`, `refresh_token`, `token_type`, `expires_in`, `user`) — bentuknya sama seperti respons login.
- **Catatan penting**:
  - Refresh token **dirotasi**: setelah dipakai, token lama langsung tidak berlaku, klien **wajib** menyimpan `refresh_token` baru dari respons ini.
  - **Jendela toleransi replay 60 detik**: kalau refresh token lama dipakai ulang **di dalam 60 detik** setelah rotasi, server menganggapnya balapan antar-klien sah (dua tab/perangkat memanggil endpoint ini hampir bersamaan) dan tetap menjawab dengan pasangan token baru — **tidak ada sesi yang dicabut**.
  - Pemakaian ulang **di luar** 60 detik itu dianggap indikasi pencurian token → **seluruh sesi user dicabut** dan respons berisi `refresh token has been revoked or already used`.
  - Kalau refresh token sudah kedaluwarsa / sudah di-logout → `401 invalid or expired refresh token` (tanpa mencabut sesi perangkat lain).
  - Kegagalan infrastruktur (mis. Redis/DB mati) dijawab dengan **500**, bukan 401, supaya klien tidak salah mengira pengguna harus login ulang.
- **Expected Response (401 Unauthorized)**:
```json
{
  "success": false,
  "message": "invalid or expired refresh token",
  "errors": "invalid or expired refresh token"
}
```

---

### 2.4 Logout (Cabut Refresh Token)
- **Endpoint**: `POST /api/v1/auth/logout`
- **Auth**: Bearer Token (access token)
- **Request Body** *(opsional)*:
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```
- **Perilaku**:
  - Body berisi `refresh_token` → hanya sesi/perangkat itu yang dicabut.
  - Body dikosongkan / tanpa body → **seluruh sesi user dicabut** (logout dari semua perangkat).
  - `refresh_token` yang tidak valid / sudah dirotasi → tetap dijawab `200`, tapi **seluruh sesi user dicabut** (perilaku aman: mencegah token hasil rotasi yang tersisa di server tetap hidup).
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Logged out successfully. Refresh token has been revoked.",
  "data": null
}
```
> Catatan: `POST /api/v1/auth/reset-password` juga otomatis mencabut seluruh sesi user (semua perangkat harus login ulang dengan password baru).

---

### 2.5 Minta Token Lupa Password (Forgot Password)
- **Endpoint**: `POST /api/v1/auth/forgot-password`
- **Auth**: Public
- **Request Body**:
```json
{
  "email": "budi@school.id"
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Password reset token generated successfully",
  "data": {
    "reset_token": "a1b2c3d4e5f67890g7h8i9j0k1l2m3n4"
  }
}
```

---

### 2.6 Reset Password dengan Token
- **Endpoint**: `POST /api/v1/auth/reset-password`
- **Auth**: Public
- **Request Body**:
```json
{
  "token": "a1b2c3d4e5f67890g7h8i9j0k1l2m3n4",
  "new_password": "newpassword123"
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Password has been reset successfully",
  "data": null
}
```

---

### 2.7 Ambil Profil Saya (Get Current Profile)
- **Endpoint**: `GET /api/v1/users/me`
- **Auth**: Bearer Token
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": "e3b8a1c9-7d8e-4f1a-9b2c-3d4e5f6a7b8c",
    "name": "Budi Santoso",
    "email": "budi@school.id",
    "role": "user",
    "avatar_url": "https://cdn.hidocs.id/avatars/budi.jpg",
    "is_active": true,
    "created_at": "2026-07-30T06:45:00Z"
  }
}
```

---

### 2.8 Update Profil Saya
- **Endpoint**: `PUT /api/v1/users/me`
- **Auth**: Bearer Token
- **Request Body**:
```json
{
  "name": "Budi Santoso, M.Pd",
  "avatar_url": "https://cdn.hidocs.id/avatars/budi_new.jpg"
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "e3b8a1c9-7d8e-4f1a-9b2c-3d4e5f6a7b8c",
    "name": "Budi Santoso, M.Pd",
    "email": "budi@school.id",
    "role": "user",
    "avatar_url": "https://cdn.hidocs.id/avatars/budi_new.jpg",
    "is_active": true,
    "created_at": "2026-07-30T06:45:00Z"
  }
}
```

---

### 2.9 Import Banyak Siswa/User
- **Endpoint**: `POST /api/v1/users/students/import`
- **Auth**: Bearer Token
- **Request Body**:
```json
{
  "students": [
    {
      "name": "Ahmad Subagja",
      "email": "ahmad@student.id",
      "password": "pass123student"
    },
    {
      "name": "Siti Nurhaliza",
      "email": "siti@student.id",
      "password": "pass123student"
    }
  ]
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Students imported successfully",
  "data": {
    "imported_count": 2
  }
}
```

---

## 📝 3. Form Builder & Settings

### 3.1 Daftar Formulir Saya (My Forms)
- **Endpoint**: `GET /api/v1/forms`
- **Auth**: Bearer Token
- **Query Parameter (Opsional)**: `status` = `DRAFT` | `ACTIVE` | `CLOSED`
  - Contoh: `GET /api/v1/forms?status=ACTIVE`
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Forms retrieved successfully",
  "data": [
    {
      "id": "c1f2e3d4-5a6b-7c8d-9e0f-1a2b3c4d5e6f",
      "user_id": "e3b8a1c9-7d8e-4f1a-9b2c-3d4e5f6a7b8c",
      "title": "Ujian Akhir Semester Matematika X",
      "description": "Ujian Matematika wajib kelas X semester genap.",
      "type": "EXAM",
      "custom_url": "ujian-math-10a",
      "status": "ACTIVE",
      "created_at": "2026-07-30T07:00:00Z",
      "response_count": 42
    }
  ]
}
```

---

### 3.2 Buat Form / Exam Baru
- **Endpoint**: `POST /api/v1/forms`
- **Auth**: Bearer Token
- **Request Body**:
```json
{
  "title": "Survei Kepuasan Siswa 2026",
  "description": "Silakan isi survei kepuasan fasilitas sekolah.",
  "type": "SURVEY",
  "custom_url": "survei-fasilitas-2026"
}
```
- **Expected Response (201 Created)**:
```json
{
  "success": true,
  "message": "Form created successfully",
  "data": {
    "id": "f8e7d6c5-4b3a-2f1e-0d9c-8b7a6f5e4d3c",
    "user_id": "e3b8a1c9-7d8e-4f1a-9b2c-3d4e5f6a7b8c",
    "title": "Survei Kepuasan Siswa 2026",
    "description": "Silakan isi survei kepuasan fasilitas sekolah.",
    "type": "SURVEY",
    "custom_url": "survei-fasilitas-2026",
    "status": "DRAFT",
    "created_at": "2026-07-30T07:15:00Z",
    "response_count": 0,
    "questions": []
  }
}
```

---

### 3.3 Import Form dari File Word (.docx)
- **Endpoint**: `POST /api/v1/forms/import-docx`
- **Auth**: Bearer Token
- **Content-Type**: `multipart/form-data`
- **Form Data**:
  - `file`: `<Pilih File Word (.docx)>`
- **Expected Response (201 Created)**:
```json
{
  "success": true,
  "message": "Form imported successfully from Word document",
  "data": {
    "id": "a9b8c7d6-e5f4-3a2b-1c0d-9e8f7a6b5c4d",
    "title": "Kuis Fisika Dasar - Hukum Newton",
    "description": "Form generated automatically from Word document",
    "type": "EXAM",
    "custom_url": "kuis-fisika-dasar-hukum-newton",
    "status": "DRAFT",
    "questions": [
      {
        "id": "11223344-5566-7788-9900-aabbccddeeff",
        "question_text": "Siapakah penemu Hukum Gravitasi?",
        "question_type": "MULTIPLE_CHOICE",
        "points": 10,
        "order_index": 1,
        "is_required": true,
        "options": [
          { "id": "opt-1", "option_text": "Isaac Newton", "is_correct": true, "order_index": 1 },
          { "id": "opt-2", "option_text": "Albert Einstein", "is_correct": false, "order_index": 2 },
          { "id": "opt-3", "option_text": "Nikola Tesla", "is_correct": false, "order_index": 3 }
        ]
      }
    ]
  }
}
```

---

### 3.4 Detail Form (Creator View)
- **Endpoint**: `GET /api/v1/forms/:form_id`
- **Auth**: Bearer Token
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Form retrieved successfully",
  "data": {
    "id": "c1f2e3d4-5a6b-7c8d-9e0f-1a2b3c4d5e6f",
    "user_id": "e3b8a1c9-7d8e-4f1a-9b2c-3d4e5f6a7b8c",
    "title": "Ujian Akhir Semester Matematika X",
    "description": "Ujian Matematika wajib kelas X semester genap.",
    "type": "EXAM",
    "custom_url": "ujian-math-10a",
    "status": "ACTIVE",
    "created_at": "2026-07-30T07:00:00Z",
    "response_count": 42,
    "exam_settings": {
      "duration_minutes": 90,
      "passcode": "MATH10A",
      "randomize_questions": true,
      "randomize_options": true,
      "start_time": "2026-07-30T08:00:00Z",
      "end_time": "2026-07-30T12:00:00Z"
    },
    "questions": [
      {
        "id": "q-111",
        "question_text": "Hitunglah nilai x jika \\(x^2 - 4 = 0\\)",
        "question_type": "MATH",
        "points": 20,
        "order_index": 1,
        "is_required": true,
        "options": [
          { "id": "opt-1", "option_text": "x = 2 atau x = -2", "is_correct": true, "order_index": 1 },
          { "id": "opt-2", "option_text": "x = 4 atau x = -4", "is_correct": false, "order_index": 2 }
        ]
      }
    ]
  }
}
```

---

### 3.5 Update Form
- **Endpoint**: `PUT /api/v1/forms/:form_id`
- **Auth**: Bearer Token
- **Request Body**:
```json
{
  "title": "Ujian Akhir Semester Matematika X (Updated)",
  "description": "Ujian Matematika Kelas X Wajib.",
  "type": "EXAM",
  "custom_url": "ujian-math-10a-2026",
  "status": "ACTIVE"
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Form updated successfully",
  "data": { ... }
}
```

---

### 3.6 Update Pengaturan Ujian (Exam Settings)
- **Endpoint**: `PUT /api/v1/forms/:form_id/settings`
- **Auth**: Bearer Token
- **Request Body**:
```json
{
  "duration_minutes": 120,
  "passcode": "MATH2026",
  "randomize_questions": true,
  "randomize_options": true,
  "start_time": "2026-07-30T08:00:00Z",
  "end_time": "2026-07-30T14:00:00Z"
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Exam settings updated successfully",
  "data": {
    "id": "s-123",
    "form_id": "c1f2e3d4-5a6b-7c8d-9e0f-1a2b3c4d5e6f",
    "duration_minutes": 120,
    "passcode": "MATH2026",
    "randomize_questions": true,
    "randomize_options": true,
    "start_time": "2026-07-30T08:00:00Z",
    "end_time": "2026-07-30T14:00:00Z"
  }
}
```

---

### 3.7 Hapus Form
- **Endpoint**: `DELETE /api/v1/forms/:form_id`
- **Auth**: Bearer Token
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Form deleted successfully",
  "data": null
}
```

---

## 🌐 4. Public Access & Responden (Exam / Form Mode)

### 4.1 Akses Public Form via Short Code / Custom Slug
- **Endpoint**: `GET /api/v1/public/forms/:short_code`
- **Auth**: Public *(Kunci jawaban `is_correct` disembunyikan demi keamanan ujian)*
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Public form retrieved successfully",
  "data": {
    "id": "c1f2e3d4-5a6b-7c8d-9e0f-1a2b3c4d5e6f",
    "title": "Ujian Akhir Semester Matematika X",
    "description": "Ujian Matematika wajib kelas X semester genap.",
    "type": "EXAM",
    "custom_url": "ujian-math-10a",
    "status": "ACTIVE",
    "exam_settings": {
      "duration_minutes": 90,
      "has_passcode": true,
      "randomize_questions": true,
      "randomize_options": true,
      "start_time": "2026-07-30T08:00:00Z",
      "end_time": "2026-07-30T12:00:00Z"
    },
    "questions": [
      {
        "id": "q-111",
        "question_text": "Hitunglah nilai x jika \\(x^2 - 4 = 0\\)",
        "question_type": "MATH",
        "points": 20,
        "order_index": 1,
        "is_required": true,
        "options": [
          { "id": "opt-1", "option_text": "x = 2 atau x = -2", "order_index": 1 },
          { "id": "opt-2", "option_text": "x = 4 atau x = -4", "order_index": 2 }
        ]
      },
      {
        "id": "q-222",
        "question_text": "Buatlah fungsi rekursif faktorial dalam Python.",
        "question_type": "CODE",
        "code_language": "python",
        "points": 30,
        "order_index": 2,
        "is_required": true
      }
    ]
  }
}
```

---

### 4.2 Submit Jawaban Form / Ujian (Auto-Grading)
- **Endpoint**: `POST /api/v1/forms/:form_id/submit`
- **Auth**: Public / Responden
- **Header Security (Exambro Mode)**: `X-Exambro-Token: EXAMBRO_PASS`
- **Request Body**:
```json
{
  "respondent_email": "siswa1@school.id",
  "passcode": "MATH2026",
  "answers": [
    {
      "question_id": "q-111",
      "selected_option_id": "opt-1"
    },
    {
      "question_id": "q-222",
      "answer_text": "def factorial(n):\n    return 1 if n <= 1 else n * factorial(n-1)"
    }
  ]
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Response submitted successfully",
  "data": {
    "response_id": "resp-998877",
    "total_score": 20,
    "submitted_at": "2026-07-30T09:30:00Z",
    "message": "Response submitted successfully"
  }
}
```

---

## ❓ 5. Kelola Soal & Opsi (Questions & Options)

### 5.1 Tambah Soal Baru
- **Endpoint**: `POST /api/v1/forms/:form_id/questions`
- **Auth**: Bearer Token
- **Request Body**:
```json
{
  "question_text": "Manakah kode JavaScript untuk membuat Variabel?",
  "question_type": "CODE",
  "code_language": "javascript",
  "points": 15,
  "order_index": 1,
  "is_required": true,
  "options": [
    { "option_text": "const x = 10;", "is_correct": true, "order_index": 1 },
    { "option_text": "variable x = 10;", "is_correct": false, "order_index": 2 }
  ]
}
```
- **Expected Response (201 Created)**:
```json
{
  "success": true,
  "message": "Question added successfully",
  "data": { ... }
}
```

---

### 5.2 Update Soal
- **Endpoint**: `PUT /api/v1/questions/:question_id`
- **Auth**: Bearer Token
- **Request Body**:
```json
{
  "question_text": "Manakah deklarasi variabel ES6 yang tepat?",
  "question_type": "CODE",
  "code_language": "javascript",
  "points": 20,
  "order_index": 1,
  "is_required": true,
  "options": [
    { "option_text": "const x = 10;", "is_correct": true, "order_index": 1 },
    { "option_text": "let y = 20;", "is_correct": true, "order_index": 2 }
  ]
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Question updated successfully",
  "data": { ... }
}
```

---

### 5.3 Hapus Soal
- **Endpoint**: `DELETE /api/v1/questions/:question_id`
- **Auth**: Bearer Token
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Question deleted successfully",
  "data": null
}
```

---

### 5.4 Hapus Opsi Jawaban
- **Endpoint**: `DELETE /api/v1/options/:option_id`
- **Auth**: Bearer Token
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Question option deleted successfully",
  "data": null
}
```

---

## 📊 6. Koreksi, Analytics & Export Data

### 6.1 Lihat Semua Respon Formulir
- **Endpoint**: `GET /api/v1/forms/:form_id/responses`
- **Auth**: Bearer Token
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Responses retrieved successfully",
  "data": [
    {
      "id": "resp-998877",
      "form_id": "c1f2e3d4-5a6b-7c8d-9e0f-1a2b3c4d5e6f",
      "respondent_email": "siswa1@school.id",
      "total_score": 85,
      "submitted_at": "2026-07-30T09:30:00Z"
    }
  ]
}
```

---

### 6.2 Lihat Rincian Jawaban Responden (Individual Response)
- **Endpoint**: `GET /api/v1/responses/:response_id`
- **Auth**: Bearer Token
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Response detail retrieved successfully",
  "data": {
    "id": "resp-998877",
    "form_id": "c1f2e3d4-5a6b-7c8d-9e0f-1a2b3c4d5e6f",
    "respondent_email": "siswa1@school.id",
    "total_score": 85,
    "submitted_at": "2026-07-30T09:30:00Z",
    "answers": [
      {
        "id": "ans-1",
        "question_id": "q-111",
        "question_text": "Hitunglah nilai x jika \\(x^2 - 4 = 0\\)",
        "selected_option_id": "opt-1",
        "selected_option_text": "x = 2 atau x = -2",
        "is_correct": true,
        "points_earned": 20
      }
    ]
  }
}
```

---

### 6.3 Update / Penyesuaian Nilai Manual
- **Endpoint**: `PUT /api/v1/responses/:response_id/grade`
- **Auth**: Bearer Token
- **Request Body**:
```json
{
  "total_score": 95.5
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Grade updated successfully",
  "data": null
}
```

---

### 6.4 Analytics Real-Time untuk Pie & Bar Chart
- **Endpoint**: `GET /api/v1/forms/:form_id/analytics`
- **Auth**: Bearer Token
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Analytics retrieved successfully",
  "data": {
    "total_responses": 42,
    "average_score": 78.5,
    "highest_score": 100,
    "lowest_score": 40,
    "question_breakdown": {
      "q-111": {
        "question_id": "q-111",
        "question_text": "Hitunglah nilai x jika \\(x^2 - 4 = 0\\)",
        "total_answered": 42,
        "correct_count": 36,
        "accuracy_rate": 85.71,
        "option_counts": {
          "opt-1": 36,
          "opt-2": 6
        }
      }
    }
  }
}
```

---

### 6.5 Export Data Respon ke Excel (.xlsx) / CSV
- **Endpoint**: `GET /api/v1/forms/:form_id/export`
- **Auth**: Bearer Token
- **Query Parameter**: `format` = `xlsx` | `csv` (Default: `xlsx`)
  - Example: `GET /api/v1/forms/c1f2e3d4.../export?format=xlsx`
- **Expected Response (200 OK)**:
  - **Header Response**:
    ```http
    Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    Content-Disposition: attachment; filename="ujian-math-10a_responses_20260730_070000.xlsx"
    ```
  - **Body**: File binary spreadsheet `.xlsx` atau `.csv`.

---

## 👑 7. Admin Exclusive Endpoints

### 7.1 Dashboard Stats Sistem Global
- **Endpoint**: `GET /api/v1/admin/dashboard/stats`
- **Auth**: Bearer Token (Role: `admin`)
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Admin dashboard stats retrieved successfully",
  "data": {
    "total_users": 150,
    "total_creators": 25,
    "total_forms": 80,
    "active_exams": 12,
    "total_responses": 1420
  }
}
```

---

### 7.2 Daftar Seluruh Form Creator
- **Endpoint**: `GET /api/v1/admin/creators`
- **Auth**: Bearer Token (Role: `admin`)
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Creators retrieved successfully",
  "data": [
    {
      "id": "e3b8a1c9-7d8e-4f1a-9b2c-3d4e5f6a7b8c",
      "name": "Budi Santoso",
      "email": "budi@school.id",
      "is_active": true,
      "created_at": "2026-07-30 06:45:00"
    }
  ]
}
```

---

### 7.3 Buat Akun Creator Baru oleh Admin
- **Endpoint**: `POST /api/v1/admin/creators`
- **Auth**: Bearer Token (Role: `admin`)
- **Request Body**:
```json
{
  "name": "Siti Aminah, S.Pd",
  "email": "siti@school.id",
  "password": "creatorpass123"
}
```
- **Expected Response (201 Created)**:
```json
{
  "success": true,
  "message": "Creator created successfully",
  "data": {
    "id": "f1e2d3c4-b5a6-7890-1234-56789abcdef0",
    "name": "Siti Aminah, S.Pd",
    "email": "siti@school.id",
    "role": "user",
    "is_active": true,
    "created_at": "2026-07-30T07:45:00Z"
  }
}
```

---

### 7.4 Nonaktifkan / Aktifkan Akun Creator
- **Endpoint**: `PUT /api/v1/admin/creators/:creator_id/status`
- **Auth**: Bearer Token (Role: `admin`)
- **Request Body**:
```json
{
  "is_active": false
}
```
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Creator status updated successfully",
  "data": null
}
```

---

### 7.5 Daftar Seluruh Form di Sistem
- **Endpoint**: `GET /api/v1/admin/forms`
- **Auth**: Bearer Token (Role: `admin`)
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "All forms retrieved successfully",
  "data": [
    {
      "id": "c1f2e3d4-5a6b-7c8d-9e0f-1a2b3c4d5e6f",
      "user_id": "e3b8a1c9-7d8e-4f1a-9b2c-3d4e5f6a7b8c",
      "title": "Ujian Akhir Semester Matematika X",
      "type": "EXAM",
      "status": "ACTIVE",
      "created_at": "2026-07-30T07:00:00Z"
    }
  ]
}
```

---

### 7.6 Hapus Form oleh Admin
- **Endpoint**: `DELETE /api/v1/admin/forms/:form_id`
- **Auth**: Bearer Token (Role: `admin`)
- **Expected Response (200 OK)**:
```json
{
  "success": true,
  "message": "Form deleted successfully by admin",
  "data": null
}
```
