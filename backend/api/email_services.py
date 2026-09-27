"""Email service utilities using Django SMTP"""
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
import logging

# Import Sentry utilities if available
try:
    from .sentry_utils import SentryHelper
    SENTRY_AVAILABLE = True
except ImportError:
    SENTRY_AVAILABLE = False

logger = logging.getLogger(__name__)


class EmailService:
    """Handle all email sending operations"""
    
    @staticmethod
    def send_verification_email(user, verification_code):
        """Send email verification code"""
        try:
            context = {
                'user_name': user.first_name or user.username,
                'verification_code': verification_code,
                'frontend_url': settings.FRONTEND_URL,
            }
            
            html_content = render_to_string('emails/verify_email.html', context)
            text_content = f"""
Hi {user.first_name or user.username},

Your email verification code is: {verification_code}

This code will expire in 24 hours.

Visit {settings.FRONTEND_URL}/verify-email?code={verification_code}

Best regards,
ResQNav Team
            """.strip()
            
            subject = "ResQNav - Email Verification"
            EmailService.send_email(
                subject=subject,
                body_text=text_content,
                body_html=html_content,
                to_email=user.email,
                recipient_name=user.first_name or user.username,
            )
            
            logger.info(f"Verification email sent to {user.email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send verification email to {user.email}: {str(e)}")
            
            # Capture error in Sentry
            if SENTRY_AVAILABLE:
                SentryHelper.capture_email_error(e, user.email, "verification")
            
            return False
    
    @staticmethod
    def send_password_reset_email(user, reset_token):
        """Send password reset email"""
        try:
            context = {
                'user_name': user.first_name or user.username,
                'reset_url': f"{settings.FRONTEND_URL}/reset-password?token={reset_token}",
                'reset_token': reset_token,
            }
            
            html_content = render_to_string('emails/password_reset.html', context)
            text_content = f"""
Hi {user.first_name or user.username},

We received a request to reset your password. 

Click the link below to reset your password:
{context['reset_url']}

This link will expire in 24 hours.

If you didn't request this, please ignore this email.

Best regards,
ResQNav Team
            """.strip()
            
            subject = "ResQNav - Password Reset"
            EmailService.send_email(
                subject=subject,
                body_text=text_content,
                body_html=html_content,
                to_email=user.email,
                recipient_name=user.first_name or user.username,
            )
            
            logger.info(f"Password reset email sent to {user.email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send password reset email to {user.email}: {str(e)}")
            
            # Capture error in Sentry
            if SENTRY_AVAILABLE:
                SentryHelper.capture_email_error(e, user.email, "password_reset")
            
            return False
    
    @staticmethod
    def send_emergency_alert_notification(emergency_contact, alert_details):
        """Send emergency alert notification to contact"""
        try:
            user = alert_details['user']
            location = alert_details.get('location', 'Unknown location')
            emergency_type = alert_details.get('emergency_type', 'Emergency Alert')
            
            # Try to get contact email - fallback to user's email if not available
            contact_email = getattr(emergency_contact, 'email', None) or user.email
            
            context = {
                'contact_name': emergency_contact.name,
                'user_name': user.first_name or user.username,
                'emergency_type': emergency_type,
                'location': location,
                'frontend_url': settings.FRONTEND_URL,
                'user_phone': emergency_contact.phone,
            }
            
            html_content = render_to_string('emails/emergency_alert.html', context)
            text_content = f"""
EMERGENCY ALERT

{user.first_name or user.username} has triggered an emergency alert.

Emergency Type: {emergency_type}
Location: {location}
Contact: {emergency_contact.phone}

Check the ResQNav app for more details.

{settings.FRONTEND_URL}/alerts
            """.strip()
            
            subject = f"ResQNav - Emergency Alert from {user.first_name or user.username}"
            EmailService.send_email(
                subject=subject,
                body_text=text_content,
                body_html=html_content,
                to_email=contact_email,
                recipient_name=emergency_contact.name,
            )
            
            logger.info(f"Emergency alert notification sent to {contact_email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send emergency alert email: {str(e)}")
            
            # Capture error in Sentry
            if SENTRY_AVAILABLE:
                SentryHelper.capture_email_error(e, contact_email, "emergency_alert")
            
            return False
    
    @staticmethod
    def send_email(subject, body_text, body_html, to_email, recipient_name=''):
        """Generic email sending method using Django SMTP"""
        try:
            msg = EmailMultiAlternatives(
                subject=subject,
                body=body_text,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[to_email],
            )
            msg.attach_alternative(body_html, "text/html")
            msg.send()
            logger.info(f"Email sent successfully to {to_email}")
            return True
        except Exception as e:
            logger.error(f"Email send failed: {str(e)}")
            return False


class OTPEmailService:
    """Handle OTP emails for 2FA"""
    
    @staticmethod
    def send_otp_email(user, otp_code):
        """Send OTP for 2FA verification"""
        try:
            context = {
                'user_name': user.first_name or user.username,
                'otp_code': otp_code,
                'valid_minutes': 10,
            }
            
            html_content = render_to_string('emails/otp_email.html', context)
            text_content = f"""
Hi {user.first_name or user.username},

Your ResQNav 2FA verification code is:

{otp_code}

This code is valid for 10 minutes.

Do not share this code with anyone.

Best regards,
ResQNav Team
            """.strip()
            
            subject = "ResQNav - Your Verification Code"
            return EmailService.send_email(
                subject=subject,
                body_text=text_content,
                body_html=html_content,
                to_email=user.email,
                recipient_name=user.first_name or user.username,
            )
        except Exception as e:
            logger.error(f"Failed to send OTP email to {user.email}: {str(e)}")
            
            # Capture error in Sentry
            if SENTRY_AVAILABLE:
                SentryHelper.capture_email_error(e, user.email, "otp")
            
            return False
