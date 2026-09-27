"""
Two-Factor Authentication models for ResQNav
"""

import random
import string
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta


class TwoFactorMethod(models.Model):
    """Store 2FA methods for users"""
    class MethodType(models.TextChoices):
        SMS = "sms", "SMS"
        EMAIL = "email", "Email"
        TOTP = "totp", "Time-based OTP (Authenticator App)"

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='two_factor_method_obj'
    )
    method_type = models.CharField(
        max_length=20,
        choices=MethodType.choices,
        default=MethodType.SMS
    )
    enabled = models.BooleanField(default=False)
    phone_number = models.CharField(max_length=20, blank=True)  # For SMS
    backup_codes = models.JSONField(default=list, blank=True)  # Backup codes
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"2FA for {self.user.username} ({self.method_type})"


class TwoFactorOTP(models.Model):
    """One-Time Passwords for 2FA verification"""
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        VERIFIED = "verified", "Verified"
        EXPIRED = "expired", "Expired"
        FAILED = "failed", "Failed"

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='two_factor_otps'
    )
    
    code = models.CharField(max_length=6, unique=True)  # 6-digit code
    method_type = models.CharField(
        max_length=20,
        choices=TwoFactorMethod.MethodType.choices
    )
    recipient = models.CharField(max_length=255)  # Phone or email
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING
    )
    attempts = models.IntegerField(default=0)
    max_attempts = models.IntegerField(default=3)
    
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"OTP for {self.user.username}"

    @staticmethod
    def generate_code():
        """Generate a random 6-digit code"""
        return ''.join(random.choices(string.digits, k=6))

    def is_valid(self):
        """Check if OTP is still valid"""
        return (
            self.status == self.Status.PENDING and
            timezone.now() < self.expires_at and
            self.attempts < self.max_attempts
        )

    def verify(self, code):
        """Verify the OTP code"""
        self.attempts += 1
        
        if not self.is_valid():
            self.status = self.Status.EXPIRED if timezone.now() >= self.expires_at else self.Status.FAILED
            self.save()
            return False
        
        if self.code != code:
            self.save()
            return False
        
        self.status = self.Status.VERIFIED
        self.verified_at = timezone.now()
        self.save()
        return True


class TwoFactorBackupCode(models.Model):
    """Backup codes for 2FA recovery"""
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='two_factor_backup_codes'
    )
    code = models.CharField(max_length=16, unique=True)
    used = models.BooleanField(default=False)
    used_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Backup code for {self.user.username}"

    @staticmethod
    def generate_codes(count=10):
        """Generate multiple backup codes"""
        codes = []
        for _ in range(count):
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8)) + '-' + \
                   ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            codes.append(code)
        return codes

    def use(self):
        """Mark backup code as used"""
        self.used = True
        self.used_at = timezone.now()
        self.save()
