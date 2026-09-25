-- =========================================================
-- HiDocs Backend Relational Database Schema (PostgreSQL)
-- =========================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'user',
    avatar_url VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 2. Forms Table
CREATE TABLE IF NOT EXISTS forms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL DEFAULT 'General',
    type VARCHAR(20) NOT NULL DEFAULT 'SURVEY',
    custom_url VARCHAR(100) UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    is_template BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 3. Form Settings Table
CREATE TABLE IF NOT EXISTS form_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID NOT NULL UNIQUE REFERENCES forms(id) ON DELETE CASCADE,
    duration_minutes INT DEFAULT NULL,
    auto_active_days INT DEFAULT 30,
    is_active_immediately BOOLEAN DEFAULT FALSE,
    is_one_time_submission BOOLEAN DEFAULT FALSE,
    randomize_questions BOOLEAN DEFAULT FALSE,
    randomize_options BOOLEAN DEFAULT FALSE,
    start_time TIMESTAMP DEFAULT NULL,
    end_time TIMESTAMP DEFAULT NULL,
    theme_color VARCHAR(50) DEFAULT '#4F46E5',
    cover_image_url VARCHAR(255) DEFAULT NULL,
    logo_url VARCHAR(255) DEFAULT NULL,
    font_family VARCHAR(50) DEFAULT 'Inter',
    allow_backtrack BOOLEAN DEFAULT TRUE,
    show_question_number BOOLEAN DEFAULT TRUE,
    fullscreen_mode BOOLEAN DEFAULT FALSE,
    exam_token VARCHAR(50) DEFAULT NULL,
    is_token_protected BOOLEAN DEFAULT FALSE,
    result_visibility VARCHAR(30) DEFAULT 'hidden',
    access_mode VARCHAR(20) DEFAULT 'qr-only'
);

-- 4. Questions Table
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID NOT NULL REFERENCES forms(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(30) NOT NULL,
    code_language VARCHAR(30) DEFAULT NULL,
    img_url VARCHAR(255) DEFAULT NULL,
    audio_url VARCHAR(255) DEFAULT NULL,
    video_url VARCHAR(255) DEFAULT NULL,
    is_auto_scored BOOLEAN DEFAULT TRUE,
    points INT DEFAULT 1,
    order_index INT NOT NULL DEFAULT 0,
    is_required BOOLEAN DEFAULT FALSE,
    correct_rating INT DEFAULT NULL,
    is_autosaved_at TIMESTAMP DEFAULT NULL
);

-- 5. Question Options Table
CREATE TABLE IF NOT EXISTS question_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    img_url VARCHAR(255) DEFAULT NULL,
    audio_url VARCHAR(255) DEFAULT NULL,
    video_url VARCHAR(255) DEFAULT NULL,
    match_key VARCHAR(255) DEFAULT NULL,
    match_target_text VARCHAR(255) DEFAULT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    order_index INT NOT NULL DEFAULT 0
);

-- 6. Form Responses Table
CREATE TABLE IF NOT EXISTS form_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID NOT NULL REFERENCES forms(id) ON DELETE CASCADE,
    user_id UUID DEFAULT NULL REFERENCES users(id) ON DELETE SET NULL,
    respondent_email VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    current_question_index INT DEFAULT 1,
    tab_switch_count INT DEFAULT 0,
    blur_count INT DEFAULT 0,
    device_platform VARCHAR(30) DEFAULT 'WEB',
    warning_message TEXT DEFAULT NULL,
    is_warning_acknowledged BOOLEAN DEFAULT FALSE,
    ip_address VARCHAR(45) DEFAULT NULL,
    user_agent TEXT DEFAULT NULL,
    total_score FLOAT DEFAULT NULL,
    is_auto_submitted BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_heartbeat TIMESTAMP DEFAULT NOW(),
    submitted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 7. Response Answers Table
CREATE TABLE IF NOT EXISTS response_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    response_id UUID NOT NULL REFERENCES form_responses(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    selected_option_id UUID DEFAULT NULL REFERENCES question_options(id) ON DELETE SET NULL,
    answer_text TEXT DEFAULT NULL,
    score_given FLOAT DEFAULT NULL,
    is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    match_pair_json JSONB DEFAULT NULL,
    CONSTRAINT uq_response_question_answer UNIQUE (response_id, question_id)
);

-- 8. Proctoring Logs Table
CREATE TABLE IF NOT EXISTS proctoring_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    response_id UUID NOT NULL REFERENCES form_responses(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    event_message TEXT DEFAULT NULL,
    metadata JSONB DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for Query Performance Optimization
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_forms_user_id ON forms(user_id);
CREATE INDEX IF NOT EXISTS idx_forms_custom_url ON forms(custom_url);
CREATE INDEX IF NOT EXISTS idx_forms_category ON forms(category);
CREATE INDEX IF NOT EXISTS idx_forms_status_type ON forms(status, type);
CREATE INDEX IF NOT EXISTS idx_forms_user_created ON forms(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_form_settings_form_id ON form_settings(form_id);
CREATE INDEX IF NOT EXISTS idx_questions_form_id ON questions(form_id);
CREATE INDEX IF NOT EXISTS idx_question_options_question_id ON question_options(question_id);
CREATE INDEX IF NOT EXISTS idx_form_responses_form_id ON form_responses(form_id);
CREATE INDEX IF NOT EXISTS idx_form_responses_user_id ON form_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_form_responses_status ON form_responses(status);
CREATE INDEX IF NOT EXISTS idx_form_responses_submitted_at ON form_responses(submitted_at);
CREATE INDEX IF NOT EXISTS idx_form_responses_form_email_submitted ON form_responses(form_id, respondent_email, submitted_at);
CREATE INDEX IF NOT EXISTS idx_form_responses_active_session ON form_responses(form_id, respondent_email, status);
CREATE INDEX IF NOT EXISTS idx_form_responses_form_heartbeat ON form_responses(form_id, last_heartbeat DESC);
CREATE INDEX IF NOT EXISTS idx_response_answers_response_id ON response_answers(response_id);
CREATE INDEX IF NOT EXISTS idx_response_answers_question_id ON response_answers(question_id);
CREATE INDEX IF NOT EXISTS idx_response_answers_resp_flag ON response_answers(response_id, is_flagged);
CREATE INDEX IF NOT EXISTS idx_proctoring_logs_response_id ON proctoring_logs(response_id);
CREATE INDEX IF NOT EXISTS idx_proctoring_logs_event_type ON proctoring_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_proctoring_logs_resp_created ON proctoring_logs(response_id, created_at DESC);
