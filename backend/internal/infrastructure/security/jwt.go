package security

import (
	"errors"
	"time"

	"backend/internal/domain"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// TokenType membedakan access token (umur pendek, dipakai tiap request) dengan
// refresh token (umur panjang, hanya dipakai untuk minta access token baru).
type TokenType string

const (
	TokenTypeAccess  TokenType = "access"
	TokenTypeRefresh TokenType = "refresh"
)

// Default & ambang batas umur token. Nilai default bisa dioverride lewat env
// JWT_ACCESS_EXPIRE_MINUTES dan JWT_REFRESH_EXPIRE_HOURS.
const (
	DefaultAccessExpireMinutes = 60  // 1 jam
	DefaultRefreshExpireHours  = 336 // 14 hari
	MinAccessExpireMinutes     = 5
	MinRefreshExpireHours      = 24
)

type JWTClaims struct {
	UserID uuid.UUID       `json:"user_id"`
	Email  string          `json:"email"`
	Role   domain.UserRole `json:"role"`
	// Type bernilai "access" atau "refresh". Token lama (diterbitkan sebelum
	// refresh token ada) tidak punya field ini, sehingga middleware
	// memperlakukannya sebagai access token agar deploy tidak memaksa seluruh
	// pengguna login ulang.
	Type TokenType `json:"type,omitempty"`
	jwt.RegisteredClaims
}

type JWTManager struct {
	secretKey        []byte
	accessExpireMins int
	refreshExpireHrs int
}

func NewJWTManager(secretKey string, accessExpireMinutes, refreshExpireHours int) *JWTManager {
	if accessExpireMinutes < MinAccessExpireMinutes {
		accessExpireMinutes = DefaultAccessExpireMinutes
	}
	if refreshExpireHours < MinRefreshExpireHours {
		refreshExpireHours = DefaultRefreshExpireHours
	}
	return &JWTManager{
		secretKey:        []byte(secretKey),
		accessExpireMins: accessExpireMinutes,
		refreshExpireHrs: refreshExpireHours,
	}
}

// AccessExpiresIn adalah umur access token (dipakai untuk field expires_in).
func (j *JWTManager) AccessExpiresIn() time.Duration {
	return time.Duration(j.accessExpireMins) * time.Minute
}

// RefreshExpiresIn adalah umur refresh token (dipakai sebagai TTL whitelist di Redis).
func (j *JWTManager) RefreshExpiresIn() time.Duration {
	return time.Duration(j.refreshExpireHrs) * time.Hour
}

// generateToken membuat JWT bertipe tertentu lengkap dengan jti (JWT ID) unik.
// jti inilah yang disimpan di Redis sebagai whitelist refresh token sehingga
// token bisa dicabut (logout) walau JWT sendiri bersifat stateless.
func (j *JWTManager) generateToken(user *domain.User, tokenType TokenType, ttl time.Duration) (string, string, error) {
	now := time.Now()
	jti := uuid.NewString()

	claims := JWTClaims{
		UserID: user.ID,
		Email:  user.Email,
		Role:   user.Role,
		Type:   tokenType,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        jti,
			Subject:   user.ID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(ttl)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(j.secretKey)
	if err != nil {
		return "", "", err
	}
	return signed, jti, nil
}

// GenerateAccessToken membuat access token berumur pendek (default 1 jam).
func (j *JWTManager) GenerateAccessToken(user *domain.User) (string, error) {
	token, _, err := j.generateToken(user, TokenTypeAccess, j.AccessExpiresIn())
	return token, err
}

// GenerateRefreshToken membuat refresh token berumur panjang (default 14 hari).
// Nilai jti yang dikembalikan WAJIB disimpan ke RefreshTokenStore, jika tidak
// token ini tidak akan bisa dipakai untuk refresh.
func (j *JWTManager) GenerateRefreshToken(user *domain.User) (string, string, error) {
	return j.generateToken(user, TokenTypeRefresh, j.RefreshExpiresIn())
}

func (j *JWTManager) parseClaims(tokenStr string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return j.secretKey, nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		return nil, domain.ErrInvalidToken
	}

	return claims, nil
}

// ValidateToken memvalidasi signature + umur token tanpa memeriksa tipenya.
// Dipertahankan untuk kompatibilitas ke belakang.
func (j *JWTManager) ValidateToken(tokenStr string) (*JWTClaims, error) {
	return j.parseClaims(tokenStr)
}

// ValidateAccessToken memastikan token valid DAN bertipe access (atau token
// legacy tanpa field type), sehingga refresh token tidak bisa dipakai untuk
// mengakses endpoint protected.
func (j *JWTManager) ValidateAccessToken(tokenStr string) (*JWTClaims, error) {
	claims, err := j.parseClaims(tokenStr)
	if err != nil {
		return nil, err
	}
	if claims.Type != "" && claims.Type != TokenTypeAccess {
		return nil, domain.ErrInvalidToken
	}
	return claims, nil
}

// ValidateRefreshToken memastikan token valid, bertipe refresh, dan punya jti.
func (j *JWTManager) ValidateRefreshToken(tokenStr string) (*JWTClaims, error) {
	claims, err := j.parseClaims(tokenStr)
	if err != nil {
		return nil, domain.ErrInvalidRefreshToken
	}
	if claims.Type != TokenTypeRefresh || claims.ID == "" {
		return nil, domain.ErrInvalidRefreshToken
	}
	return claims, nil
}
