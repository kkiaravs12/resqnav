"""
Rate limiting and throttling for ResQNav API
"""

from rest_framework.throttling import UserRateThrottle, AnonRateThrottle


class AuthThrottle(AnonRateThrottle):
    """
    Throttle for authentication endpoints.
    5 requests per minute for anonymous users (prevents brute force)
    """
    scope = 'auth'
    rate = '5/min'


class PasswordResetThrottle(AnonRateThrottle):
    """
    Throttle for password reset endpoints.
    3 requests per hour for anonymous users
    """
    scope = 'password_reset'
    rate = '3/hour'


class EmailVerificationThrottle(AnonRateThrottle):
    """
    Throttle for email verification endpoints.
    10 requests per hour for anonymous users
    """
    scope = 'email_verification'
    rate = '10/hour'


class GoogleOAuthThrottle(AnonRateThrottle):
    """
    Throttle for Google OAuth endpoints.
    20 requests per hour for anonymous users
    """
    scope = 'oauth'
    rate = '20/hour'


class GeneralUserThrottle(UserRateThrottle):
    """
    Throttle for general authenticated users.
    1000 requests per hour
    """
    scope = 'general_user'
    rate = '1000/hour'


class BurstThrottle(UserRateThrottle):
    """
    Throttle for burst operations (emergency alerts).
    100 requests per minute for authenticated users
    """
    scope = 'burst'
    rate = '100/minute'


class EmergencyAlertThrottle(UserRateThrottle):
    """
    Throttle for emergency alerts.
    10 requests per minute to prevent accidental spam
    """
    scope = 'emergency_alert'
    rate = '10/minute'
