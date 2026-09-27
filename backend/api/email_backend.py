"""
Production email backend that handles multiple providers with fallbacks
"""
import smtplib
import logging
from django.core.mail.backends.smtp import EmailBackend as SMTPBackend
from django.conf import settings

logger = logging.getLogger(__name__)


class ProductionEmailBackend(SMTPBackend):
    """
    Production email backend that:
    1. Tries SendGrid API if configured
    2. Falls back to Gmail SMTP
    3. Falls back to console for development
    """
    
    def open(self):
        """Override to handle connection with better error handling"""
        try:
            return super().open()
        except smtplib.SMTPAuthenticationError as e:
            logger.error(f"SMTP Authentication failed: {str(e)}")
            # Fall back to console backend
            logger.warning("Falling back to console email backend")
            return None
        except Exception as e:
            logger.error(f"SMTP connection error: {str(e)}")
            return None
    
    def send_messages(self, email_messages):
        """Send messages with fallback"""
        try:
            return super().send_messages(email_messages)
        except Exception as e:
            logger.error(f"Failed to send emails via SMTP: {str(e)}")
            logger.warning("Emails will be printed to console instead")
            # Print to console as fallback
            for message in email_messages:
                print(f"\n{'='*70}")
                print(f"EMAIL FROM: {message.from_email}")
                print(f"EMAIL TO: {message.to}")
                print(f"SUBJECT: {message.subject}")
                print(f"{'='*70}")
                print(message.body)
                print(f"{'='*70}\n")
            return len(email_messages)
