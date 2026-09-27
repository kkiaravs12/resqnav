from django.urls import path

from .views import (
    EmergencyAlertListView,
    EmergencyContactDetailView,
    EmergencyContactListCreateView,
    EmergencyNotificationListView,
    EmergencyServiceDetailView,
    EmergencyServiceListView,
    ForgotPasswordView,
    ProfileView,
    RegisterView,
    ResetPasswordView,
    ResolveEmergencyAlertView,
    SearchHistoryDetailView,
    SearchHistoryListCreateView,
    TriggerEmergencyAlertView,
)

from .views_auth import (
    UserDetailView,
    UserProfileView,
    ChangePasswordView,
    SendEmailVerificationView,
    VerifyEmailView,
    GoogleOAuthCallbackView,
    LoginHistoryListView,
    AuditLogListView,
    SecuritySettingsView,
)

from .views_2fa import (
    RequestOTPView,
    VerifyOTPView,
    SetupTwoFactorView,
    BackupCodesView,
    VerifyBackupCodeView,
)

from .views_auth_v2 import (
    TokenObtainView,
    TokenRefreshView,
    LogoutView,
    DeviceTokenView,
    SessionHistoryView,
)

urlpatterns = [
    # ─── JWT Token Management ─────────────────────
    path(
        "auth/token/",
        TokenObtainView.as_view(),
        name="token-obtain",
    ),
    path(
        "auth/token/refresh/",
        TokenRefreshView.as_view(),
        name="token-refresh",
    ),
    path(
        "auth/logout/",
        LogoutView.as_view(),
        name="logout",
    ),
    path(
        "auth/device-token/",
        DeviceTokenView.as_view(),
        name="device-token",
    ),
    path(
        "auth/sessions/",
        SessionHistoryView.as_view(),
        name="session-history",
    ),

    # ─── Auth ─────────────────────────────────────
    path(
        "auth/register/",
        RegisterView.as_view(),
        name="register",
    ),
    path(
        "auth/forgot-password/",
        ForgotPasswordView.as_view(),
        name="forgot-password",
    ),
    path(
        "auth/reset-password/",
        ResetPasswordView.as_view(),
        name="reset-password",
    ),
    path(
        "auth/change-password/",
        ChangePasswordView.as_view(),
        name="change-password",
    ),
    path(
        "auth/verify-email/send/",
        SendEmailVerificationView.as_view(),
        name="send-email-verification",
    ),
    path(
        "auth/verify-email/",
        VerifyEmailView.as_view(),
        name="verify-email",
    ),
    path(
        "auth/google/callback/",
        GoogleOAuthCallbackView.as_view(),
        name="google-oauth-callback",
    ),

    # ─── User Profile ─────────────────────────────
    path(
        "user/",
        UserDetailView.as_view(),
        name="user-detail",
    ),
    path(
        "profile/",
        ProfileView.as_view(),
        name="profile",
    ),
    path(
        "profile/settings/",
        UserProfileView.as_view(),
        name="profile-settings",
    ),

    # ─── Security ─────────────────────────────────────
    path(
        "security/settings/",
        SecuritySettingsView.as_view(),
        name="security-settings",
    ),
    path(
        "security/login-history/",
        LoginHistoryListView.as_view(),
        name="login-history",
    ),
    path(
        "security/audit-logs/",
        AuditLogListView.as_view(),
        name="audit-logs",
    ),
    path(
        "security/2fa/request-otp/",
        RequestOTPView.as_view(),
        name="request-otp",
    ),
    path(
        "security/2fa/verify-otp/",
        VerifyOTPView.as_view(),
        name="verify-otp",
    ),
    path(
        "security/2fa/setup/",
        SetupTwoFactorView.as_view(),
        name="setup-two-factor",
    ),
    path(
        "security/2fa/backup-codes/",
        BackupCodesView.as_view(),
        name="backup-codes",
    ),
    path(
        "security/2fa/backup-code/verify/",
        VerifyBackupCodeView.as_view(),
        name="verify-backup-code",
    ),

    # ─── Emergency Services ────────────────────────
    path(
        "emergency-services/",
        EmergencyServiceListView.as_view(),
        name="emergency-services",
    ),
    path(
        "emergency-services/<int:pk>/",
        EmergencyServiceDetailView.as_view(),
        name="emergency-service-detail",
    ),

    # ─── Search History ───────────────────────────
    path(
        "history/",
        SearchHistoryListCreateView.as_view(),
        name="history",
    ),
    path(
        "history/<int:pk>/",
        SearchHistoryDetailView.as_view(),
        name="history-detail",
    ),

    # ─── Emergency Contacts ───────────────────────
    path(
        "emergency-contacts/",
        EmergencyContactListCreateView.as_view(),
        name="emergency-contacts",
    ),
    path(
        "emergency-contacts/<int:pk>/",
        EmergencyContactDetailView.as_view(),
        name="emergency-contact-detail",
    ),

    # ─── Emergency Alerts ─────────────────────────
    path(
        "emergency-alert/",
        TriggerEmergencyAlertView.as_view(),
        name="trigger-emergency-alert",
    ),
    path(
        "emergency-alerts/",
        EmergencyAlertListView.as_view(),
        name="emergency-alerts",
    ),
    path(
        "emergency-alerts/<int:alert_id>/resolve/",
        ResolveEmergencyAlertView.as_view(),
        name="resolve-emergency-alert",
    ),

    # ─── Notifications ────────────────────────────
    path(
        "emergency-notifications/",
        EmergencyNotificationListView.as_view(),
        name="emergency-notifications",
    ),
]