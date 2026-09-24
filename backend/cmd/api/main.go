package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"backend/config"
	_ "backend/docs"
	"backend/internal/application/service"
	"backend/internal/domain"
	"backend/internal/infrastructure/cache"
	"backend/internal/infrastructure/database"
	"backend/internal/infrastructure/email"
	"backend/internal/infrastructure/parser"
	"backend/internal/infrastructure/repository"
	"backend/internal/infrastructure/security"
	"backend/internal/interfaces/http/handler"
	"backend/internal/interfaces/http/router"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// @title HiDocs Backend API (Form & Exam Maker)
// @version 1.0
// @description High-performance backend API for HiDocs Form & Exam Maker application using Golang and Domain-Driven Design (DDD).
// @termsOfService http://swagger.io/terms/

// @contact.name HiDocs Support
// @contact.email support@hidocs.id

// @BasePath /
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization

func main() {
	cfg := config.LoadConfig()

	// Initialize Postgres DB
	db, err := database.NewPostgresDB(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	// Security & External Infrastructure Components
	hasher := security.NewBcryptHasher()
	jwtManager := security.NewJWTManager(cfg.JWTSecret, cfg.JWTAccessExpireMin, cfg.JWTExpireHr)
	docxParser := parser.NewDocxParser()
	redisClient := cache.NewRedisClient(cfg)
	emailSender := email.NewSMTPEmailSender(cfg)

	// Repositories
	userRepo := repository.NewUserRepository(db)
	formRepo := repository.NewFormRepository(db)
	questionRepo := repository.NewQuestionRepository(db)
	responseRepo := repository.NewResponseRepository(db)
	adminRepo := repository.NewAdminRepository(db)
	// FIX: repository baru untuk Share Monitoring dan Bank Soal.
	collaboratorRepo := repository.NewCollaboratorRepository(db)
	bankQuestionRepo := repository.NewBankQuestionRepository(db)

	// Services
	// FIX: redisClient dipakai dua peran — sebagai OTP cache dan sebagai
	// whitelist refresh token (Opsi A) supaya sesi bisa dicabut saat logout.
	authService := service.NewAuthService(userRepo, hasher, jwtManager, redisClient, redisClient, emailSender)
	userService := service.NewUserService(userRepo, hasher)
	// FIX: NewFormService sekarang butuh appBaseURL (QR code) + collabRepo/userRepo
	// (Share Monitoring).
	formService := service.NewFormService(formRepo, responseRepo, redisClient, cfg.AppBaseURL, collaboratorRepo, userRepo)
	questionService := service.NewQuestionService(questionRepo, formRepo)
	// FIX: NewResponseService sekarang butuh collaboratorRepo (Share Monitoring).
	responseService := service.NewResponseService(responseRepo, formRepo, questionRepo, collaboratorRepo)
	docxService := service.NewDocxService(docxParser, formRepo, questionRepo)
	exportService := service.NewExportService(formRepo, responseRepo, questionRepo)
	adminService := service.NewAdminService(adminRepo, userRepo, hasher)
	metricsService := service.NewMetricsService(db, formRepo)
	// FIX: sebelumnya AIService tidak pernah diinstantiate sama sekali.
	aiService := service.NewAIService(cfg, formRepo, questionRepo, responseRepo)
	// FIX: service baru untuk Bank Soal.
	questionBankService := service.NewQuestionBankService(bankQuestionRepo, questionRepo, formRepo)

	// Handlers
	authHandler := handler.NewAuthHandler(authService)
	userHandler := handler.NewUserHandler(userService)
	formHandler := handler.NewFormHandler(formService, docxService)
	questionHandler := handler.NewQuestionHandler(questionService, formService)
	responseHandler := handler.NewResponseHandler(responseService, exportService)
	publicHandler := handler.NewPublicHandler(formService)
	adminHandler := handler.NewAdminHandler(adminService)
	metricsHandler := handler.NewMetricsHandler(metricsService)
	// FIX: sebelumnya AIHandler tidak pernah diinstantiate sama sekali.
	aiHandler := handler.NewAIHandler(aiService)
	// FIX: handler baru untuk Bank Soal.
	questionBankHandler := handler.NewQuestionBankHandler(questionBankService)

	// Router
	r := router.SetupRouter(&router.RouterConfig{
		AuthHandler:     authHandler,
		UserHandler:     userHandler,
		FormHandler:     formHandler,
		QuestionHandler: questionHandler,
		ResponseHandler: responseHandler,
		PublicHandler:   publicHandler,
		AdminHandler:    adminHandler,
		MetricsHandler:  metricsHandler,
		AIHandler:       aiHandler,
		QuestionBankHandler: questionBankHandler,
		JWTManager:      jwtManager,
		Cfg:             cfg,
	})

	// Auto-seed default SuperAdmin and Test Exam Form for load testing
	seedSuperAdmin(db, hasher)
	seedTestExam(db)

	serverAddr := fmt.Sprintf(":%s", cfg.AppPort)
	log.Printf("🚀 HiDocs Backend Server running on port %s", cfg.AppPort)

	srv := &http.Server{
		Addr:         serverAddr,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 120 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Server failed: %v", err)
	}
}

func seedSuperAdmin(db *gorm.DB, hasher security.PasswordHasher) {
	var user domain.User
	err := db.Where("email = ?", "admin@hidocs.id").First(&user).Error
	if err != nil {
		hashed, _ := hasher.HashPassword("admin123")
		admin := &domain.User{
			ID:           uuid.MustParse("8763d91d-7257-4863-a42d-7ceb5047446e"),
			Name:         "System Admin",
			Email:        "admin@hidocs.id",
			PasswordHash: hashed,
			Role:         domain.RoleAdmin,
			IsActive:     true,
		}
		if createErr := db.Create(admin).Error; createErr == nil {
			log.Println("✅ Default system admin created: admin@hidocs.id / admin123")
		}
	}
}

func seedTestExam(db *gorm.DB) {
	var count int64
	db.Model(&domain.Form{}).Where("custom_url = ? OR id = ?", "perhatikan-ilustrasi-berikut-berdasarkan-jenisnya", "346ed6d4-94e4-4012-924d-1ba66e048a9f").Count(&count)
	if count > 0 {
		// Update status to ACTIVE to ensure it is publicly accessible
		db.Model(&domain.Form{}).Where("id = ?", "346ed6d4-94e4-4012-924d-1ba66e048a9f").Update("status", domain.StatusActive)
		return
	}

	var admin domain.User
	if err := db.Where("email = ?", "admin@hidocs.id").First(&admin).Error; err != nil {
		return
	}

	formID := uuid.MustParse("346ed6d4-94e4-4012-924d-1ba66e048a9f")
	form := &domain.Form{
		ID:          formID,
		UserID:      admin.ID,
		Title:       "Perhatikan ilustrasi berikut! (Berdasarkan Jenisnya)",
		Description: "Pada saat terjadi ketegangan di wilayah perbatasan laut Indonesia...",
		Type:        domain.TypeExam,
		CustomURL:   "perhatikan-ilustrasi-berikut-berdasarkan-jenisnya",
		Status:      domain.StatusActive,
		IsTemplate:  false,
	}

	if err := db.Create(form).Error; err != nil {
		log.Printf("Warning: failed to seed test exam form: %v", err)
		return
	}

	duration := 60
	settings := &domain.FormSettings{
		ID:                  uuid.New(),
		FormID:              formID,
		DurationMinutes:     &duration,
		AutoActiveDays:      30,
		IsActiveImmediately: true,
	}
	db.Create(settings)

	q1ID := uuid.New()
	q1 := &domain.Question{
		ID:           q1ID,
		FormID:       formID,
		QuestionText: "Berdasarkan jenisnya, ilustrasi di atas termasuk bentuk ancaman jenis apa?",
		QuestionType: domain.TypeMultipleChoice,
		Points:       50,
		OrderIndex:   1,
		IsAutoScored: true,
	}
	db.Create(q1)

	db.Create(&domain.QuestionOption{ID: uuid.New(), QuestionID: q1ID, OptionText: "Militer", IsCorrect: true, OrderIndex: 1})
	db.Create(&domain.QuestionOption{ID: uuid.New(), QuestionID: q1ID, OptionText: "Non-Militer", IsCorrect: false, OrderIndex: 2})
	db.Create(&domain.QuestionOption{ID: uuid.New(), QuestionID: q1ID, OptionText: "Hibrida", IsCorrect: false, OrderIndex: 3})

	log.Println("✅ Test Exam Form seeded successfully (Status: ACTIVE)")
}
