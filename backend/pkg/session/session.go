package session

import (
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
)

func GenerateExamSessionToken(responseID, secret string) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte("exam-session:" + responseID))
	return hex.EncodeToString(mac.Sum(nil))
}

func ValidateExamSessionToken(responseID, token, secret string) bool {
	if responseID == "" || token == "" || secret == "" {
		return false
	}
	expected := GenerateExamSessionToken(responseID, secret)
	return subtle.ConstantTimeCompare([]byte(expected), []byte(token)) == 1
}
