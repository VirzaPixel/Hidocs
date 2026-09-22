package cache

import (
	"context"
	"log"
	"sync"
	"time"
	"fmt"
	"strings"

	"backend/config"
	"github.com/redis/go-redis/v9"
)

type OTPCache interface {
	SetOTP(ctx context.Context, email, otp string, ttl time.Duration) error
	GetOTP(ctx context.Context, email string) (string, error)
	DeleteOTP(ctx context.Context, email string) error
	
	// Temporary user registration storage during OTP verification
	SetPendingUser(ctx context.Context, email, payload string, ttl time.Duration) error
	GetPendingUser(ctx context.Context, email string) (string, error)
}

type RedisClient struct {
	rdb        *redis.Client
	isFallback bool
	memStore   map[string]memItem
	mu         sync.RWMutex
}

type memItem struct {
	value     string
	expiresAt time.Time
}

func NewRedisClient(cfg *config.Config) *RedisClient {
	redisAddr := cfg.RedisHost
	if !strings.Contains(redisAddr, ":") {
		redisAddr = fmt.Sprintf("%s:6379", redisAddr)
	}

	rdb := redis.NewClient(&redis.Options{
		Addr:     redisAddr, // Gunakan redisAddr yang sudah dipastikan ada port-nya
		Password: cfg.RedisPassword,
		DB:       cfg.RedisDB,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	client := &RedisClient{
		rdb:      rdb,
		memStore: make(map[string]memItem),
	}

	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Printf("⚠️ Redis server not available at %s, using fallback in-memory OTP cache: %v", redisAddr, err)
		client.isFallback = true
	} else {
		log.Printf("✅ Connected to Redis server at %s", redisAddr)
	}

	return client
}

func cleanEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

func (c *RedisClient) SetOTP(ctx context.Context, email, otp string, ttl time.Duration) error {
	email = cleanEmail(email)
	if c.isFallback {
		c.mu.Lock()
		defer c.mu.Unlock()
		c.memStore["otp:"+email] = memItem{
			value:     otp,
			expiresAt: time.Now().Add(ttl),
		}
		return nil
	}
	return c.rdb.Set(ctx, "otp:"+email, otp, ttl).Err()
}

func (c *RedisClient) GetOTP(ctx context.Context, email string) (string, error) {
	email = cleanEmail(email)
	if c.isFallback {
		c.mu.RLock()
		defer c.mu.RUnlock()
		item, exists := c.memStore["otp:"+email]
		if !exists || time.Now().After(item.expiresAt) {
			return "", redis.Nil
		}
		return item.value, nil
	}
	return c.rdb.Get(ctx, "otp:"+email).Result()
}

func (c *RedisClient) DeleteOTP(ctx context.Context, email string) error {
	email = cleanEmail(email)
	if c.isFallback {
		c.mu.Lock()
		defer c.mu.Unlock()
		delete(c.memStore, "otp:"+email)
		delete(c.memStore, "pending:"+email)
		return nil
	}
	c.rdb.Del(ctx, "otp:"+email)
	c.rdb.Del(ctx, "pending:"+email)
	return nil
}

func (c *RedisClient) SetPendingUser(ctx context.Context, email, payload string, ttl time.Duration) error {
	email = cleanEmail(email)
	if c.isFallback {
		c.mu.Lock()
		defer c.mu.Unlock()
		c.memStore["pending:"+email] = memItem{
			value:     payload,
			expiresAt: time.Now().Add(ttl),
		}
		return nil
	}
	return c.rdb.Set(ctx, "pending:"+email, payload, ttl).Err()
}

func (c *RedisClient) GetPendingUser(ctx context.Context, email string) (string, error) {
	email = cleanEmail(email)
	if c.isFallback {
		c.mu.RLock()
		defer c.mu.RUnlock()
		item, exists := c.memStore["pending:"+email]
		if !exists || time.Now().After(item.expiresAt) {
			return "", redis.Nil
		}
		return item.value, nil
	}
	return c.rdb.Get(ctx, "pending:"+email).Result()
}

func (c *RedisClient) SetCache(ctx context.Context, key, val string, ttl time.Duration) error {
	if c.isFallback {
		c.mu.Lock()
		defer c.mu.Unlock()
		c.memStore[key] = memItem{
			value:     val,
			expiresAt: time.Now().Add(ttl),
		}
		return nil
	}
	return c.rdb.Set(ctx, key, val, ttl).Err()
}

func (c *RedisClient) GetCache(ctx context.Context, key string) (string, error) {
	if c.isFallback {
		c.mu.RLock()
		defer c.mu.RUnlock()
		item, exists := c.memStore[key]
		if !exists || time.Now().After(item.expiresAt) {
			return "", redis.Nil
		}
		return item.value, nil
	}
	return c.rdb.Get(ctx, key).Result()
}

func (c *RedisClient) DeleteCache(ctx context.Context, key string) error {
	if c.isFallback {
		c.mu.Lock()
		defer c.mu.Unlock()
		delete(c.memStore, key)
		return nil
	}
	return c.rdb.Del(ctx, key).Err()
}
