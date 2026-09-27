"""Authentication Serializers with proper token handling"""
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer, TokenRefreshSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
from .models_tokens import TokenBlacklist, SessionLog, DeviceToken


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Enhanced token serializer with custom claims"""
    
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        
        # Add custom claims
        token['username'] = user.username
        token['email'] = user.email
        token['full_name'] = user.get_full_name()
        token['user_id'] = user.id
        
        return token
    
    def validate(self, attrs):
        data = super().validate(attrs)
        
        # Get user from credentials
        user = self.user
        
        # Log session
        request = self.context.get('request')
        if request:
            ip_address = self._get_client_ip(request)
            user_agent = request.META.get('HTTP_USER_AGENT', '')
            
            SessionLog.objects.create(
                user=user,
                ip_address=ip_address,
                user_agent=user_agent,
            )
        
        return data
    
    def _get_client_ip(self, request):
        """Extract client IP from request"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class CustomTokenRefreshSerializer(TokenRefreshSerializer):
    """Enhanced refresh token serializer with validation"""
    
    def validate(self, attrs):
        refresh_token = attrs['refresh']
        
        # Check if token is blacklisted
        if TokenBlacklist.is_token_blacklisted(refresh_token):
            raise serializers.ValidationError('Refresh token has been revoked.')
        
        data = super().validate(attrs)
        return data


class LogoutSerializer(serializers.Serializer):
    """Serialize logout request"""
    refresh = serializers.CharField()
    
    def validate_refresh(self, value):
        """Validate refresh token"""
        try:
            RefreshToken(value)
        except Exception as e:
            raise serializers.ValidationError(str(e))
        return value
    
    def save(self):
        """Blacklist the token"""
        refresh_token = self.validated_data['refresh']
        token = RefreshToken(refresh_token)
        user = self.context['request'].user
        
        # Add both access and refresh to blacklist
        TokenBlacklist.add_token_to_blacklist(token, user)
        
        return {'detail': 'Successfully logged out.'}


class DeviceTokenSerializer(serializers.ModelSerializer):
    """Manage push notification device tokens"""
    
    class Meta:
        model = DeviceToken
        fields = ['id', 'device_id', 'device_type', 'push_token', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']


class SessionLogSerializer(serializers.ModelSerializer):
    """Serialize user session logs for audit"""
    
    class Meta:
        model = SessionLog
        fields = [
            'id', 'ip_address', 'user_agent', 'device_type',
            'location', 'login_at', 'logout_at', 'duration_seconds',
            'is_suspicious'
        ]
        read_only_fields = fields
