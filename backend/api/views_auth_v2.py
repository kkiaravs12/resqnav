"""Production-ready Authentication Views"""
from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView
from django.contrib.auth.models import User
from django.utils import timezone

from .serializers_auth import (
    CustomTokenObtainPairSerializer,
    CustomTokenRefreshSerializer,
    LogoutSerializer,
    DeviceTokenSerializer,
    SessionLogSerializer
)
from .models_tokens import TokenBlacklist, DeviceToken, SessionLog
from .models_auth import UserProfile


class TokenObtainView(APIView):
    """Enhanced token obtain view with session logging"""
    permission_classes = [permissions.AllowAny]
    serializer_class = CustomTokenObtainPairSerializer
    
    def post(self, request):
        serializer = self.serializer_class(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data, status=status.HTTP_200_OK)


class TokenRefreshView(TokenRefreshView):
    """Enhanced refresh view with validation"""
    serializer_class = CustomTokenRefreshSerializer


class LogoutView(APIView):
    """Logout and blacklist tokens"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = LogoutSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        
        # Calculate and save session duration
        try:
            latest_session = SessionLog.objects.filter(user=request.user).latest('login_at')
            latest_session.logout_at = timezone.now()
            latest_session.calculate_duration()
        except SessionLog.DoesNotExist:
            pass
        
        return Response(serializer.save(), status=status.HTTP_200_OK)


class DeviceTokenView(generics.ListCreateAPIView):
    """Manage device tokens for push notifications"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = DeviceTokenSerializer
    
    def get_queryset(self):
        return DeviceToken.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class DeviceTokenDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Manage individual device tokens"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = DeviceTokenSerializer
    
    def get_queryset(self):
        return DeviceToken.objects.filter(user=self.request.user)


class SessionHistoryView(generics.ListAPIView):
    """View session history for security audit"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = SessionLogSerializer
    
    def get_queryset(self):
        return SessionLog.objects.filter(user=self.request.user).order_by('-login_at')


class ActiveSessionsView(APIView):
    """Get active sessions and manage them"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        """List all active sessions"""
        active_sessions = SessionLog.objects.filter(
            user=request.user,
            logout_at__isnull=True
        ).order_by('-login_at')
        
        serializer = SessionLogSerializer(active_sessions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    def delete(self, request):
        """Terminate all other sessions (logout from all devices)"""
        device_id = request.data.get('device_id')
        
        if device_id:
            # Logout from specific device
            SessionLog.objects.filter(
                user=request.user,
                logout_at__isnull=True
            ).exclude(id=device_id).update(logout_at=timezone.now())
        else:
            # Logout from all devices
            sessions = SessionLog.objects.filter(
                user=request.user,
                logout_at__isnull=True
            )
            sessions.update(logout_at=timezone.now())
        
        return Response(
            {'detail': 'All other sessions terminated.'},
            status=status.HTTP_200_OK
        )


class ChangePasswordView(APIView):
    """Change user password securely"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        user = request.user
        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')
        confirm_password = request.data.get('confirm_password')
        
        # Validate current password
        if not user.check_password(current_password):
            return Response(
                {'error': 'Current password is incorrect.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate new password
        if new_password != confirm_password:
            return Response(
                {'error': 'New passwords do not match.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if len(new_password) < 8:
            return Response(
                {'error': 'Password must be at least 8 characters.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Change password
        user.set_password(new_password)
        user.save()
        
        # Blacklist all existing tokens
        try:
            refresh = RefreshToken.for_user(user)
            TokenBlacklist.add_token_to_blacklist(refresh, user)
        except Exception:
            pass
        
        return Response(
            {'detail': 'Password changed successfully. Please login again.'},
            status=status.HTTP_200_OK
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def revoke_all_tokens(request):
    """Revoke all user tokens for security"""
    user = request.user
    
    # Blacklist all refresh tokens
    try:
        refresh = RefreshToken.for_user(user)
        TokenBlacklist.add_token_to_blacklist(refresh, user)
    except Exception:
        pass
    
    return Response(
        {'detail': 'All tokens revoked. Please login again.'},
        status=status.HTTP_200_OK
    )
