package session

import "testing"

func TestSessionTokenRoundtrip(t *testing.T) {
	secret := "test-secret-min-32-karakter-123456"
	tok := GenerateExamSessionToken("resp-123", secret)
	if !ValidateExamSessionToken("resp-123", tok, secret) {
		t.Fatal("valid token rejected")
	}
	if ValidateExamSessionToken("resp-999", tok, secret) {
		t.Fatal("wrong response accepted")
	}
	if ValidateExamSessionToken("resp-123", "bogus", secret) {
		t.Fatal("bogus token accepted")
	}
	if ValidateExamSessionToken("resp-123", tok, "wrong-secret") {
		t.Fatal("wrong secret accepted")
	}
}
