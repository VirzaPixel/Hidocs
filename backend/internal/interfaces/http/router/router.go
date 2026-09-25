package router

import (
	"backend/config"
	"backend/internal/domain"
	"backend/internal/infrastructure/security"
	"backend/internal/interfaces/http/handler"
	"backend/internal/interfaces/http/middleware"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

type RouterConfig struct {
	AuthHandler     *handler.AuthHandler
	UserHandler     *handler.UserHandler
	FormHandler     *handler.FormHandler
	QuestionHandler *handler.QuestionHandler
	ResponseHandler *handler.ResponseHandler
	PublicHandler   *handler.PublicHandler
	AdminHandler    *handler.AdminHandler
	MetricsHandler  *handler.MetricsHandler
	// FIX: sebelumnya tidak ada field ini sama sekali, jadi seluruh endpoint AI
	// (generate soal, grading esai) tidak mungkin di-route walau handler-nya sudah jadi.
	AIHandler  *handler.AIHandler
	// FIX: baru — handler untuk Bank Soal.
	QuestionBankHandler *handler.QuestionBankHandler
	WSHandler           *handler.WSHandler
	JWTManager          *security.JWTManager
	// FIX: dibutuhkan supaya CORS, RateLimiter, dan BodyLimit bisa pakai nilai dari
	// env (config) alih-alih angka/daftar yang di-hardcode di file ini.
	Cfg *config.Config
}

func SetupRouter(cfg *RouterConfig) *gin.Engine {
	r := gin.New()
	if gin.Mode() == gin.DebugMode {
		r.Use(gin.Logger(), gin.Recovery())
	} else {
		r.Use(gin.Recovery())
	}

	rateLimitPerMin := 500
	bodyLimitMB := 2
	var allowedOrigins []string
	if cfg.Cfg != nil {
		if cfg.Cfg.RateLimitPerMin > 0 {
			rateLimitPerMin = cfg.Cfg.RateLimitPerMin
		}
		if cfg.Cfg.BodyLimitMB > 0 {
			bodyLimitMB = cfg.Cfg.BodyLimitMB
		}
		allowedOrigins = cfg.Cfg.AllowedOrigins
	}

	r.Use(middleware.CORS(allowedOrigins))
	r.Use(middleware.RateLimiter(rateLimitPerMin))
	// FIX: middleware ini sudah ditulis lengkap sebelumnya tapi tidak pernah dipasang,
	// jadi tidak ada batas ukuran body request JSON sama sekali di level global.
	r.Use(middleware.BodyLimit(bodyLimitMB))
	r.Use(middleware.TrackMetrics()) // Telemetry & Traffic Collector Middleware

	// Serve Uploaded Local Images Static Files
	r.Static("/uploads", "./uploads")

	// Swagger API Docs
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Healthcheck
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "app": "HiDocs Backend API"})
	})

	api := r.Group("/api/v1")
	{
		// Base /api/v1 ping info
		api.GET("", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"status":  "ok",
				"app":     "HiDocs Backend API v1",
				"version": "1.0",
				"docs":    "/swagger/index.html",
			})
		})

		// 1. Access Short Link / Public Forms & Live Exam Engine
		public := api.Group("/public")
		{
			public.GET("/forms/:short_code", cfg.PublicHandler.GetPublicForm)
			public.GET("/forms/:short_code/qr", cfg.PublicHandler.GetFormQRCode)
			public.POST("/forms/:form_id/verify-token", cfg.PublicHandler.VerifyExamToken)

			// Live Student Session, Autosave, Telemetry (Anti-Cheat)
			public.POST("/responses/:response_id/autosave", cfg.ResponseHandler.AutosaveAnswer)
			public.POST("/responses/:response_id/telemetry", cfg.ResponseHandler.SendTelemetry)
			public.GET("/responses/:response_id/session", cfg.ResponseHandler.GetSessionState)
			public.POST("/responses/:response_id/acknowledge-warning", cfg.ResponseHandler.AcknowledgeWarning)
		}

		// 1b. Real-Time WebSocket for Live Monitoring
		if cfg.WSHandler != nil {
			api.GET("/ws/forms/:form_id/live", cfg.WSHandler.HandleLiveMonitoring)
		}

		// 2. Authentication & OTP Verification
		auth := api.Group("/auth")
		{
			auth.POST("/register", cfg.AuthHandler.Register)
			auth.POST("/verify-otp", cfg.AuthHandler.VerifyOTP)
			auth.POST("/resend-otp", cfg.AuthHandler.ResendOTP)
			auth.POST("/login", cfg.AuthHandler.Login)
			// Refresh token: satu-satunya endpoint yang menerima refresh token.
			// Access token yang sudah expired ditukar dengan pasangan token baru
			// tanpa meminta pengguna login ulang (sliding session).
			auth.POST("/refresh", cfg.AuthHandler.Refresh)
			auth.POST("/forgot-password", cfg.AuthHandler.ForgotPassword)
			auth.POST("/reset-password", cfg.AuthHandler.ResetPassword)
		}

		// Authenticated Routes
		protected := api.Group("")
		protected.Use(middleware.RequireAuth(cfg.JWTManager))
		{
			// 2b. Logout: cabut refresh token (satu perangkat atau semua perangkat).
			protected.POST("/auth/logout", cfg.AuthHandler.Logout)

			// 3. User Profile & Student Import
			users := protected.Group("/users")
			{
				users.GET("/me", cfg.UserHandler.GetProfile)
				users.PUT("/me", cfg.UserHandler.UpdateProfile)
				users.POST("/students/import", cfg.UserHandler.ImportStudents)
			}

			// 4. Forms & Settings
			forms := protected.Group("/forms")
			{
				forms.GET("", cfg.FormHandler.ListForms)
				forms.GET("/categories", cfg.FormHandler.GetCategories)
				forms.POST("", cfg.FormHandler.CreateForm)
				forms.POST("/import-docx", cfg.FormHandler.ImportDocx)
				forms.POST("/import-excel", cfg.FormHandler.ImportExcel)
				// FIX: Import PDF dihapus dari produk (kualitas parsing teks PDF
				// tidak dapat diandalkan). Dihapus route + handler/service terkait.
				forms.GET("/:form_id", cfg.FormHandler.GetFormByID)
				forms.PUT("/:form_id", cfg.FormHandler.UpdateForm)
				forms.DELETE("/:form_id", cfg.FormHandler.DeleteForm)
				forms.PUT("/:form_id/settings", cfg.FormHandler.UpdateFormSettings)

				// Creator Live Proctoring & Anti-Cheat Monitoring
				forms.GET("/:form_id/live-monitoring", cfg.ResponseHandler.GetLiveMonitoring)
				forms.POST("/:form_id/responses/:response_id/restart", cfg.ResponseHandler.RestartStudentSession)
				forms.POST("/:form_id/responses/:response_id/grade", cfg.ResponseHandler.GradeResponse)

				// Questions under form
				forms.GET("/:form_id/questions", cfg.QuestionHandler.GetQuestionsByFormID)
				forms.POST("/:form_id/questions", cfg.QuestionHandler.AddQuestion)

				// Responses & Submissions under form
				forms.GET("/:form_id/responses", cfg.ResponseHandler.GetFormResponses)
				forms.GET("/:form_id/export", cfg.ResponseHandler.ExportResponses)
				forms.GET("/:form_id/analytics", cfg.ResponseHandler.GetAnalytics)

				// FIX: Share Monitoring — undang/lihat/hapus guru pengawas lain.
				forms.POST("/:form_id/collaborators", cfg.FormHandler.AddCollaborator)
				forms.GET("/:form_id/collaborators", cfg.FormHandler.ListCollaborators)
				forms.DELETE("/:form_id/collaborators/:user_id", cfg.FormHandler.RemoveCollaborator)
			}

			// Public Submit Endpoint (or with passcode)
			api.POST("/forms/:form_id/submit", cfg.ResponseHandler.SubmitForm)

			// 5. Questions, Options & Media Storage Upload
			questions := protected.Group("/questions")
			{
				questions.POST("/upload-image", cfg.QuestionHandler.UploadImage)
				questions.POST("/upload-media", cfg.QuestionHandler.UploadMedia)
				questions.PUT("/:question_id", cfg.QuestionHandler.UpdateQuestion)
				questions.DELETE("/:question_id", cfg.QuestionHandler.DeleteQuestion)
				// FIX: Bank Soal — simpan soal form yang sudah ada ke bank.
				questions.POST("/:question_id/save-to-bank", cfg.QuestionBankHandler.SaveFromQuestion)
			}

			// FIX: Bank Soal — CRUD + salin ke form.
			bank := protected.Group("/question-bank")
			{
				bank.GET("", cfg.QuestionBankHandler.List)
				bank.POST("", cfg.QuestionBankHandler.Create)
				bank.PUT("/:id", cfg.QuestionBankHandler.Update)
				bank.DELETE("/:id", cfg.QuestionBankHandler.Delete)
				bank.POST("/:id/add-to-form", cfg.QuestionBankHandler.AddToForm)
			}
			options := protected.Group("/options")
			{
				options.DELETE("/:option_id", cfg.QuestionHandler.DeleteOption)
			}

			// 6. Responses & Grading
			responses := protected.Group("/responses")
			{
				responses.GET("/me", cfg.ResponseHandler.GetMySubmissions)
				responses.GET("/:response_id", cfg.ResponseHandler.GetResponseByID)
				responses.PUT("/:response_id/grade", cfg.ResponseHandler.GradeResponse)
			}

			// 7. AI — Generate Soal & Auto-Grading
			// FIX: seluruh grup ini sebelumnya TIDAK ADA di router, padahal
			// AIHandler + AIService sudah lengkap diimplementasikan. Tanpa ini,
			// endpoint AI selalu 404 walau kodenya sudah jadi.
			ai := protected.Group("/ai")
			{
				ai.GET("/template-prompt", cfg.AIHandler.TemplatePrompt)
				ai.POST("/generate-preview", cfg.AIHandler.GeneratePreview)
				ai.POST("/generate-form", cfg.AIHandler.CreateForm)
				ai.POST("/grade-essay", cfg.AIHandler.GradeEssay)
				ai.POST("/grade-response", cfg.AIHandler.GradeResponse)
				ai.POST("/transcribe", cfg.AIHandler.Transcribe)
				// FIX: baru — ekstraksi materi PDF/Word untuk lampiran AI generate.
				ai.POST("/extract-material", cfg.AIHandler.ExtractMaterial)
			}

			// 8. Admin Exclusive Endpoints
			admin := protected.Group("/admin")
			admin.Use(middleware.RequireRole(domain.RoleAdmin, domain.RoleSuperAdmin))
			{
				admin.GET("/dashboard/stats", cfg.AdminHandler.GetDashboardStats)
				admin.GET("/creators", cfg.AdminHandler.ListCreators)
				admin.POST("/creators", cfg.AdminHandler.CreateCreator)
				admin.PUT("/creators/:creator_id/status", cfg.AdminHandler.UpdateCreatorStatus)
				admin.GET("/forms", cfg.AdminHandler.ListAllForms)
				admin.DELETE("/forms/:form_id", cfg.AdminHandler.DeleteForm)

				// Realtime Metrics & Telemetry Endpoints
				metricsGroup := admin.Group("/metrics")
				{
					metricsGroup.GET("/realtime", cfg.MetricsHandler.GetRealtimeMetrics)
					metricsGroup.GET("/system", cfg.MetricsHandler.GetSystemMetrics)
					metricsGroup.GET("/live-exams", cfg.MetricsHandler.GetLiveExams)
					metricsGroup.GET("/traffic-history", cfg.MetricsHandler.GetTrafficHistory)
					metricsGroup.GET("/forms/:form_id", cfg.MetricsHandler.GetFormMetrics)
				}
			}

			// 9. Superadmin Exclusive
			superadmin := protected.Group("/superadmin")
			superadmin.Use(middleware.RequireRole(domain.RoleSuperAdmin))
			{
				superadmin.POST("/create-admin", cfg.AdminHandler.CreateAdmin)
				superadmin.GET("/list-admin", cfg.AdminHandler.ListAdmins)
			}
		}
	}

	return r
}
