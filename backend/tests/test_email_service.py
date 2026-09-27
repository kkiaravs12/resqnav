"""Email service unit tests"""
import pytest
from unittest.mock import patch, MagicMock
from django.contrib.auth.models import User
from api.email_services import EmailService, OTPEmailService


@pytest.mark.django_db
class TestEmailService:

    def test_send_verification_email_console(self, user, settings):
        settings.EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
        from django.core import mail
        result = EmailService.send_verification_email(user, "123456")
        assert result is True
        assert len(mail.outbox) == 1
        assert "123456" in mail.outbox[0].body
        assert user.email in mail.outbox[0].to

    def test_send_password_reset_email_console(self, user, settings):
        settings.EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
        from django.core import mail
        result = EmailService.send_password_reset_email(user, "reset-token-abc")
        assert result is True
        assert len(mail.outbox) == 1
        assert "reset-token-abc" in mail.outbox[0].body

    def test_send_otp_email_console(self, user, settings):
        settings.EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
        from django.core import mail
        result = OTPEmailService.send_otp_email(user, "654321")
        assert result is True
        assert "654321" in mail.outbox[0].body

    def test_verification_email_uses_correct_recipient(self, user, settings):
        settings.EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
        from django.core import mail
        EmailService.send_verification_email(user, "000000")
        assert mail.outbox[0].to == ["test@resqnav.com"]

    def test_email_subject_contains_resqnav(self, user, settings):
        settings.EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
        from django.core import mail
        EmailService.send_verification_email(user, "111111")
        assert "ResQNav" in mail.outbox[0].subject

    @patch("api.email_services.EmailService.send_email", side_effect=Exception("SMTP error"))
    def test_verification_email_handles_exception(self, mock_send, user):
        result = EmailService.send_verification_email(user, "999999")
        assert result is False

    @patch("api.email_services.EmailService.send_email", side_effect=Exception("SMTP error"))
    def test_password_reset_handles_exception(self, mock_send, user):
        result = EmailService.send_password_reset_email(user, "bad-token")
        assert result is False
