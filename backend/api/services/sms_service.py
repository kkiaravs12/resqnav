"""
SMS Service for sending emergency notifications
Supports MSG91 (India) and Twilio (International)
"""

import requests
from django.conf import settings
from decouple import config
import logging

logger = logging.getLogger(__name__)


class SMSService:
    """Service for sending SMS notifications"""
    
    @staticmethod
    def send_emergency_alert(phone_number: str, message: str, user_name: str = None, location: str = None) -> dict:
        """
        Send emergency alert SMS to a phone number
        
        Args:
            phone_number: Recipient phone number (with country code)
            message: Alert message
            user_name: Name of person in emergency
            location: Location details
            
        Returns:
            dict: Response with success status and details
        """
        # Clean phone number
        phone_number = phone_number.strip().replace(' ', '').replace('-', '')
        
        # Build message
        alert_message = f"🚨 EMERGENCY ALERT - ResQNav\n\n"
        
        if user_name:
            alert_message += f"{user_name} needs help!\n\n"
        
        alert_message += f"{message}\n\n"
        
        if location:
            alert_message += f"📍 Location: {location}\n\n"
        
        alert_message += "This is an automated emergency alert. Please respond immediately."
        
        # Try MSG91 first (better for India)
        msg91_key = config('MSG91_AUTH_KEY', default=None)
        if msg91_key:
            return SMSService._send_via_msg91(phone_number, alert_message, msg91_key)
        
        # Fallback to Twilio
        twilio_sid = config('TWILIO_ACCOUNT_SID', default=None)
        twilio_token = config('TWILIO_AUTH_TOKEN', default=None)
        twilio_phone = config('TWILIO_PHONE_NUMBER', default=None)
        
        if twilio_sid and twilio_token and twilio_phone:
            return SMSService._send_via_twilio(phone_number, alert_message, twilio_sid, twilio_token, twilio_phone)
        
        # No SMS service configured - log only
        logger.warning(f"No SMS service configured. Would send to {phone_number}: {alert_message}")
        return {
            'success': True,
            'provider': 'mock',
            'message': 'SMS service not configured - message logged only',
            'phone': phone_number
        }
    
    @staticmethod
    def _send_via_msg91(phone_number: str, message: str, auth_key: str) -> dict:
        """Send SMS via MSG91 (India)"""
        try:
            # MSG91 API endpoint
            url = "https://api.msg91.com/api/v2/sendsms"
            
            # Remove + from phone number if present
            phone_number = phone_number.replace('+', '')
            
            # If no country code, assume India (+91)
            if not phone_number.startswith('91') and len(phone_number) == 10:
                phone_number = '91' + phone_number
            
            payload = {
                "sender": config('MSG91_SENDER_ID', default='RESQNV'),
                "route": config('MSG91_ROUTE', default='4'),
                "country": "91",
                "sms": [
                    {
                        "message": message,
                        "to": [phone_number]
                    }
                ]
            }
            
            headers = {
                "authkey": auth_key,
                "content-type": "application/json"
            }
            
            # Send SMS with verify=False for development (proper SSL in production)
            response = requests.post(
                url, 
                json=payload, 
                headers=headers, 
                timeout=10,
                verify=True  # Set to False only if SSL issues persist in production
            )
            
            # Check if request was successful
            if response.status_code == 200:
                logger.info(f"SMS sent successfully via MSG91 to {phone_number}")
                return {
                    'success': True,
                    'provider': 'msg91',
                    'message': 'SMS sent successfully',
                    'phone': phone_number,
                    'response': response.json() if response.text else {}
                }
            else:
                logger.error(f"MSG91 returned status {response.status_code}: {response.text}")
                return {
                    'success': False,
                    'provider': 'msg91',
                    'error': f'HTTP {response.status_code}',
                    'phone': phone_number
                }
            
        except requests.exceptions.SSLError as e:
            # SSL certificate error - retry with verification disabled (dev only)
            logger.warning(f"MSG91 SSL error: {str(e)}. Retrying with verification disabled...")
            try:
                response = requests.post(
                    url, 
                    json=payload, 
                    headers=headers, 
                    timeout=10,
                    verify=False  # Bypass SSL verification as fallback
                )
                if response.status_code == 200:
                    logger.info(f"SMS sent via MSG91 (SSL bypass) to {phone_number}")
                    return {
                        'success': True,
                        'provider': 'msg91',
                        'message': 'SMS sent (SSL bypass)',
                        'phone': phone_number,
                        'response': response.json() if response.text else {}
                    }
            except Exception as retry_error:
                logger.error(f"MSG91 retry failed: {str(retry_error)}")
            
            return {
                'success': False,
                'provider': 'msg91',
                'error': f'SSL Error: {str(e)}',
                'phone': phone_number
            }
            
        except requests.exceptions.RequestException as e:
            logger.error(f"MSG91 SMS failed for {phone_number}: {str(e)}")
            return {
                'success': False,
                'provider': 'msg91',
                'error': str(e),
                'phone': phone_number
            }
        except Exception as e:
            logger.error(f"Unexpected error in MSG91 SMS: {str(e)}")
            return {
                'success': False,
                'provider': 'msg91',
                'error': f'Unexpected error: {str(e)}',
                'phone': phone_number
            }
    
    @staticmethod
    def _send_via_twilio(phone_number: str, message: str, account_sid: str, auth_token: str, from_phone: str) -> dict:
        """Send SMS via Twilio (International)"""
        try:
            from twilio.rest import Client
            
            # Ensure phone number has country code
            if not phone_number.startswith('+'):
                # Assume India if no country code
                if len(phone_number) == 10:
                    phone_number = '+91' + phone_number
                else:
                    phone_number = '+' + phone_number
            
            client = Client(account_sid, auth_token)
            
            twilio_message = client.messages.create(
                body=message,
                from_=from_phone,
                to=phone_number
            )
            
            logger.info(f"SMS sent successfully via Twilio to {phone_number}")
            return {
                'success': True,
                'provider': 'twilio',
                'message': 'SMS sent successfully',
                'phone': phone_number,
                'sid': twilio_message.sid
            }
            
        except Exception as e:
            logger.error(f"Twilio SMS failed for {phone_number}: {str(e)}")
            return {
                'success': False,
                'provider': 'twilio',
                'error': str(e),
                'phone': phone_number
            }


class EmailService:
    """Service for sending email notifications"""
    
    @staticmethod
    def send_emergency_alert(email: str, message: str, user_name: str = None, location: str = None) -> dict:
        """
        Send emergency alert email
        
        Args:
            email: Recipient email address
            message: Alert message
            user_name: Name of person in emergency
            location: Location details
            
        Returns:
            dict: Response with success status
        """
        try:
            from django.core.mail import send_mail
            from django.template.loader import render_to_string
            
            subject = f"🚨 EMERGENCY ALERT - {user_name or 'ResQNav User'} needs help!"
            
            # Build HTML email
            html_message = f"""
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <div style="background: linear-gradient(135deg, #dc2626 0%, #991b1b 100%); padding: 20px; text-align: center;">
                    <h1 style="color: white; margin: 0;">🚨 EMERGENCY ALERT</h1>
                </div>
                <div style="padding: 30px; background: #f9fafb;">
                    <h2 style="color: #1f2937;">Emergency Assistance Needed</h2>
                    {f'<p style="font-size: 16px;"><strong>{user_name}</strong> has triggered an emergency alert and needs immediate help.</p>' if user_name else ''}
                    <div style="background: white; padding: 20px; border-left: 4px solid #dc2626; margin: 20px 0;">
                        <p style="margin: 0; color: #374151;">{message}</p>
                    </div>
                    {f'<p><strong>📍 Location:</strong> {location}</p>' if location else ''}
                    <p style="color: #6b7280; font-size: 14px; margin-top: 30px;">
                        This is an automated emergency alert from ResQNav. Please respond immediately.
                    </p>
                </div>
            </body>
            </html>
            """
            
            send_mail(
                subject=subject,
                message=message,  # Plain text fallback
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                html_message=html_message,
                fail_silently=False,
            )
            
            logger.info(f"Email sent successfully to {email}")
            return {
                'success': True,
                'provider': 'email',
                'message': 'Email sent successfully',
                'email': email
            }
            
        except Exception as e:
            logger.error(f"Email sending failed for {email}: {str(e)}")
            return {
                'success': False,
                'provider': 'email',
                'error': str(e),
                'email': email
            }

    @staticmethod
    def send_password_reset(email: str, uid: str, token: str) -> dict:
        logger.info("Password reset requested for %s uid=%s token=%s", email, uid, token)
        try:
            from django.core.mail import send_mail

            send_mail(
                subject="ResQNav password reset",
                message=(
                    "Use these values in the ResQNav reset form:\n"
                    f"Reset ID: {uid}\n"
                    f"Reset code: {token}\n"
                ),
                from_email=getattr(settings, "DEFAULT_FROM_EMAIL", "noreply@resqnav.app"),
                recipient_list=[email],
                fail_silently=True,
            )
            return {"success": True, "email": email}
        except Exception as exc:
            logger.warning("Password reset email skipped: %s", exc)
            return {"success": False, "error": str(exc)}


    @staticmethod
    def send_email_verification(email: str, token: str, username: str = None) -> dict:
        """Send email verification token"""
        logger.info("Sending email verification to %s", email)
        try:
            from django.core.mail import send_mail
            from django.conf import settings as django_settings

            frontend_url = django_settings.FRONTEND_URL
            verify_link = f"{frontend_url}/verify-email?token={token}"

            html_message = f"""
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <div style="background: linear-gradient(135deg, #0ea5e9 0%, #06b6d4 100%); padding: 20px; text-align: center;">
                    <h1 style="color: white; margin: 0;">✓ Verify Your Email</h1>
                </div>
                <div style="padding: 30px; background: #f9fafb;">
                    <p>Hi {username or 'there'},</p>
                    <p>Thanks for signing up with ResQNav! To complete your account setup and enable all emergency features, please verify your email address.</p>
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{verify_link}" style="background: #0ea5e9; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Verify Email Address</a>
                    </div>
                    <p style="color: #6b7280; font-size: 12px;">Or copy this link: <br/><code style="background: #f3f4f6; padding: 5px;">{verify_link}</code></p>
                    <p style="color: #6b7280; font-size: 12px;">This link expires in 24 hours.</p>
                </div>
            </body>
            </html>
            """

            send_mail(
                subject="Verify Your ResQNav Email Address",
                message=f"Verify your email by clicking: {verify_link}",
                from_email=django_settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                html_message=html_message,
                fail_silently=False,
            )
            return {"success": True, "email": email}
        except Exception as exc:
            logger.error("Email verification send failed: %s", exc)
            return {"success": False, "error": str(exc)}

    @staticmethod
    def send_password_changed(email: str, username: str = None) -> dict:
        """Send password changed confirmation email"""
        logger.info("Sending password changed confirmation to %s", email)
        try:
            from django.core.mail import send_mail
            from django.conf import settings as django_settings

            html_message = f"""
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 20px; text-align: center;">
                    <h1 style="color: white; margin: 0;">✓ Password Updated</h1>
                </div>
                <div style="padding: 30px; background: #f9fafb;">
                    <p>Hi {username or 'there'},</p>
                    <p>Your password has been successfully changed. If you did not make this change, please contact support immediately.</p>
                    <p style="color: #6b7280; font-size: 12px;">Your account security is important to us. If you notice any suspicious activity, please log in and review your security settings or contact our support team.</p>
                </div>
            </body>
            </html>
            """

            send_mail(
                subject="Your ResQNav Password Has Been Changed",
                message="Your password has been changed successfully.",
                from_email=django_settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                html_message=html_message,
                fail_silently=False,
            )
            return {"success": True, "email": email}
        except Exception as exc:
            logger.error("Password changed email send failed: %s", exc)
            return {"success": False, "error": str(exc)}


    @staticmethod
    def send_otp(phone_number: str, code: str) -> dict:
        """Send OTP code via SMS"""
        logger.info(f"Sending OTP to {phone_number}")
        try:
            message = f"Your ResQNav verification code is: {code}\n\nDo not share this code with anyone."
            return SMSService.send_emergency_alert(
                phone_number=phone_number,
                message=message,
                user_name=None,
                location=None
            )
        except Exception as e:
            logger.error(f"OTP SMS failed: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'phone': phone_number
            }


    @staticmethod
    def send_otp(email: str, code: str) -> dict:
        """Send OTP code via email"""
        logger.info(f"Sending OTP email to {email}")
        try:
            from django.core.mail import send_mail
            from django.conf import settings as django_settings

            html_message = f"""
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <div style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); padding: 20px; text-align: center;">
                    <h1 style="color: white; margin: 0;">🔐 Verification Code</h1>
                </div>
                <div style="padding: 30px; background: #f9fafb;">
                    <p>Your ResQNav verification code is:</p>
                    <div style="background: white; padding: 20px; text-align: center; border: 2px solid #f59e0b; margin: 20px 0; border-radius: 5px;">
                        <h2 style="margin: 0; font-family: monospace; font-size: 32px; letter-spacing: 5px; color: #f59e0b;">{code}</h2>
                    </div>
                    <p style="color: #6b7280; font-size: 14px;">
                        <strong>⚠️ Do not share this code with anyone.</strong> ResQNav staff will never ask for this code.
                    </p>
                    <p style="color: #6b7280; font-size: 12px;">
                        This code expires in 10 minutes.
                    </p>
                </div>
            </body>
            </html>
            """

            send_mail(
                subject=f"Your ResQNav Verification Code: {code}",
                message=f"Your verification code is: {code}",
                from_email=django_settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                html_message=html_message,
                fail_silently=False,
            )
            return {"success": True, "email": email}
        except Exception as exc:
            logger.error(f"OTP email send failed: {str(exc)}")
            return {"success": False, "error": str(exc), "email": email}
