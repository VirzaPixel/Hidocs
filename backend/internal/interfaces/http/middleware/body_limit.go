package middleware

import (
	"net/http"
	"strings"

	"backend/pkg/response"
	"github.com/gin-gonic/gin"
)

// BodyLimit membatasi ukuran JSON agar submit massal tidak OOM.
// Multipart (upload/import) dikecualikan karena sudah divalidasi per-handler.
func BodyLimit(maxMB int) gin.HandlerFunc {
	if maxMB <= 0 {
		maxMB = 2
	}
	maxBytes := int64(maxMB) << 20
	return func(c *gin.Context) {
		ct := c.GetHeader("Content-Type")
		if strings.HasPrefix(ct, "multipart/form-data") {
			c.Next()
			return
		}
		if c.Request.ContentLength > maxBytes && c.Request.ContentLength > 0 {
			response.Error(c, http.StatusRequestEntityTooLarge, "Request body too large", nil)
			c.Abort()
			return
		}
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
		c.Next()
	}
}
