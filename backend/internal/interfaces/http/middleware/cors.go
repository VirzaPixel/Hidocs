package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// CORS sebelumnya hardcoded "Access-Control-Allow-Origin: *" tanpa peduli env
// ALLOWED_ORIGINS (yang sudah ada di .env.example tapi tidak pernah dibaca).
// Sekarang menerima daftar origin dari config; kalau kosong atau berisi "*",
// perilakunya sama seperti sebelumnya (permissive), supaya tidak ada yang tiba-tiba
// putus di frontend yang sudah jalan.
//
// FIX (revisi ke-2): SEBELUMNYA ada bug di sini — header
// "Access-Control-Allow-Credentials: true" selalu di-set berbarengan dengan
// "Access-Control-Allow-Origin: *". Kombinasi ini DILARANG oleh spesifikasi CORS,
// sehingga browser (Chrome/Firefox/dll) menolak seluruh response dan menampilkan
// error seolah header Allow-Origin "hilang", padahal server sudah mengirimnya.
// Aplikasi ini tidak pakai cookie sama sekali (JWT dikirim via header
// Authorization), jadi Allow-Credentials tidak dibutuhkan — dihapus total di
// bawah ini.
func CORS(allowedOrigins []string) gin.HandlerFunc {
	allowAll := len(allowedOrigins) == 0
	allowed := make(map[string]bool, len(allowedOrigins))
	for _, o := range allowedOrigins {
		if o == "*" {
			allowAll = true
		}
		allowed[o] = true
	}

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")

		switch {
		case allowAll:
			c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		case origin != "" && allowed[origin]:
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
			c.Writer.Header().Set("Vary", "Origin")
		}

		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With, X-Exambro-Token")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
