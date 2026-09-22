package config

import (
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	AppPort    string
	AppEnv     string
	AppBaseURL string // Base URL publik (untuk QR code, short link, dsb). Contoh: https://hidocs.id

	DBHost      string
	DBPort      string
	DBUser      string
	DBPassword  string
	DBName      string
	DBSSLMode   string
	DBLogLevel  string
	AutoMigrate bool

	// Connection pool (sebelumnya hardcoded di postgres.go, sekarang bisa dikonfigurasi)
	DBMaxOpenConns int
	DBMaxIdleConns int

	RedisHost     string
	RedisPassword string
	RedisDB       int

	SMTPHost     string
	SMTPPort     string
	SMTPUser     string
	SMTPPassword string

	JWTSecret   string
	JWTExpireHr int

	// FIX: field ini sebelumnya TIDAK ADA di struct, padahal sudah dipakai di
	// internal/application/service/ai_service.go (cfg.GeminiAPIKey, cfg.GeminiModel).
	// Tanpa ini, project tidak bisa di-compile (undefined field).
	GeminiAPIKey string
	GeminiModel  string

	// GROQ_API_KEY: masih dibaca untuk kompatibilitas, tapi AI generate
	// sekarang via Gemini SDK (google.golang.org/genai). Biarkan kosong
	// jika tidak dipakai.
	GroqAPIKey string
	GroqModel  string

	// FIX: sebelumnya ada di .env.example tapi tidak pernah dibaca ke Config,
	// jadi CORS selalu hardcoded ke "*" dan upload/body limit tidak pernah divalidasi
	// dari env sama sekali.
	AllowedOrigins   []string
	MaxUploadMB      int // batas upload gambar soal (questions/upload-image)
	MaxMediaUploadMB int // batas upload audio/video (questions/upload-media)
	RateLimitPerMin  int
	BodyLimitMB      int
}

func LoadConfig() *Config {
	if err := godotenv.Load(); err != nil {
		_ = godotenv.Load(filepath.Join("backend", ".env"))
	}
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}
	geminiKey := envFirst("GEMINI_API_KEY", "GOOGLE_API_KEY", "GENAI_API_KEY", "AI_API_KEY")

	jwtExpire, _ := strconv.Atoi(getEnv("JWT_EXPIRE_HOURS", "24"))
	autoMigrate, _ := strconv.ParseBool(getEnv("AUTO_MIGRATE", "true"))
	redisDB, _ := strconv.Atoi(getEnv("REDIS_DB", "0"))

	dbMaxOpenConns, _ := strconv.Atoi(getEnv("DB_MAX_OPEN_CONNS", "150"))
	dbMaxIdleConns, _ := strconv.Atoi(getEnv("DB_MAX_IDLE_CONNS", "30"))

	maxUploadMB, _ := strconv.Atoi(getEnv("MAX_UPLOAD_MB", "1"))
	maxMediaUploadMB, _ := strconv.Atoi(getEnv("MAX_MEDIA_UPLOAD_MB", "10"))
	rateLimitPerMin, _ := strconv.Atoi(getEnv("RATE_LIMIT_PER_MIN", "500"))
	bodyLimitMB, _ := strconv.Atoi(getEnv("BODY_LIMIT_MB", "2"))

	allowedOriginsRaw := getEnv("ALLOWED_ORIGINS", "*")
	var allowedOrigins []string
	for _, o := range strings.Split(allowedOriginsRaw, ",") {
		o = strings.TrimSpace(o)
		if o != "" {
			allowedOrigins = append(allowedOrigins, o)
		}
	}

	return &Config{
		AppPort:    getEnv("APP_PORT", "8080"),
		AppEnv:     getEnv("APP_ENV", "development"),
		AppBaseURL: getEnv("APP_BASE_URL", "http://localhost:5173"),

		DBHost:      getEnv("DB_HOST", "127.0.0.1"),
		DBPort:      getEnv("DB_PORT", "5432"),
		DBUser:      getEnv("DB_USER", "postgres"),
		DBPassword:  getEnv("DB_PASSWORD", ""),
		DBName:      getEnv("DB_NAME", "hidocs_db"),
		DBSSLMode:   getEnv("DB_SSLMODE", "disable"),
		DBLogLevel:  getEnv("DB_LOG_LEVEL", "warn"),
		AutoMigrate: autoMigrate,

		DBMaxOpenConns: dbMaxOpenConns,
		DBMaxIdleConns: dbMaxIdleConns,

		RedisHost:     getEnv("REDIS_HOST", "127.0.0.1"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       redisDB,

		SMTPHost:     getEnv("SMTP_HOST", "smtp.gmail.com"),
		SMTPPort:     getEnv("SMTP_PORT", "587"),
		SMTPUser:     getEnv("SMTP_USER", ""),
		SMTPPassword: getEnv("SMTP_PASSWORD", ""),

		JWTSecret:   getEnv("JWT_SECRET", "dev-secret-change-in-prod"),
		JWTExpireHr: jwtExpire,

		GeminiAPIKey: geminiKey,
		GeminiModel:  getEnv("GEMINI_MODEL", "gemini-2.5-flash"),
		GroqAPIKey:   envFirst("GROQ_API_KEY", "GROQ_KEY"),
		GroqModel:    getEnv("GROQ_MODEL", "llama-3.1-8b-instant"),

		AllowedOrigins:   allowedOrigins,
		MaxUploadMB:      maxUploadMB,
		MaxMediaUploadMB: maxMediaUploadMB,
		RateLimitPerMin:  rateLimitPerMin,
		BodyLimitMB:      bodyLimitMB,
	}
}

func envFirst(keys ...string) string {
	for _, k := range keys {
		if v := strings.TrimSpace(os.Getenv(k)); v != "" {
			return v
		}
	}
	return ""
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
