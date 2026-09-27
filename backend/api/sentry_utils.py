"""Sentry utilities for enhanced error tracking"""
import sentry_sdk
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


class SentryHelper:
    """Helper class for Sentry error tracking"""
    
    @staticmethod
    def capture_api_error(error: Exception, request=None, extra_context: dict = None):
        """Capture API-specific errors with enhanced context"""
        try:
            with sentry_sdk.configure_scope() as scope:
                # Add API-specific context
                scope.set_tag("component", "api")
                scope.set_context("error_type", {
                    "exception_type": type(error).__name__,
                    "module": error.__class__.__module__,
                })
                
                # Add request context if available
                if request:
                    scope.set_context("request_info", {
                        "method": request.method,
                        "path": request.path,
                        "user_agent": request.META.get('HTTP_USER_AGENT', ''),
                        "ip_address": SentryHelper.get_client_ip(request),
                        "user_id": request.user.id if hasattr(request, 'user') and request.user.is_authenticated else None,
                    })
                
                # Add extra context
                if extra_context:
                    scope.set_context("additional_info", extra_context)
                
                # Capture the exception
                sentry_sdk.capture_exception(error)
                logger.error(f"API Error captured by Sentry: {str(error)}")
                
        except Exception as e:
            logger.error(f"Failed to capture error in Sentry: {str(e)}")
    
    @staticmethod
    def capture_emergency_alert_error(error: Exception, alert_data: dict = None):
        """Capture emergency alert system errors"""
        try:
            with sentry_sdk.configure_scope() as scope:
                scope.set_tag("component", "emergency_alert")
                scope.set_level("error")
                
                if alert_data:
                    scope.set_context("alert_data", {
                        "alert_type": alert_data.get('alert_type'),
                        "user_id": alert_data.get('user_id'),
                        "location": alert_data.get('location', 'Unknown'),
                        "timestamp": alert_data.get('created_at'),
                    })
                
                sentry_sdk.capture_exception(error)
                logger.error(f"Emergency Alert Error: {str(error)}")
                
        except Exception as e:
            logger.error(f"Failed to capture emergency alert error: {str(e)}")
    
    @staticmethod
    def capture_sms_error(error: Exception, phone_number: str = None, provider: str = None):
        """Capture SMS delivery errors"""
        try:
            with sentry_sdk.configure_scope() as scope:
                scope.set_tag("component", "sms")
                scope.set_tag("sms_provider", provider or "unknown")
                
                scope.set_context("sms_info", {
                    "phone_number": phone_number[:5] + "***" if phone_number else None,  # Mask phone number
                    "provider": provider,
                    "error_type": type(error).__name__,
                })
                
                sentry_sdk.capture_exception(error)
                logger.error(f"SMS Error ({provider}): {str(error)}")
                
        except Exception as e:
            logger.error(f"Failed to capture SMS error: {str(e)}")
    
    @staticmethod
    def capture_email_error(error: Exception, email: str = None, email_type: str = None):
        """Capture email delivery errors"""
        try:
            with sentry_sdk.configure_scope() as scope:
                scope.set_tag("component", "email")
                scope.set_tag("email_type", email_type or "unknown")
                
                scope.set_context("email_info", {
                    "email_domain": email.split('@')[1] if email and '@' in email else None,
                    "email_type": email_type,
                    "error_type": type(error).__name__,
                })
                
                sentry_sdk.capture_exception(error)
                logger.error(f"Email Error ({email_type}): {str(error)}")
                
        except Exception as e:
            logger.error(f"Failed to capture email error: {str(e)}")
    
    @staticmethod
    def capture_auth_error(error: Exception, username: str = None, auth_method: str = None):
        """Capture authentication errors"""
        try:
            with sentry_sdk.configure_scope() as scope:
                scope.set_tag("component", "authentication")
                scope.set_tag("auth_method", auth_method or "unknown")
                
                scope.set_context("auth_info", {
                    "username": username,
                    "auth_method": auth_method,
                    "error_type": type(error).__name__,
                })
                
                sentry_sdk.capture_exception(error)
                logger.warning(f"Auth Error ({auth_method}): {str(error)}")
                
        except Exception as e:
            logger.error(f"Failed to capture auth error: {str(e)}")
    
    @staticmethod
    def get_client_ip(request):
        """Get client IP address from request"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    @staticmethod
    def capture_performance_issue(operation_name: str, duration_ms: float, extra_data: dict = None):
        """Capture performance issues"""
        try:
            with sentry_sdk.configure_scope() as scope:
                scope.set_tag("component", "performance")
                scope.set_context("performance", {
                    "operation": operation_name,
                    "duration_ms": duration_ms,
                    "is_slow": duration_ms > 5000,  # Mark as slow if > 5 seconds
                    "extra_data": extra_data,
                })
                
                if duration_ms > 10000:  # Only capture if very slow (> 10 seconds)
                    sentry_sdk.capture_message(
                        f"Slow operation detected: {operation_name} took {duration_ms}ms",
                        level='warning'
                    )
                
        except Exception as e:
            logger.error(f"Failed to capture performance issue: {str(e)}")


def init_sentry_context():
    """Initialize Sentry with application-specific context"""
    if not settings.DEBUG and hasattr(settings, 'SENTRY_DSN') and settings.SENTRY_DSN:
        try:
            with sentry_sdk.configure_scope() as scope:
                scope.set_tag("application", "resqnav")
                scope.set_tag("environment", settings.ENVIRONMENT if hasattr(settings, 'ENVIRONMENT') else 'unknown')
                scope.set_context("application", {
                    "name": "ResQNav",
                    "version": "1.0.0",
                    "debug": settings.DEBUG,
                    "allowed_hosts": settings.ALLOWED_HOSTS,
                })
                
            logger.info("Sentry context initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize Sentry context: {str(e)}")


# Custom Sentry middleware
class SentryMiddleware:
    """Custom middleware for enhanced Sentry error tracking"""
    
    def __init__(self, get_response):
        self.get_response = get_response
        init_sentry_context()
    
    def __call__(self, request):
        # Add request context to Sentry scope
        with sentry_sdk.configure_scope() as scope:
            scope.set_user({
                "id": request.user.id if hasattr(request, 'user') and request.user.is_authenticated else None,
                "username": request.user.username if hasattr(request, 'user') and request.user.is_authenticated else None,
                "ip_address": SentryHelper.get_client_ip(request),
            })
            
            scope.set_tag("request.method", request.method)
            scope.set_tag("request.path", request.path)
        
        response = self.get_response(request)
        
        # Log unusual response codes
        if response.status_code >= 500:
            sentry_sdk.capture_message(
                f"Server error {response.status_code} on {request.method} {request.path}",
                level='error'
            )
        elif response.status_code >= 400:
            sentry_sdk.capture_message(
                f"Client error {response.status_code} on {request.method} {request.path}",
                level='warning'
            )
        
        return response
    
    def process_exception(self, request, exception):
        """Process exceptions with enhanced context"""
        SentryHelper.capture_api_error(exception, request)
        return None