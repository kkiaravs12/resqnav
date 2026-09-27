import math
from datetime import timedelta
import math

from django.contrib.auth.models import User
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.db.models import Q
from django.utils import timezone
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
import django_filters
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import (
    EmergencyAlert, 
    EmergencyContact, 
    EmergencyNotification, 
    EmergencyService, 
    SearchHistory
)
from .models_auth import UserProfile, EmailVerificationToken
from .serializers import (
    EmergencyAlertSerializer,
    EmergencyContactSerializer,
    EmergencyNotificationSerializer,
    EmergencyServiceSerializer,
    RegisterSerializer,
    SearchHistorySerializer,
    UserSerializer,
)
from .services import SMSService, EmailService
from .throttling import EmergencyAlertThrottle


def calculate_haversine(lat1, lon1, lat2, lon2):
    """
    Calculate the great-circle distance between two points
    on the Earth (specified in decimal degrees).
    Returns distance in kilometers.
    """
    try:
        r = 6371.0  # Earth radius in kilometers
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(math.radians(lat1))
            * math.cos(math.radians(lat2))
            * math.sin(dlon / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return round(r * c, 2)
    except Exception:
        return None


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Create user profile
        profile, _ = UserProfile.objects.get_or_create(user=user)

        # Create email verification token
        from .models_auth import AuditLog
        email_verification, _ = EmailVerificationToken.objects.get_or_create(
            user=user,
            defaults={
                'expires_at': timezone.now() + timedelta(hours=24)
            }
        )

        # Send verification email
        EmailService.send_email_verification(
            user.email,
            email_verification.token,
            user.first_name or user.username
        )

        # Log the signup
        AuditLog.objects.create(
            user=user,
            action='login',
            description='New account created',
            ip_address=self.get_client_ip(request)
        )

        refresh = RefreshToken.for_user(user)

        return Response(
            {
                "user": UserSerializer(user).data,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "message": "Account created! Please verify your email to enable all features.",
                "requires_email_verification": True,
            },
            status=status.HTTP_201_CREATED,
        )

    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class ProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        user = request.user
        full_name = request.data.get("full_name")
        if full_name:
            parts = full_name.strip().split(maxsplit=1)
            user.first_name = parts[0]
            user.last_name = parts[1] if len(parts) > 1 else ""
        email = request.data.get("email")
        if email:
            email = email.strip().lower()
            if email != user.email:
                from django.contrib.auth.models import User as UserModel
                if UserModel.objects.filter(email__iexact=email).exclude(pk=user.pk).exists():
                    return Response(
                        {"detail": "An account with this email already exists."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                user.email = email
                user.username = email
        user.save()
        return Response(UserSerializer(user).data)


class EmergencyServiceListView(generics.ListAPIView):
    serializer_class = EmergencyServiceSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [
        django_filters.rest_framework.DjangoFilterBackend,
        SearchFilter,
        OrderingFilter
    ]
    search_fields = ['name', 'address', 'phone', 'category']
    ordering_fields = ['name', 'category', 'status', 'created_at']
    ordering = ['name']

    def get_queryset(self):
        queryset = EmergencyService.objects.filter(is_active=True)

        category = self.request.query_params.get("category")
        search = self.request.query_params.get("search")

        if category:
            queryset = queryset.filter(category__iexact=category)

        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) | Q(address__icontains=search)
            )

        return queryset

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())

        lat_param = request.query_params.get("latitude") or request.query_params.get("lat")
        lng_param = request.query_params.get("longitude") or request.query_params.get("lng")
        radius_param = request.query_params.get("radius")

        if lat_param and lng_param:
            try:
                user_lat = float(lat_param)
                user_lng = float(lng_param)
                radius_km = float(radius_param) if radius_param else None

                results = []
                for service in queryset:
                    dist = calculate_haversine(
                        user_lat,
                        user_lng,
                        float(service.latitude),
                        float(service.longitude),
                    )
                    service.distance_km = dist

                    if radius_km is None or (dist is not None and dist <= radius_km):
                        results.append(service)

                # Sort nearest first
                results.sort(key=lambda s: s.distance_km if s.distance_km is not None else 999999)

                serializer = self.get_serializer(results, many=True)
                return Response(serializer.data)
            except (ValueError, TypeError):
                pass

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class EmergencyServiceDetailView(generics.RetrieveAPIView):
    queryset = EmergencyService.objects.filter(is_active=True)
    serializer_class = EmergencyServiceSerializer
    permission_classes = [permissions.AllowAny]


class SearchHistoryListCreateView(generics.ListCreateAPIView):
    serializer_class = SearchHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SearchHistory.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def delete(self, request, *args, **kwargs):
        deleted_count, _ = SearchHistory.objects.filter(user=request.user).delete()
        return Response(
            {"message": f"Deleted {deleted_count} history records."},
            status=status.HTTP_200_OK,
        )


class SearchHistoryDetailView(generics.RetrieveDestroyAPIView):
    serializer_class = SearchHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SearchHistory.objects.filter(user=self.request.user)


class EmergencyContactListCreateView(generics.ListCreateAPIView):
    serializer_class = EmergencyContactSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return EmergencyContact.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        if serializer.validated_data.get("is_primary"):
            EmergencyContact.objects.filter(
                user=self.request.user, is_primary=True
            ).update(is_primary=False)
        serializer.save(user=self.request.user)


class EmergencyContactDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = EmergencyContactSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return EmergencyContact.objects.filter(user=self.request.user)

    def perform_update(self, serializer):
        if serializer.validated_data.get("is_primary"):
            EmergencyContact.objects.filter(
                user=self.request.user, is_primary=True
            ).exclude(pk=self.get_object().pk).update(is_primary=False)
        serializer.save()


class TriggerEmergencyAlertView(APIView):
    """Trigger an emergency alert and notify all emergency contacts via SMS/Email"""
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [EmergencyAlertThrottle]

    def post(self, request):
        user = request.user
        data = request.data
        
        import logging
        logger = logging.getLogger('api')
        logger.info(f"SOS Request data: {data}")
        
        # Create emergency alert - latitude/longitude are optional
        alert_data = {
            'alert_type': data.get('alert_type', 'sos'),
            'message': data.get('message', 'Emergency alert triggered'),
            'latitude': data.get('latitude') or None,
            'longitude': data.get('longitude') or None, 
            'address': data.get('address', ''),
        }
        
        logger.info(f"SOS Alert data: {alert_data}")
        
        alert_serializer = EmergencyAlertSerializer(data=alert_data)
        if not alert_serializer.is_valid():
            logger.error(f"SOS Serializer errors: {alert_serializer.errors}")
            return Response(alert_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
        alert = alert_serializer.save(user=user)
        
        # Get user's emergency contacts
        emergency_contacts = EmergencyContact.objects.filter(user=user)
        
        if not emergency_contacts.exists():
            return Response({
                'alert': EmergencyAlertSerializer(alert).data,
                'message': 'Emergency alert created, but no emergency contacts found to notify.'
            })
        
        # Prepare alert details
        user_name = user.get_full_name() or user.username
        location_text = alert.address or f"Lat: {alert.latitude}, Lng: {alert.longitude}" if alert.latitude and alert.longitude else "Location unavailable"
        
        # Google Maps link if coordinates available
        maps_link = ""
        if alert.latitude and alert.longitude:
            maps_link = f"https://www.google.com/maps?q={alert.latitude},{alert.longitude}"
            location_text += f"\n🗺️ Track: {maps_link}"
        
        # Send notifications to each contact
        notifications_created = []
        notifications_sent = 0
        notifications_failed = 0
        
        for contact in emergency_contacts:
            # Send SMS notification
            sms_notification = EmergencyNotification.objects.create(
                emergency_alert=alert,
                emergency_contact=contact,
                notification_type='sms',
                recipient=contact.phone,
                message=f"🚨 EMERGENCY: {user_name} needs help! {alert.message}. Location: {location_text}",
                status='pending'
            )
            
            # Actually send the SMS
            sms_result = SMSService.send_emergency_alert(
                phone_number=contact.phone,
                message=alert.message,
                user_name=user_name,
                location=location_text
            )
            
            if sms_result.get('success'):
                sms_notification.status = 'sent'
                sms_notification.sent_at = timezone.now()
                notifications_sent += 1
            else:
                sms_notification.status = 'failed'
                sms_notification.error_message = sms_result.get('error', 'Unknown error')
                notifications_failed += 1
            
            sms_notification.save()
            notifications_created.append(sms_notification)
        
        response_message = f'Emergency alert sent! {notifications_sent} SMS sent successfully'
        if notifications_failed > 0:
            response_message += f', {notifications_failed} failed'
        
        return Response({
            'alert': EmergencyAlertSerializer(alert).data,
            'notifications_sent': notifications_sent,
            'notifications_failed': notifications_failed,
            'total_contacts': len(notifications_created),
            'message': response_message,
            'maps_link': maps_link if maps_link else None
        }, status=status.HTTP_201_CREATED)


class EmergencyAlertListView(generics.ListAPIView):
    """List user's emergency alerts"""
    serializer_class = EmergencyAlertSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return EmergencyAlert.objects.filter(user=self.request.user)


class ResolveEmergencyAlertView(APIView):
    """Resolve/cancel an active emergency alert"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, alert_id):
        try:
            alert = EmergencyAlert.objects.get(id=alert_id, user=request.user)
        except EmergencyAlert.DoesNotExist:
            return Response({'error': 'Alert not found'}, status=status.HTTP_404_NOT_FOUND)
            
        if alert.status == 'resolved':
            return Response({'message': 'Alert already resolved'})
            
        alert.status = 'resolved'
        alert.resolved_at = timezone.now()
        alert.save()
        
        return Response({
            'alert': EmergencyAlertSerializer(alert).data,
            'message': 'Emergency alert resolved.'
        })


class EmergencyNotificationListView(generics.ListAPIView):
    """List notifications for user's emergency alerts"""
    serializer_class = EmergencyNotificationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return EmergencyNotification.objects.filter(
            emergency_alert__user=self.request.user
        )


_password_reset_tokens = PasswordResetTokenGenerator()


class ForgotPasswordView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = (request.data.get("email") or "").strip().lower()
        if not email:
            return Response(
                {"detail": "Please enter your email address."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.filter(email__iexact=email).first()
        payload = {
            "message": "If an account exists for that email, a reset link has been sent.",
        }
        if user:
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            token = _password_reset_tokens.make_token(user)
            # Combine uid and token for reset URL
            reset_token = f"{uid}:{token}"
            EmailService.send_password_reset_email(user, reset_token)
            from django.conf import settings as django_settings
            if django_settings.DEBUG:
                payload["uid"] = uid
                payload["token"] = token
                payload["debug"] = True

        return Response(payload)


class ResetPasswordView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        uidb64 = (request.data.get("uid") or "").strip()
        token = (request.data.get("token") or "").strip()
        password = request.data.get("password") or ""

        if not uidb64 or not token or not password:
            return Response(
                {"detail": "Reset code, and a new password of at least 6 characters, are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(password) < 6:
            return Response(
                {"detail": "Password must be at least 6 characters."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user_id = force_str(urlsafe_base64_decode(uidb64))
            user = User.objects.get(pk=user_id)
        except Exception:
            return Response(
                {"detail": "This reset link is invalid."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not _password_reset_tokens.check_token(user, token):
            return Response(
                {"detail": "This reset link has expired. Request a new one."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.set_password(password)
        user.save()
        return Response({"message": "Password updated. You can sign in now."})