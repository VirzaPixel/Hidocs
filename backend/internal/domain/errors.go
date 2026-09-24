package domain

import "errors"

var (
	ErrUserNotFound        = errors.New("user not found")
	ErrUserAlreadyExists   = errors.New("user with this email already exists")
	ErrInvalidCredentials  = errors.New("invalid email or password")
	ErrUnauthorized        = errors.New("unauthorized access")
	ErrForbidden           = errors.New("access forbidden")
	
	ErrFormNotFound        = errors.New("form not found")
	ErrFormClosed          = errors.New("form is closed or not active")
	ErrFormNotStarted      = errors.New("exam has not started yet")
	ErrFormEnded           = errors.New("exam time limit has passed")
	ErrMaxSubmissionsReached = errors.New("maximum submission limit has been reached for this form")
	ErrInvalidPasscode     = errors.New("invalid exam passcode/token")
	ErrAlreadySubmitted    = errors.New("you have already submitted a response for this form")
	
	ErrQuestionNotFound    = errors.New("question not found")
	ErrOptionNotFound      = errors.New("question option not found")
	ErrResponseNotFound    = errors.New("form response not found")
	
	ErrInvalidFileType     = errors.New("invalid file type, only docx is supported")
	ErrInvalidToken        = errors.New("invalid or expired token")
	// ErrInvalidRefreshToken dipakai endpoint POST /auth/refresh saat refresh
	// token tidak valid, kedaluwarsa, atau salah tipe.
	ErrInvalidRefreshToken = errors.New("invalid or expired refresh token")
	// ErrRefreshTokenRevoked menandakan refresh token sudah pernah dipakai
	// (rotasi) atau sudah dicabut lewat logout — indikasi token dicuri/dipakai
	// ulang oleh pihak lain.
	ErrRefreshTokenRevoked = errors.New("refresh token has been revoked or already used")
)
