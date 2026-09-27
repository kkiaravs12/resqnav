"""Extended authentication models for ResQNav"""

from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import uuid

class PasswordResetToken(models.Model):
    """One-time password reset tokens"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='password_reset_tokens')
    token = models.CharField(max_length=255, unique=True, default=uuid.uuid4)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used = models.BooleanField(default=False)
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def is_valid(self):
        return not self.used and timezone.now() < self.expires_at

    def __str__(self):
        return f"Reset token for {self.user.username}"


class EmailVerificationToken(models.Model):
    """Email verification tokens for new accounts"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='email_verification')
    token = models.CharField(max_length=255, unique=True, default=uuid.uuid4)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    verified = models.BooleanField(default=False)
    verified_at = models.DateTimeField(null=True, blank=True)

    def is_valid(self):
        return not self.verified and timezone.now() < self.expires_at

    def __str__(self):
        return f"Email verification for {self.user.username}"


class UserProfile(models.Model):
    """Extended user profile"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    phone_number = models.CharField(max_length=20, blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    bio = models.TextField(max_length=500, blank=True)
    location = models.CharField(max_length=200, blank=True)
    blood_group = models.CharField(
        max_length=5,
        choices=[
            ('O+', 'O+'),
            ('O-', 'O-'),
            ('A+', 'A+'),
            ('A-', 'A-'),
            ('B+', 'B+'),
            ('B-', 'B-'),
            ('AB+', 'AB+'),
            ('AB-', 'AB-'),
        ],
        blank=True
    )
    medical_conditions = models.TextField(blank=True, help_text="Any allergies or medical conditions")
    emergency_verified = models.BooleanField(default=False)
    sms_notifications = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=True)
    push_notifications = models.BooleanField(default=True)
    two_factor_enabled = models.BooleanField(default=False)
    two_factor_method = models.CharField(
        max_length=10,
        choices=[('sms', 'SMS'), ('email', 'Email'), ('app', 'Authenticator App')],
        blank=True
    )
    login_attempts = models.IntegerField(default=0)
    last_login_attempt = models.DateTimeField(null=True, blank=True)
    account_locked_until = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Profile of {self.user.username}"


class GoogleOAuthToken(models.Model):
    """Google OAuth tokens"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='google_oauth')
    google_id = models.CharField(max_length=255, unique=True)
    access_token = models.TextField()
    refresh_token = models.TextField(blank=True)
    token_expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Google OAuth for {self.user.username}"


class LoginHistory(models.Model):
    """Track user login attempts and locations"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='login_history')
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField(blank=True)
    device_name = models.CharField(max_length=200, blank=True)
    location = models.CharField(max_length=200, blank=True)
    success = models.BooleanField(default=True)
    reason_failed = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        status = "Success" if self.success else "Failed"
        return f"{self.user.username} - {status} - {self.created_at}"


class AuditLog(models.Model):
    """Audit trail for sensitive actions"""
    ACTION_CHOICES = [
        ('login', 'Login'),
        ('logout', 'Logout'),
        ('password_change', 'Password Changed'),
        ('email_change', 'Email Changed'),
        ('emergency_contact_add', 'Emergency Contact Added'),
        ('emergency_contact_delete', 'Emergency Contact Deleted'),
        ('emergency_alert', 'Emergency Alert Triggered'),
        ('profile_update', 'Profile Updated'),
        ('permission_change', 'Permissions Changed'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='audit_logs')
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    description = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField()
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.user.username} - {self.action} - {self.timestamp}"
