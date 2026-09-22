package database

import (
	"fmt"
	"log"
	"strings"
	"time"

	"backend/config"
	"backend/internal/domain"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func NewPostgresDB(cfg *config.Config) (*gorm.DB, error) {
	// 1. First connect to default 'postgres' database to verify/create target database if AutoMigrate is enabled
	if cfg.AutoMigrate {
		defaultDSN := fmt.Sprintf(
			"host=%s user=%s password=%s dbname=postgres port=%s sslmode=%s TimeZone=Asia/Jakarta",
			cfg.DBHost, cfg.DBUser, cfg.DBPassword, cfg.DBPort, cfg.DBSSLMode,
		)

		defaultDB, err := gorm.Open(postgres.Open(defaultDSN), &gorm.Config{
			Logger: logger.Default.LogMode(logger.Silent),
		})
		if err == nil {
			var count int
			checkQuery := fmt.Sprintf("SELECT count(*) FROM pg_database WHERE datname = '%s'", cfg.DBName)
			defaultDB.Raw(checkQuery).Scan(&count)
			if count == 0 {
				createDBQuery := fmt.Sprintf("CREATE DATABASE %s", cfg.DBName)
				if createErr := defaultDB.Exec(createDBQuery).Error; createErr != nil {
					log.Printf("Warning: failed to auto-create database %s: %v", cfg.DBName, createErr)
				} else {
					log.Printf("Database '%s' created successfully!", cfg.DBName)
				}
			}
			sqlDB, _ := defaultDB.DB()
			if sqlDB != nil {
				sqlDB.Close()
			}
		}
	}

	// 2. Connect to the target database
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=Asia/Jakarta",
		cfg.DBHost, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBPort, cfg.DBSSLMode,
	)

	gormConfig := &gorm.Config{
		PrepareStmt:            true, // Cache prepared statements for high query throughput
		SkipDefaultTransaction: true, // Skip auto-transactions for single write queries to reduce locks
	}
	switch strings.ToLower(cfg.DBLogLevel) {
	case "silent":
		gormConfig.Logger = logger.Default.LogMode(logger.Silent)
	case "info":
		gormConfig.Logger = logger.Default.LogMode(logger.Info)
	case "error":
		gormConfig.Logger = logger.Default.LogMode(logger.Error)
	default: // "warn"
		gormConfig.Logger = logger.Default.LogMode(logger.Warn)
	}

	db, err := gorm.Open(postgres.Open(dsn), gormConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get sql.DB instance: %w", err)
	}

	// Performance Optimization for 500+ Concurrent Students (Tuned Pool Settings)
	// FIX: sebelumnya hardcoded 150/30, mengabaikan DB_MAX_OPEN_CONNS/DB_MAX_IDLE_CONNS
	// yang sudah ada di .env.example. Sekarang dibaca dari config (dengan default sama
	// seperti sebelumnya kalau env tidak diisi).
	maxOpen := cfg.DBMaxOpenConns
	if maxOpen <= 0 {
		maxOpen = 150
	}
	maxIdle := cfg.DBMaxIdleConns
	if maxIdle <= 0 {
		maxIdle = 30
	}
	sqlDB.SetMaxOpenConns(maxOpen)
	sqlDB.SetMaxIdleConns(maxIdle)
	sqlDB.SetConnMaxLifetime(5 * time.Minute)
	sqlDB.SetConnMaxIdleTime(2 * time.Minute)

	log.Println("PostgreSQL connected successfully with high-concurrency pool settings and prepared statements cache")

	// Run Auto Migration only if AUTO_MIGRATE is true
	if cfg.AutoMigrate {
		log.Println("Running AutoMigration...")
		db.Exec("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";")

		err = db.AutoMigrate(
			&domain.User{},
			&domain.PasswordReset{},
			&domain.Form{},
			&domain.FormSettings{},
			&domain.Question{},
			&domain.QuestionOption{},
			&domain.FormResponse{},
			&domain.ResponseAnswer{},
			&domain.ProctoringLog{},
			// FIX: tabel baru untuk Bank Soal dan Share Monitoring.
			&domain.BankQuestion{},
			&domain.BankQuestionOption{},
			&domain.FormCollaborator{},
		)
		if err != nil {
			return nil, fmt.Errorf("auto migration failed: %w", err)
		}

		// Ensure composite performance indexes
		db.Exec("CREATE INDEX IF NOT EXISTS idx_form_responses_active_session ON form_responses(form_id, respondent_email, status);")
		db.Exec("CREATE INDEX IF NOT EXISTS idx_form_responses_form_heartbeat ON form_responses(form_id, last_heartbeat DESC);")
		db.Exec("CREATE INDEX IF NOT EXISTS idx_forms_user_created ON forms(user_id, created_at DESC);")
		db.Exec("CREATE INDEX IF NOT EXISTS idx_response_answers_resp_flag ON response_answers(response_id, is_flagged);")
		db.Exec("CREATE INDEX IF NOT EXISTS idx_proctoring_logs_resp_created ON proctoring_logs(response_id, created_at DESC);")

		log.Println("AutoMigration completed successfully with performance indexes")
	}

	return db, nil
}
