package middleware

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"backend/pkg/response"
	"github.com/gin-gonic/gin"
)

type clientLimit struct {
	count     int
	lastReset time.Time
}

var (
	clients   = make(map[string]*clientLimit)
	rateMu    sync.RWMutex
	cleanOnce sync.Once
)

func initRateLimitCleaner() {
	go func() {
		ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			rateMu.Lock()
			now := time.Now()
			for ip, client := range clients {
				if now.Sub(client.lastReset) > 2*time.Minute {
					delete(clients, ip)
				}
			}
			rateMu.Unlock()
		}
	}()
}

func RateLimiter(requestsPerMinute int) gin.HandlerFunc {
	cleanOnce.Do(initRateLimitCleaner)

	return func(c *gin.Context) {
		path := c.Request.URL.Path

		// 1. Bypass rate limiter for school/campus NAT WiFi on active student exam endpoints
		// (Autosave, Telemetry, Session State, Submit, Verify Token)
		if strings.Contains(path, "/public/responses/") ||
			strings.HasSuffix(path, "/submit") ||
			strings.HasSuffix(path, "/verify-token") {
			c.Next()
			return
		}

		ip := c.ClientIP()

		// 2. Bypass rate limiter for localhost/loopback IP
		if ip == "127.0.0.1" || ip == "::1" || ip == "localhost" {
			c.Next()
			return
		}

		rateMu.Lock()
		client, exists := clients[ip]
		if !exists || time.Since(client.lastReset) > time.Minute {
			clients[ip] = &clientLimit{
				count:     1,
				lastReset: time.Now(),
			}
			rateMu.Unlock()
			c.Next()
			return
		}

		if client.count >= requestsPerMinute {
			rateMu.Unlock()
			response.Error(c, http.StatusTooManyRequests, "Rate limit exceeded. Please try again later.", nil)
			c.Abort()
			return
		}

		client.count++
		rateMu.Unlock()
		c.Next()
	}
}
