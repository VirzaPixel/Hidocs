package middleware

import (
	"strings"

	"backend/internal/domain"
	"backend/internal/infrastructure/security"
	"backend/pkg/response"
	"github.com/gin-gonic/gin"
)

const (
	UserContextKey = "user_claims"
)

func RequireAuth(jwtManager *security.JWTManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.Unauthorized(c, "Authorization header is required", nil)
			c.Abort()
			return
		}

		tokenStr := authHeader
		if strings.HasPrefix(authHeader, "Bearer ") {
			tokenStr = strings.TrimPrefix(authHeader, "Bearer ")
		} else if strings.HasPrefix(authHeader, "bearer ") {
			tokenStr = strings.TrimPrefix(authHeader, "bearer ")
		}

		tokenStr = strings.TrimSpace(tokenStr)
		claims, err := jwtManager.ValidateToken(tokenStr)
		if err != nil {
			response.Unauthorized(c, "Invalid or expired token", err)
			c.Abort()
			return
		}

		c.Set(UserContextKey, claims)
		c.Next()
	}
}

func RequireRole(roles ...domain.UserRole) gin.HandlerFunc {
	return func(c *gin.Context) {
		claimsVal, exists := c.Get(UserContextKey)
		if !exists {
			response.Unauthorized(c, "Unauthorized access", nil)
			c.Abort()
			return
		}

		claims, ok := claimsVal.(*security.JWTClaims)
		if !ok {
			response.Unauthorized(c, "Invalid token claims", nil)
			c.Abort()
			return
		}

		roleAllowed := false
		for _, r := range roles {
			if claims.Role == r {
				roleAllowed = true
				break
			}
		}

		if !roleAllowed {
			response.Forbidden(c, "You do not have permission to access this resource", nil)
			c.Abort()
			return
		}

		c.Next()
	}
}
