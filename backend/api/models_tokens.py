"""Token Management Models for JWT"""
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken
import uuid
from datetime import datetime


class TokenBlacklist(models.Model):
    """Store revoked tokens for logout functionality"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blacklisted_tokens')
    token = models.TextField()
    token_type = models.CharField(
        max_length=20,
        choices=[('access', 'Access'), ('refresh', 'Refresh')],
        default='access'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'expires_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.token_type} (blacklisted)"
    
    @classmethod
    def add_token_to_blacklist(cls, token_obj, user):
        """Add token to blacklist with expiration time"""
        token_type = 'refresh' if hasattr(token_obj, 'get_exp_delta') else 'access'
        expires_at = datetime.fromtimestamp(token_obj['exp'], tz=timezone.get_current_timezone())
        
        cls.objects.create(
            user=user,
            token=str(token_obj),
            token_type=token_type,
            expires_at=expires_at
        )
    
    @classmethod
    def is_token_blacklisted(cls, token_str):
        """Check if token is blacklisted"""
        return cls.objects.filter(token=token_str).exists()
    
    @classmethod
    def cleanup_expired(cls):
        """Remove expired tokens from blacklist"""
        cls.objects.filter(expires_at__lt=timezone.now()).delete()


class DeviceToken(models.Model):
    """Track device tokens for push notifications"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='device_tokens')
    device_id = models.CharField(max_length=255, unique=True)
    device_type = models.CharField(
        max_length=20,
        choices=[('ios', 'iOS'), ('android', 'Android'), ('web', 'Web')],
        default='android'
    )
    push_token = models.TextField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('user', 'device_id')
        ordering = ['-last_used_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.device_type}"


class SessionLog(models.Model):
    """Track user session for security audit"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='session_logs')
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    device_type = models.CharField(max_length=50, blank=True)
    location = models.CharField(max_length=255, blank=True)
    login_at = models.DateTimeField(auto_now_add=True)
    logout_at = models.DateTimeField(null=True, blank=True)
    duration_seconds = models.IntegerField(null=True, blank=True)
    is_suspicious = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-login_at']
        indexes = [
            models.Index(fields=['user', 'login_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.login_at}"
    
    def calculate_duration(self):
        """Calculate session duration"""
        if self.logout_at:
            delta = self.logout_at - self.login_at
            self.duration_seconds = int(delta.total_seconds())
            self.save(update_fields=['duration_seconds'])
