package email

import (
	"fmt"
	"log"
	"net/smtp"

	"backend/config"
)

type EmailSender interface {
	SendOTPEmail(toEmail, otpCode string) error
	SendResetEmail(toEmail, resetToken string) error
}

type SMTPEmailSender struct {
	cfg *config.Config
}

func NewSMTPEmailSender(cfg *config.Config) *SMTPEmailSender {
	return &SMTPEmailSender{cfg: cfg}
}

func (s *SMTPEmailSender) SendOTPEmail(toEmail, otpCode string) error {
	log.Printf("📩 [OTP DISTRIBUTOR] OTP Code for %s is: %s (Expires in 180 seconds)", toEmail, otpCode)

	if s.cfg.SMTPPassword == "" || s.cfg.SMTPUser == "" {
		log.Println("ℹ️ SMTP_PASSWORD/SMTP_USER not configured. OTP printed to console above.")
		return nil
	}

	auth := smtp.PlainAuth("", s.cfg.SMTPUser, s.cfg.SMTPPassword, s.cfg.SMTPHost)
	mime := "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\n\n"
	subject := "Subject: Kode Verifikasi OTP HiDocs\n"
	body := fmt.Sprintf(`
		<!DOCTYPE html>
		<html>
		<head>
			<style>
				body { font-family: Arial, sans-serif; background-color: #f4f6f9; padding: 20px; }
				.card { background: #ffffff; padding: 30px; border-radius: 10px; max-width: 500px; margin: auto; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
				.otp { font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #4F46E5; text-align: center; margin: 20px 0; background: #EEF2FF; padding: 10px; border-radius: 8px; }
			</style>
		</head>
		<body>
			<div class="card">
				<h2>Kode Verifikasi OTP HiDocs</h2>
				<p>Gunakan kode OTP berikut untuk menyelesaikan proses registrasi akun Anda:</p>
				<div class="otp">%s</div>
				<p style="color: #6B7280; font-size: 13px;">Kode ini hanya berlaku selama <strong>180 detik</strong>. Jangan bagikan kode ini kepada siapapun.</p>
			</div>
		</body>
		</html>
	`, otpCode)

	msg := []byte(subject + mime + body)
	addr := fmt.Sprintf("%s:%s", s.cfg.SMTPHost, s.cfg.SMTPPort)

	err := smtp.SendMail(addr, auth, s.cfg.SMTPUser, []string{toEmail}, msg)
	if err != nil {
		log.Printf("⚠️ Failed to send SMTP email to %s: %v", toEmail, err)
		return nil // Non-blocking so dev continues
	}

	log.Printf("✅ OTP Email successfully sent to %s", toEmail)
	return nil
}

func (s *SMTPEmailSender) SendResetEmail(toEmail, resetToken string) error {
	if s.cfg.SMTPPassword == "" || s.cfg.SMTPUser == "" {
		log.Printf("📩 [RESET] Password reset token for %s is: %s (Expires in 1 hour)", toEmail, resetToken)
		return nil
	}

	auth := smtp.PlainAuth("", s.cfg.SMTPUser, s.cfg.SMTPPassword, s.cfg.SMTPHost)
	mime := "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\n\n"
	subject := "Subject: Reset Kata Sandi HiDocs\n"
	body := fmt.Sprintf(`
		<!DOCTYPE html>
		<html>
		<head>
			<style>
				body { font-family: Arial, sans-serif; background-color: #f4f6f9; padding: 20px; }
				.card { background: #ffffff; padding: 30px; border-radius: 10px; max-width: 500px; margin: auto; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
				.token { font-size: 15px; font-weight: bold; color: #4F46E5; text-align: center; margin: 20px 0; background: #EEF2FF; padding: 12px; border-radius: 8px; word-break: break-all; }
			</style>
		</head>
		<body>
			<div class="card">
				<h2>Reset Kata Sandi HiDocs</h2>
				<p>Gunakan token berikut untuk membuat kata sandi baru (berlaku 1 jam, sekali pakai):</p>
				<div class="token">%s</div>
				<p style="color: #6B7280; font-size: 13px;">Jangan bagikan token ini kepada siapapun.</p>
			</div>
		</body>
		</html>
	`, resetToken)

	msg := []byte(subject + mime + body)
	addr := fmt.Sprintf("%s:%s", s.cfg.SMTPHost, s.cfg.SMTPPort)

	if err := smtp.SendMail(addr, auth, s.cfg.SMTPUser, []string{toEmail}, msg); err != nil {
		log.Printf("⚠️ Failed to send reset email to %s: %v", toEmail, err)
		return err
	}

	log.Printf("✅ Reset email successfully sent to %s", toEmail)
	return nil
}
