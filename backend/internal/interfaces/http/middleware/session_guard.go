package middleware

import (
	"backend/pkg/response"
	"backend/pkg/session"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func RequireExamSession(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		rid := c.Param("response_id")
		if _, err := uuid.Parse(rid); err != nil {
			response.BadRequest(c, "Invalid response_id UUID format", err)
			c.Abort()
			return
		}

		token := c.GetHeader("X-Session-Token")
		if !session.ValidateExamSessionToken(rid, token, secret) {
			response.Unauthorized(c, "Invalid or missing exam session token", nil)
			c.Abort()
			return
		}

		c.Next()
	}
}
