package cache

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"sync"
	"time"

	"backend/config"
	"github.com/google/uuid"
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

// RefreshTokenState adalah status sebuah refresh token di whitelist.
type RefreshTokenState string

const (
	// RefreshTokenActive: token masih terdaftar dan boleh ditukar dengan token baru.
	RefreshTokenActive RefreshTokenState = "active"
	// RefreshTokenRotatedRecently: token baru saja dirotasi (masih di dalam
	// jendela toleransi). Pemakaian ulang pada rentang ini dianggap wajar —
	// mis. dua tab browser atau web+HP memanggil /auth/refresh hampir
	// bersamaan — sehingga TIDAK boleh mencabut sesi siapa pun.
	RefreshTokenRotatedRecently RefreshTokenState = "rotated_recently"
	// RefreshTokenRotated: token sudah dirotasi dan jendela toleransi sudah
	// lewat. Pemakaian ulang di sini menandakan token berpotensi dicuri,
	// sehingga seluruh sesi user perlu dicabut.
	RefreshTokenRotated RefreshTokenState = "rotated"
	// RefreshTokenUnknown: token tidak dikenal — sudah dicabut lewat logout,
	// sudah kedaluwarsa, atau dicabut karena reset password. Tolak saja tanpa
	// mencabut sesi lain (perangkat lain harus tetap bisa jalan).
	RefreshTokenUnknown RefreshTokenState = "unknown"
)

// RefreshTokenStore adalah whitelist refresh token (Opsi A). JWT refresh
// bersifat stateless — tanpa whitelist ini token tidak bisa dicabut saat
// logout maupun diputar (rotasi) setelah dipakai, sehingga token yang bocor
// tetap valid sampai masa berlakunya habis.
//
// Implementasinya memakai Redis (dengan fallback in-memory seperti OTP cache)
// sehingga TTL-nya otomatis bersih dan tidak perlu tabel/migrasi baru.
type RefreshTokenStore interface {
	StoreRefreshToken(ctx context.Context, userID uuid.UUID, jti string, ttl time.Duration) error
	RefreshTokenState(ctx context.Context, userID uuid.UUID, jti string) (RefreshTokenState, error)
	// MarkRefreshTokenRotated menandai token lama sebagai terpakai.
	// detectionTTL menyimpan penanda untuk deteksi pencurian jangka panjang,
	// sedangkan replayGraceTTL menyimpan penanda berumur pendek untuk
	// menoleransi pemakaian ulang akibat balapan antar-klien (<= 0 berarti
	// toleransi dimatikan).
	MarkRefreshTokenRotated(ctx context.Context, userID uuid.UUID, jti string, detectionTTL, replayGraceTTL time.Duration) error
	RevokeRefreshToken(ctx context.Context, userID uuid.UUID, jti string) error
	RevokeAllRefreshTokens(ctx context.Context, userID uuid.UUID) error
}

const (
	refreshKeyPrefix      = "refresh:"       // refresh:<user_id>:<jti> -> token aktif
	refreshUsedKeyPrefix  = "refresh:used:"  // refresh:used:<user_id>:<jti> -> penanda rotasi (deteksi pencurian)
	refreshGraceKeyPrefix = "refresh:grace:" // refresh:grace:<user_id>:<jti> -> toleransi replay (balapan antar-klien)
)

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

// ---------------------------------------------------------------------------
// Refresh Token Whitelist (Opsi A: access token pendek + refresh token panjang)
// ---------------------------------------------------------------------------

// refreshTokenKey membentuk kunci Redis per token, bukan per user, supaya satu
// user bisa login di beberapa perangkat sekaligus dan tiap sesi bisa dicabut
// secara terpisah (mis. logout dari HP saja).
func refreshTokenKey(userID uuid.UUID, jti string) string {
	return fmt.Sprintf("%s%s:%s", refreshKeyPrefix, userID.String(), jti)
}

func refreshTokenUserPrefix(userID uuid.UUID) string {
	return refreshKeyPrefix + userID.String() + ":"
}

// refreshTokenUsedKey menyimpan tombstone (penanda) untuk refresh token yang
// sudah dirotasi. Tombstone ini yang membedakan "token dicabut karena logout"
// (tidak berbahaya) dengan "token dipakai ulang setelah rotasi" (indikasi
// pencurian token).
func refreshTokenUsedKey(userID uuid.UUID, jti string) string {
	return fmt.Sprintf("%s%s:%s", refreshUsedKeyPrefix, userID.String(), jti)
}

// refreshTokenGraceKey menyimpan penanda berumur pendek setelah rotasi, dipakai
// untuk menoleransi pemakaian ulang token yang sah (balapan antar-klien: dua tab
// browser, atau web + HP, memakai refresh token yang sama hampir bersamaan).
func refreshTokenGraceKey(userID uuid.UUID, jti string) string {
	return fmt.Sprintf("%s%s:%s", refreshGraceKeyPrefix, userID.String(), jti)
}

// StoreRefreshToken menyimpan jti refresh token yang baru diterbitkan dengan
// TTL sama dengan umur token. Setelah TTL habis, kunci hilang sendiri sehingga
// Redis tidak menumpuk data token mati.
func (c *RedisClient) StoreRefreshToken(ctx context.Context, userID uuid.UUID, jti string, ttl time.Duration) error {
	key := refreshTokenKey(userID, jti)
	if c.isFallback {
		c.mu.Lock()
		defer c.mu.Unlock()
		c.memStore[key] = memItem{value: string(RefreshTokenActive), expiresAt: time.Now().Add(ttl)}
		return nil
	}
	return c.rdb.Set(ctx, key, string(RefreshTokenActive), ttl).Err()
}

// MarkRefreshTokenRotated menghapus token dari daftar aktif, menulis penanda
// rotasi jangka panjang (detectionTTL, untuk deteksi pencurian), dan — bila
// replayGraceTTL > 0 — menulis penanda pendek yang menandakan pemakaian ulang
// dalam rentang itu masih wajar (balapan antar-klien).
func (c *RedisClient) MarkRefreshTokenRotated(ctx context.Context, userID uuid.UUID, jti string, detectionTTL, replayGraceTTL time.Duration) error {
	key := refreshTokenKey(userID, jti)
	usedKey := refreshTokenUsedKey(userID, jti)
	graceKey := refreshTokenGraceKey(userID, jti)

	if c.isFallback {
		c.mu.Lock()
		defer c.mu.Unlock()
		delete(c.memStore, key)
		c.memStore[usedKey] = memItem{value: string(RefreshTokenRotated), expiresAt: time.Now().Add(detectionTTL)}
		if replayGraceTTL > 0 {
			c.memStore[graceKey] = memItem{value: string(RefreshTokenRotatedRecently), expiresAt: time.Now().Add(replayGraceTTL)}
		} else {
			delete(c.memStore, graceKey)
		}
		return nil
	}

	pipe := c.rdb.Pipeline()
	pipe.Del(ctx, key)
	pipe.Set(ctx, usedKey, string(RefreshTokenRotated), detectionTTL)
	if replayGraceTTL > 0 {
		pipe.Set(ctx, graceKey, string(RefreshTokenRotatedRecently), replayGraceTTL)
	} else {
		pipe.Del(ctx, graceKey)
	}
	_, err := pipe.Exec(ctx)
	return err
}

// RefreshTokenState mengembalikan status token: active, rotated_recently
// (masih dalam jendela toleransi), rotated (dirotasi lama → indikasi pencurian),
// atau unknown (sudah logout/kedaluwarsa → tolak biasa tanpa mencabut sesi lain).
func (c *RedisClient) RefreshTokenState(ctx context.Context, userID uuid.UUID, jti string) (RefreshTokenState, error) {
	key := refreshTokenKey(userID, jti)
	usedKey := refreshTokenUsedKey(userID, jti)
	graceKey := refreshTokenGraceKey(userID, jti)

	if c.isFallback {
		c.mu.RLock()
		defer c.mu.RUnlock()

		now := time.Now()
		if item, exists := c.memStore[key]; exists && now.Before(item.expiresAt) {
			// Nilai tak dikenal (mis. sisa versi lama) diperlakukan sebagai token
			// tidak valid, bukan otomatis "active".
			if item.value == string(RefreshTokenActive) {
				return RefreshTokenActive, nil
			}
			return RefreshTokenUnknown, nil
		}
		if item, exists := c.memStore[graceKey]; exists && now.Before(item.expiresAt) {
			return RefreshTokenRotatedRecently, nil
		}
		if item, exists := c.memStore[usedKey]; exists && now.Before(item.expiresAt) {
			return RefreshTokenRotated, nil
		}
		return RefreshTokenUnknown, nil
	}

	// Pipeline: 1 round-trip untuk tiga key sekaligus.
	pipe := c.rdb.Pipeline()
	activeCmd := pipe.Get(ctx, key)
	usedCmd := pipe.Get(ctx, usedKey)
	graceCmd := pipe.Get(ctx, graceKey)
	if _, err := pipe.Exec(ctx); err != nil && !errors.Is(err, redis.Nil) {
		return RefreshTokenUnknown, err
	}

	if val, err := activeCmd.Result(); err == nil && val == string(RefreshTokenActive) {
		return RefreshTokenActive, nil
	}
	if _, err := graceCmd.Result(); err == nil {
		return RefreshTokenRotatedRecently, nil
	}
	if _, err := usedCmd.Result(); err == nil {
		return RefreshTokenRotated, nil
	}
	return RefreshTokenUnknown, nil
}

// RevokeRefreshToken mencabut satu sesi (satu jti). Dipakai saat logout dari
// satu perangkat. Penanda rotasi (24 jam) sengaja TIDAK dihapus agar pemakaian
// ulang token lama tetap terdeteksi sebagai pencurian; penanda grace dihapus
// supaya token lama tidak bisa "dihidupkan lagi" setelah logout.
func (c *RedisClient) RevokeRefreshToken(ctx context.Context, userID uuid.UUID, jti string) error {
	key := refreshTokenKey(userID, jti)
	graceKey := refreshTokenGraceKey(userID, jti)
	if c.isFallback {
		c.mu.Lock()
		defer c.mu.Unlock()
		delete(c.memStore, key)
		delete(c.memStore, graceKey)
		return nil
	}
	return c.rdb.Del(ctx, key, graceKey).Err()
}

// RevokeAllRefreshTokens mencabut semua sesi milik satu user. Dipakai untuk
// logout dari semua perangkat, setelah reset password, dan saat terdeteksi
// pemakaian ulang refresh token (indikasi token dicuri).
//
// Yang dihapus adalah token aktif + penanda grace (jendela toleransi replay);
// penanda rotasi jangka panjang tetap disimpan agar deteksi pencurian masih
// bekerja dan token lama tidak bisa dipakai lagi.
func (c *RedisClient) RevokeAllRefreshTokens(ctx context.Context, userID uuid.UUID) error {
	activePrefix := refreshTokenUserPrefix(userID)
	gracePrefix := refreshGraceKeyPrefix + userID.String() + ":"

	if c.isFallback {
		c.mu.Lock()
		defer c.mu.Unlock()
		for k := range c.memStore {
			if strings.HasPrefix(k, activePrefix) || strings.HasPrefix(k, gracePrefix) {
				delete(c.memStore, k)
			}
		}
		return nil
	}

	for _, pattern := range []string{activePrefix + "*", gracePrefix + "*"} {
		var cursor uint64
		for {
			keys, next, err := c.rdb.Scan(ctx, cursor, pattern, 100).Result()
			if err != nil {
				return err
			}
			if len(keys) > 0 {
				if err := c.rdb.Del(ctx, keys...).Err(); err != nil {
					return err
				}
			}
			cursor = next
			if cursor == 0 {
				break
			}
		}
	}
	return nil
}
