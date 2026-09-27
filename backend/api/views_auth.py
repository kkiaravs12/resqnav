"""
Authentication and profile views for ResQNav
"""

import logging
from datetime import timedelta

from django.contrib.auth.models import User
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.utils import timezone
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.decorators import throttle_classes

from .models_auth import (
    UserProfile,
    EmailVerificationToken,
    GoogleOAuthToken,
    LoginHistory,
    AuditLog,
)
from .serializers import (
    UserDetailSerializer,
    UserProfileSerializer,
    ChangePasswordSerializer,
    EmailVerificationSerializer,
    VerifyEmailSerializer,
    LoginHistorySerializer,
    AuditLogSerializer,
)
from .services import EmailService, SMSService
from .throttling import (
    PasswordResetThrottle,
    EmailVerificationThrottle,
    GoogleOAuthThrottle,
    GeneralUserThrottle,
)

logger = logging.getLogger(__name__)
_password_reset_tokens = PasswordResetTokenGenerator()


class UserDetailView(APIView):
    """Get detailed user information including profile"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        # Ensure profile exists
        profile, _ = UserProfile.objects.get_or_create(user=user)
        serializer = UserDetailSerializer(user)
        return Response(serializer.data)


class UserProfileView(generics.RetrieveUpdateAPIView):
    """Get and update user profile"""
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        profile, _ = UserProfile.objects.get_or_create(user=self.request.user)
        return profile

    def perform_update(self, serializer):
        profile = serializer.save()
        # Log the update
        AuditLog.objects.create(
            user=self.request.user,
            action='profile_update',
            description=f'Updated profile',
            ip_address=self.get_client_ip()
        )

    def get_client_ip(self):
        """Get client IP address from request"""
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip


class ChangePasswordView(APIView):
    """Change user password"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        old_password = serializer.validated_data['old_password']
        new_password = serializer.validated_data['new_password']

        # Verify old password
        if not user.check_password(old_password):
            return Response(
                {'detail': 'Current password is incorrect.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Set new password
        user.set_password(new_password)
        user.save()

        # Log the action
        AuditLog.objects.create(
            user=user,
            action='password_change',
            description='User changed their password',
            ip_address=self.get_client_ip()
        )

        # Send notification email
        EmailService.send_password_changed(user.email, user.username)

        return Response({'message': 'Password changed successfully.'})

    def get_client_ip(self):
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip


class SendEmailVerificationView(APIView):
    """Send email verification token to user"""
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [EmailVerificationThrottle]

    def post(self, request):
        user = request.user
        
        # Check if email already verified
        profile, _ = UserProfile.objects.get_or_create(user=user)
        if profile.emergency_verified:
            return Response(
                {'message': 'Email is already verified.'},
                status=status.HTTP_200_OK
            )

        # Create or get existing token
        email_verification, _ = EmailVerificationToken.objects.get_or_create(
            user=user,
            defaults={
                'expires_at': timezone.now() + timedelta(hours=24)
            }
        )

        # Reset if expired
        if not email_verification.is_valid():
            email_verification.token = str(__import__('uuid').uuid4())
            email_verification.expires_at = timezone.now() + timedelta(hours=24)
            email_verification.verified = False
            email_verification.save()

        # Send email
        EmailService.send_email_verification(
            user.email,
            email_verification.token,
            user.username
        )

        return Response({
            'message': 'Verification email sent. Please check your inbox.',
            'expires_in_hours': 24
        })


class VerifyEmailView(APIView):
    """Verify email using token"""
    permission_classes = [permissions.AllowAny]
    throttle_classes = [EmailVerificationThrottle]

    def post(self, request):
        serializer = VerifyEmailSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        token = serializer.validated_data['token']

        try:
            email_verification = EmailVerificationToken.objects.get(token=token)
        except EmailVerificationToken.DoesNotExist:
            return Response(
                {'detail': 'Invalid or expired token.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not email_verification.is_valid():
            return Response(
                {'detail': 'This token has expired. Request a new verification email.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Mark as verified
        email_verification.verified = True
        email_verification.verified_at = timezone.now()
        email_verification.save()

        # Update profile
        profile = email_verification.user.profile
        profile.emergency_verified = True
        profile.save()

        # Log the action
        AuditLog.objects.create(
            user=email_verification.user,
            action='profile_update',
            description='Email verified',
            ip_address=self.get_client_ip()
        )

        return Response({
            'message': 'Email verified successfully! Your account is now fully verified.',
            'user': UserDetailSerializer(email_verification.user).data
        })

    def get_client_ip(self):
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip


class GoogleOAuthCallbackView(APIView):
    """Handle Google OAuth callback"""
    permission_classes = [permissions.AllowAny]
    throttle_classes = [GoogleOAuthThrottle]

    def post(self, request):
        """
        Expected payload:
        {
            "id_token": "...",  # JWT from Google
            "code": "..."        # Authorization code
        }
        """
        from django.conf import settings
        import requests

        id_token = request.data.get('id_token')
        code = request.data.get('code')

        if not id_token and not code:
            return Response(
                {'detail': 'id_token or code is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Verify token with Google
            google_id, email, name = self._verify_google_token(id_token or code)
        except Exception as e:
            logger.error(f"Google OAuth verification failed: {str(e)}")
            return Response(
                {'detail': 'Google authentication failed.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': email,
                'first_name': name.split()[0] if name else 'User',
                'last_name': ' '.join(name.split()[1:]) if name and len(name.split()) > 1 else '',
            }
        )

        # Create or update Google OAuth record
        google_oauth, _ = GoogleOAuthToken.objects.get_or_create(
            user=user,
            defaults={
                'google_id': google_id,
                'access_token': id_token or code,
                'token_expires_at': timezone.now() + timedelta(days=365)
            }
        )

        # Ensure profile exists and mark as verified
        profile, _ = UserProfile.objects.get_or_create(user=user)
        profile.emergency_verified = True
        profile.save()

        # Create tokens
        refresh = RefreshToken.for_user(user)

        # Log the login
        LoginHistory.objects.create(
            user=user,
            ip_address=self.get_client_ip(),
            user_agent=request.META.get('HTTP_USER_AGENT', '')[:500],
            success=True
        )

        # Log audit
        AuditLog.objects.create(
            user=user,
            action='login',
            description='Logged in via Google OAuth',
            ip_address=self.get_client_ip()
        )

        return Response({
            'user': UserDetailSerializer(user).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'created': created,
            'message': 'Welcome!' if created else f'Welcome back, {user.first_name or user.username}!'
        }, status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED)

    def _verify_google_token(self, token):
        """Verify Google JWT token (simplified - use google-auth in production)"""
        import json
        from urllib.request import urlopen

        try:
            # Get Google's public keys
            url = "https://www.googleapis.com/oauth2/v1/userinfo?access_token=" + token
            response = urlopen(url)
            data = json.loads(response.read())

            google_id = data.get('id')
            email = data.get('email')
            name = data.get('name', data.get('given_name', 'User'))

            if not google_id or not email:
                raise ValueError("Invalid Google token")

            return google_id, email, name
        except Exception as e:
            raise ValueError(f"Token verification failed: {str(e)}")

    def get_client_ip(self):
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip


class LoginHistoryListView(generics.ListAPIView):
    """Get user's login history"""
    serializer_class = LoginHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return LoginHistory.objects.filter(user=self.request.user).order_by('-created_at')[:50]


class AuditLogListView(generics.ListAPIView):
    """Get user's audit logs"""
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return AuditLog.objects.filter(user=self.request.user).order_by('-timestamp')[:100]


class SecuritySettingsView(APIView):
    """Manage security settings including 2FA"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get security settings"""
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        return Response({
            'two_factor_enabled': profile.two_factor_enabled,
            'two_factor_method': profile.two_factor_method,
            'email_notifications': profile.email_notifications,
            'sms_notifications': profile.sms_notifications,
            'push_notifications': profile.push_notifications,
        })

    def post(self, request):
        """Update security settings"""
        profile, _ = UserProfile.objects.get_or_create(user=request.user)

        # Update settings
        if 'two_factor_enabled' in request.data:
            profile.two_factor_enabled = request.data.get('two_factor_enabled', False)
        if 'two_factor_method' in request.data:
            profile.two_factor_method = request.data.get('two_factor_method', '')
        if 'email_notifications' in request.data:
            profile.email_notifications = request.data.get('email_notifications', True)
        if 'sms_notifications' in request.data:
            profile.sms_notifications = request.data.get('sms_notifications', True)
        if 'push_notifications' in request.data:
            profile.push_notifications = request.data.get('push_notifications', True)

        profile.save()

        # Log the update
        AuditLog.objects.create(
            user=request.user,
            action='profile_update',
            description='Updated security settings',
            ip_address=self.get_client_ip()
        )

        return Response({
            'message': 'Security settings updated.',
            'settings': {
                'two_factor_enabled': profile.two_factor_enabled,
                'two_factor_method': profile.two_factor_method,
                'email_notifications': profile.email_notifications,
                'sms_notifications': profile.sms_notifications,
                'push_notifications': profile.push_notifications,
            }
        })

    def get_client_ip(self):
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip
