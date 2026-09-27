from django.contrib.auth.models import User
from rest_framework import serializers

from .models import (
    EmergencyAlert, 
    EmergencyContact, 
    EmergencyNotification, 
    EmergencyService, 
    SearchHistory
)
from .models_auth import (
    UserProfile,
    PasswordResetToken,
    EmailVerificationToken,
    GoogleOAuthToken,
    LoginHistory,
    AuditLog,
)


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "full_name",
        ]

    def get_full_name(self, obj):
        full = f"{obj.first_name} {obj.last_name}".strip()
        return full if full else obj.username


class RegisterSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(
        write_only=True,
        max_length=150,
    )

    password = serializers.CharField(
        write_only=True,
        min_length=6,
    )

    class Meta:
        model = User
        fields = [
            "full_name",
            "email",
            "password",
        ]

    def validate_email(self, value):
        email = value.strip().lower()

        if User.objects.filter(
            email__iexact=email
        ).exists():
            raise serializers.ValidationError(
                "An account with this email already exists."
            )

        return email

    def create(self, validated_data):
        full_name = validated_data.pop(
            "full_name"
        ).strip()

        email = validated_data["email"]

        name_parts = full_name.split(
            maxsplit=1
        )

        first_name = name_parts[0]
        last_name = (
            name_parts[1]
            if len(name_parts) > 1
            else ""
        )

        user = User.objects.create_user(
            username=email,
            email=email,
            password=validated_data["password"],
            first_name=first_name,
            last_name=last_name,
        )

        return user
    
class EmergencyServiceSerializer(
    serializers.ModelSerializer
):
    distance_km = serializers.FloatField(read_only=True, required=False, allow_null=True)

    class Meta:
        model = EmergencyService
        fields = [
            "id",
            "name",
            "category",
            "address",
            "phone",
            "latitude",
            "longitude",
            "status",
            "is_active",
            "distance_km",
            "created_at",
            "updated_at",
        ]


class SearchHistorySerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = SearchHistory
        fields = [
            "id",
            "search_type",
            "query",
            "destination_name",
            "destination_address",
            "category",
            "latitude",
            "longitude",
            "distance_meters",
            "duration_seconds",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
        ]


class EmergencyContactSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = EmergencyContact
        fields = [
            "id",
            "name",
            "relationship",
            "phone",
            "is_primary",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
        ]


class EmergencyAlertSerializer(serializers.ModelSerializer):
    # Auto-generated from model fields
    class Meta:
        model = EmergencyAlert
        fields = [
            "id",
            "alert_type",
            "status",
            "message",
            "latitude",
            "longitude", 
            "address",
            "created_at",
            "resolved_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
        ]


class EmergencyNotificationSerializer(serializers.ModelSerializer):
    emergency_contact_name = serializers.CharField(source='emergency_contact.name', read_only=True)
    
    class Meta:
        model = EmergencyNotification
        fields = [
            "id",
            "emergency_alert",
            "emergency_contact",
            "emergency_contact_name",
            "notification_type",
            "status",
            "message",
            "recipient",
            "sent_at",
            "delivered_at",
            "error_message",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
            "emergency_contact_name",
        ]


# ─── Auth & Profile Serializers ─────────────────────────────────

class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)

    class Meta:
        model = UserProfile
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "phone_number",
            "avatar",
            "bio",
            "location",
            "blood_group",
            "medical_conditions",
            "emergency_verified",
            "sms_notifications",
            "email_notifications",
            "push_notifications",
            "two_factor_enabled",
            "two_factor_method",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "emergency_verified",
            "created_at",
            "updated_at",
        ]


class UserDetailSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "full_name",
            "profile",
            "date_joined",
        ]
        read_only_fields = [
            "id",
            "username",
            "date_joined",
        ]

    def get_full_name(self, obj):
        full = f"{obj.first_name} {obj.last_name}".strip()
        return full if full else obj.username


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for password change endpoint"""
    old_password = serializers.CharField(write_only=True, required=True)
    new_password = serializers.CharField(write_only=True, required=True, min_length=6)
    confirm_password = serializers.CharField(write_only=True, required=True, min_length=6)

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError({
                'confirm_password': 'Passwords do not match.'
            })
        if data['old_password'] == data['new_password']:
            raise serializers.ValidationError({
                'new_password': 'New password must be different from old password.'
            })
        return data


class EmailVerificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailVerificationToken
        fields = [
            "id",
            "token",
            "created_at",
            "expires_at",
            "verified",
            "verified_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
            "verified_at",
        ]


class VerifyEmailSerializer(serializers.Serializer):
    """Serializer for email verification"""
    token = serializers.CharField(required=True)

    def validate_token(self, value):
        try:
            EmailVerificationToken.objects.get(token=value)
        except EmailVerificationToken.DoesNotExist:
            raise serializers.ValidationError("Invalid or expired verification token.")
        return value


class GoogleOAuthSerializer(serializers.ModelSerializer):
    class Meta:
        model = GoogleOAuthToken
        fields = [
            "id",
            "google_id",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "google_id",
            "access_token",
            "refresh_token",
            "token_expires_at",
            "created_at",
            "updated_at",
        ]


class LoginHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = LoginHistory
        fields = [
            "id",
            "ip_address",
            "user_agent",
            "device_name",
            "location",
            "success",
            "reason_failed",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
        ]


class AuditLogSerializer(serializers.ModelSerializer):
    action_display = serializers.CharField(source='get_action_display', read_only=True)

    class Meta:
        model = AuditLog
        fields = [
            "id",
            "action",
            "action_display",
            "description",
            "ip_address",
            "timestamp",
        ]
        read_only_fields = [
            "id",
            "action_display",
            "timestamp",
        ]


# ─── 2FA Serializers ───────────────────────────────────────────

from .models_2fa import TwoFactorMethod, TwoFactorOTP, TwoFactorBackupCode


class TwoFactorMethodSerializer(serializers.ModelSerializer):
    class Meta:
        model = TwoFactorMethod
        fields = [
            "id",
            "method_type",
            "enabled",
            "phone_number",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
            "updated_at",
        ]


class TwoFactorOTPSerializer(serializers.ModelSerializer):
    class Meta:
        model = TwoFactorOTP
        fields = [
            "id",
            "code",
            "method_type",
            "recipient",
            "status",
            "attempts",
            "max_attempts",
            "created_at",
            "expires_at",
            "verified_at",
        ]
        read_only_fields = [
            "id",
            "code",
            "status",
            "attempts",
            "created_at",
            "verified_at",
        ]


class RequestOTPSerializer(serializers.Serializer):
    """Request OTP for 2FA verification"""
    method_type = serializers.ChoiceField(choices=['sms', 'email'])
    phone_number = serializers.CharField(required=False, allow_blank=True)


class VerifyOTPSerializer(serializers.Serializer):
    """Verify OTP code"""
    code = serializers.CharField(max_length=6, min_length=6)


class SetupTwoFactorSerializer(serializers.Serializer):
    """Setup 2FA for user"""
    method_type = serializers.ChoiceField(choices=['sms', 'email', 'totp'])
    phone_number = serializers.CharField(required=False, allow_blank=True)
    otp_code = serializers.CharField(required=False, allow_blank=True)


class TwoFactorBackupCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = TwoFactorBackupCode
        fields = [
            "id",
            "code",
            "used",
            "used_at",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "used",
            "used_at",
            "created_at",
        ]
