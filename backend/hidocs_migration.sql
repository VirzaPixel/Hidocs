-- =============================================================================
-- HiDocs — Migrasi SQL Lengkap (PostgreSQL)
-- Dibuat manual dari source Go (internal/domain/*.go) per 21 Sep 2026, mencakup
-- SEMUA batch perbaikan sebelumnya (fix compile, Bank Soal, Share Monitoring,
-- status Review, max_attempts).
--
-- CATATAN PENTING: backend ini pakai GORM AutoMigrate (AUTO_MIGRATE=true di .env),
-- jadi secara teknis file ini TIDAK WAJIB dijalankan manual — backend akan bikin
-- semua tabel ini sendiri saat pertama kali start. File ini berguna untuk:
--   1. Restore/setup database di server baru tanpa menjalankan aplikasi dulu
--   2. Referensi skema lengkap untuk dokumentasi/audit
--   3. Kalau AUTO_MIGRATE=false di production (lebih aman), ini migrasi manualnya
--
-- Jalankan sekali di database kosong:
--   psql -U postgres -d hidocs_db -f migration.sql
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- untuk gen_random_uuid()

-- =============================================================================
-- 1. USERS
-- =============================================================================
CREATE TABLE IF NOT EXISTS users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL DEFAULT 'user', -- user | admin | superadmin
    avatar_url    VARCHAR(255),
    is_active     BOOLEAN      NOT NULL DEFAULT true,
    created_at    TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at    TIMESTAMP    NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email ON users (email);

CREATE TABLE IF NOT EXISTS password_resets (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email      VARCHAR(100) NOT NULL,
    token      VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP    NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_password_resets_email ON password_resets (email);
CREATE UNIQUE INDEX IF NOT EXISTS uq_password_resets_token ON password_resets (token);

-- =============================================================================
-- 2. FORMS
-- =============================================================================
CREATE TABLE IF NOT EXISTS forms (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    category    VARCHAR(100) NOT NULL DEFAULT 'General',
    type        VARCHAR(20)  NOT NULL DEFAULT 'SURVEY',   -- SURVEY | EXAM
    custom_url  VARCHAR(100),
    status      VARCHAR(20)  NOT NULL DEFAULT 'DRAFT',    -- DRAFT | REVIEW | ACTIVE | CLOSED
    is_template BOOLEAN      NOT NULL DEFAULT false,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_forms_user_id ON forms (user_id);
CREATE INDEX IF NOT EXISTS idx_forms_category ON forms (category);
CREATE UNIQUE INDEX IF NOT EXISTS uq_forms_custom_url ON forms (custom_url);

CREATE TABLE IF NOT EXISTS form_settings (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id                UUID NOT NULL REFERENCES forms(id) ON DELETE CASCADE,
    duration_minutes       INT,
    auto_active_days       INT     NOT NULL DEFAULT 30,
    is_active_immediately  BOOLEAN NOT NULL DEFAULT false,
    is_one_time_submission BOOLEAN NOT NULL DEFAULT false,
    max_attempts           INT     NOT NULL DEFAULT 0,   -- 0 = tidak dibatasi
    randomize_questions    BOOLEAN NOT NULL DEFAULT false,
    randomize_options      BOOLEAN NOT NULL DEFAULT false,
    start_time             TIMESTAMP,
    end_time               TIMESTAMP,
    theme_color            VARCHAR(50)  NOT NULL DEFAULT '#4F46E5',
    cover_image_url        VARCHAR(255),
    logo_url               VARCHAR(255),
    font_family            VARCHAR(50)  NOT NULL DEFAULT 'Inter',
    allow_backtrack        BOOLEAN NOT NULL DEFAULT true,
    show_question_number   BOOLEAN NOT NULL DEFAULT true,
    fullscreen_mode        BOOLEAN NOT NULL DEFAULT false,
    exam_token             VARCHAR(50),
    is_token_protected     BOOLEAN NOT NULL DEFAULT false
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_form_settings_form_id ON form_settings (form_id);

-- =============================================================================
-- 3. QUESTIONS & OPTIONS (milik satu form)
-- =============================================================================
CREATE TABLE IF NOT EXISTS questions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id         UUID NOT NULL REFERENCES forms(id) ON DELETE CASCADE,
    question_text   TEXT NOT NULL,
    question_type   VARCHAR(30) NOT NULL, -- SHORT_TEXT|LONG_TEXT|MULTIPLE_CHOICE|CHECKBOXES|
                                            -- DROPDOWN|RATING|YES_NO|MATH|CODE|IMAGE|MATCHING
    code_language   VARCHAR(30),
    img_url         VARCHAR(255),
    audio_url       VARCHAR(255),
    video_url       VARCHAR(255),
    is_auto_scored  BOOLEAN   NOT NULL DEFAULT true,
    points          INT       NOT NULL DEFAULT 1,
    order_index     INT       NOT NULL DEFAULT 0,
    is_required     BOOLEAN   NOT NULL DEFAULT false,
    is_autosaved_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_questions_form_id ON questions (form_id);

CREATE TABLE IF NOT EXISTS question_options (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id       UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    option_text       TEXT NOT NULL,
    img_url           VARCHAR(255),
    audio_url         VARCHAR(255),
    video_url         VARCHAR(255),
    match_key         VARCHAR(255), -- khusus tipe MATCHING
    match_target_text VARCHAR(255), -- khusus tipe MATCHING
    is_correct        BOOLEAN NOT NULL DEFAULT false,
    order_index       INT     NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_question_options_question_id ON question_options (question_id);

-- =============================================================================
-- 4. BANK SOAL (lepas dari form manapun, milik guru — lihat batch fix Bank Soal)
-- =============================================================================
CREATE TABLE IF NOT EXISTS bank_questions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject       VARCHAR(100),
    topic         VARCHAR(100),
    difficulty    VARCHAR(20) NOT NULL DEFAULT 'MEDIUM', -- EASY | MEDIUM | HARD
    question_text TEXT NOT NULL,
    question_type VARCHAR(30) NOT NULL,
    code_language VARCHAR(30),
    img_url       VARCHAR(255),
    audio_url     VARCHAR(255),
    video_url     VARCHAR(255),
    points        INT NOT NULL DEFAULT 10,
    created_at    TIMESTAMP NOT NULL DEFAULT now(),
    updated_at    TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_bank_questions_user_id ON bank_questions (user_id);
CREATE INDEX IF NOT EXISTS idx_bank_questions_subject ON bank_questions (subject);
CREATE INDEX IF NOT EXISTS idx_bank_questions_topic ON bank_questions (topic);
CREATE INDEX IF NOT EXISTS idx_bank_questions_difficulty ON bank_questions (difficulty);
CREATE INDEX IF NOT EXISTS idx_bank_questions_question_type ON bank_questions (question_type);

CREATE TABLE IF NOT EXISTS bank_question_options (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_question_id  UUID NOT NULL REFERENCES bank_questions(id) ON DELETE CASCADE,
    option_text       TEXT NOT NULL,
    img_url           VARCHAR(255),
    audio_url         VARCHAR(255),
    video_url         VARCHAR(255),
    match_key         VARCHAR(255),
    match_target_text VARCHAR(255),
    is_correct        BOOLEAN NOT NULL DEFAULT false,
    order_index       INT     NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_bank_question_options_bank_question_id ON bank_question_options (bank_question_id);

-- =============================================================================
-- 5. SHARE MONITORING — kolaborator form (lihat batch fix Share Monitoring)
-- =============================================================================
CREATE TABLE IF NOT EXISTS form_collaborators (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id    UUID NOT NULL REFERENCES forms(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role       VARCHAR(20) NOT NULL DEFAULT 'MONITOR', -- cuma role ini yang ada saat ini
    invited_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_form_collaborator ON form_collaborators (form_id, user_id);

-- =============================================================================
-- 6. RESPONSES (pengerjaan ujian/form oleh siswa/responden)
-- =============================================================================
CREATE TABLE IF NOT EXISTS form_responses (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id                  UUID NOT NULL REFERENCES forms(id) ON DELETE CASCADE,
    user_id                  UUID REFERENCES users(id),
    respondent_email         VARCHAR(100) NOT NULL,
    status                   VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS', -- IN_PROGRESS|SUBMITTED|RESTARTED|BLOCKED
    current_question_index   INT NOT NULL DEFAULT 1,
    tab_switch_count         INT NOT NULL DEFAULT 0,
    blur_count               INT NOT NULL DEFAULT 0,
    device_platform          VARCHAR(30) NOT NULL DEFAULT 'WEB',
    warning_message          TEXT,
    is_warning_acknowledged  BOOLEAN NOT NULL DEFAULT false,
    ip_address               VARCHAR(45),
    user_agent               TEXT,
    total_score              DOUBLE PRECISION,
    is_auto_submitted        BOOLEAN NOT NULL DEFAULT false,
    started_at               TIMESTAMP NOT NULL DEFAULT now(),
    last_heartbeat           TIMESTAMP NOT NULL DEFAULT now(),
    submitted_at             TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_form_responses_form_id ON form_responses (form_id);
CREATE INDEX IF NOT EXISTS idx_form_responses_user_id ON form_responses (user_id);
CREATE INDEX IF NOT EXISTS idx_form_responses_status ON form_responses (status);

CREATE TABLE IF NOT EXISTS response_answers (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    response_id        UUID NOT NULL REFERENCES form_responses(id) ON DELETE CASCADE,
    question_id        UUID NOT NULL REFERENCES questions(id),
    selected_option_id UUID REFERENCES question_options(id),
    answer_text        TEXT,
    score_given        DOUBLE PRECISION,
    is_flagged         BOOLEAN NOT NULL DEFAULT false,
    match_pair_json     JSONB
);
CREATE INDEX IF NOT EXISTS idx_response_answers_response_id ON response_answers (response_id);
CREATE INDEX IF NOT EXISTS idx_response_answers_question_id ON response_answers (question_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_resp_question ON response_answers (response_id, question_id);

CREATE TABLE IF NOT EXISTS proctoring_logs (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    response_id   UUID NOT NULL REFERENCES form_responses(id) ON DELETE CASCADE,
    event_type    VARCHAR(50) NOT NULL,
    event_message TEXT,
    metadata      JSONB,
    created_at    TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_proctoring_logs_response_id ON proctoring_logs (response_id);
CREATE INDEX IF NOT EXISTS idx_proctoring_logs_event_type ON proctoring_logs (event_type);

-- =============================================================================
-- Data awal (opsional) — akun superadmin pertama, kalau kamu mau seed manual.
-- GANTI password_hash di bawah dengan hash bcrypt asli sebelum dipakai — placeholder
-- ini BUKAN hash valid, cuma penanda supaya kamu tidak lupa menggantinya.
-- =============================================================================
-- INSERT INTO users (name, email, password_hash, role, is_active)
-- VALUES ('Super Admin', 'superadmin@hidocs.id', 'GANTI_DENGAN_BCRYPT_HASH_ASLI', 'superadmin', true)
-- ON CONFLICT (email) DO NOTHING;
