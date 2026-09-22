package middleware

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"backend/internal/infrastructure/cache"
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
	return rateLimiter(requestsPerMinute, nil)
}

// S-016: Redis-backed limiter (jalan di multi-replica). Fallback ke
// in-memory bila client nil.
func RateLimiterRedis(requestsPerMinute int, client *cache.RedisClient) gin.HandlerFunc {
	return rateLimiter(requestsPerMinute, client)
}

func rateLimiter(requestsPerMinute int, redisClient *cache.RedisClient) gin.HandlerFunc {
	cleanOnce.Do(initRateLimitCleaner)

	return func(c *gin.Context) {
		path := c.Request.URL.Path

		// 1. Autosave, Telemetry, Session State bypass global limiter
		// (diproteksi session-token + dibatasi group limiter 60/mnt).
		// verify-token & submit TIDAK di-bypass (anti brute-force).
		if strings.Contains(path, "/public/responses/") {
			c.Next()
			return
		}

		ip := c.ClientIP()

		// S-016: Redis fixed-window per IP+path (multi-replica safe)
		if redisClient != nil {
			key := "ratelimit:" + c.Request.URL.Path + ":" + ip
			n, err := redisClient.IncrWithTTL(c.Request.Context(), key, time.Minute)
			if err == nil {
				if int(n) > requestsPerMinute {
					response.Error(c, http.StatusTooManyRequests, "Terlalu banyak permintaan. Silakan coba beberapa saat lagi.", nil)
					c.Abort()
					return
				}
				c.Next()
				return
			}
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
			response.Error(c, http.StatusTooManyRequests, "Terlalu banyak permintaan. Silakan coba beberapa saat lagi.", nil)
			c.Abort()
			return
		}

		client.count++
		rateMu.Unlock()
		c.Next()
	}
}
