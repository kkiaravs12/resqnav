"""SMS Service - Production-ready SMS delivery via MSG91 or Twilio"""
import requests
import logging
from django.conf import settings
from decouple import config

# Import Sentry utilities if available
try:
    from .sentry_utils import SentryHelper
    SENTRY_AVAILABLE = True
except ImportError:
    SENTRY_AVAILABLE = False

logger = logging.getLogger(__name__)


class SMSServiceProduction:
    """Production SMS service with proper error handling and fallbacks"""
    
    @staticmethod
    def send_sms(phone_number: str, message: str, sms_type: str = 'alert') -> dict:
        """
        Send SMS notification using configured provider (MSG91 or Twilio)
        
        Args:
            phone_number: Recipient phone number (with or without +91)
            message: SMS message content
            sms_type: Type of SMS (alert, verification, otp)
            
        Returns:
            dict: {'success': bool, 'provider': str, 'phone': str, 'error': str}
        """
        if not phone_number:
            return {'success': False, 'error': 'Phone number required'}
        
        # Try MSG91 first (India-optimized)
        msg91_key = config('MSG91_AUTH_KEY', default='')
        if msg91_key:
            return SMSServiceProduction.send_via_msg91(phone_number, message)
        
        # Fallback to Twilio (International)
        twilio_sid = config('TWILIO_ACCOUNT_SID', default='')
        if twilio_sid:
            return SMSServiceProduction.send_via_twilio(phone_number, message)
        
        logger.warning("No SMS provider configured (MSG91_AUTH_KEY or TWILIO_ACCOUNT_SID)")
        return {
            'success': False,
            'error': 'No SMS provider configured',
            'phone': phone_number
        }
    
    @staticmethod
    def send_via_msg91(phone_number: str, message: str) -> dict:
        """Send SMS via MSG91 API (India-focused)"""
        try:
            auth_key = config('MSG91_AUTH_KEY')
            if not auth_key:
                return {'success': False, 'error': 'MSG91_AUTH_KEY not configured', 'phone': phone_number}
            
            # Normalize phone number
            phone_number = phone_number.replace('+', '').replace(' ', '')
            if len(phone_number) == 10:
                phone_number = '91' + phone_number
            
            # MSG91 API v2 Direct SMS endpoint
            url = "https://api.msg91.com/api/v2/sendsms"
            
            payload = {
                "sender": config('MSG91_SENDER_ID', default='RESQNV'),
                "route": config('MSG91_ROUTE', default='4'),  # 4 = Transactional
                "country": "91",
                "sms": [{
                    "message": message[:160],  # SMS length limit
                    "to": [phone_number]
                }]
            }
            
            headers = {
                "authkey": auth_key,
                "content-type": "application/json"
            }
            
            # Production: verify=True (with proper SSL certs)
            # Development: verify=False if SSL issues (Windows dev environment common issue)
            import urllib3
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            
            # Try with SSL verification first
            response = requests.post(
                url,
                json=payload,
                headers=headers,
                timeout=10,
                verify=True
            )
            
            if 200 <= response.status_code < 300:
                response_data = response.json() if response.text else {}
                logger.info(f"SMS sent via MSG91 to {phone_number}. Response: {response_data}")
                return {
                    'success': True,
                    'provider': 'msg91',
                    'phone': phone_number,
                    'message_id': response_data.get('message_id', '') or response_data.get('request_id', ''),
                    'response': response_data
                }
            else:
                logger.error(f"MSG91 error {response.status_code}: {response.text}")
                return {
                    'success': False,
                    'provider': 'msg91',
                    'error': f'HTTP {response.status_code}: {response.text}',
                    'phone': phone_number
                }
                
        except requests.exceptions.SSLError as e:
            logger.warning(f"MSG91 SSL Error: {str(e)} - Retrying with SSL verification disabled (dev only)")
            
            # Capture SSL error in Sentry
            if SENTRY_AVAILABLE:
                SentryHelper.capture_sms_error(e, phone_number, "msg91")
            
            # Development fallback: retry without SSL verification
            try:
                import urllib3
                urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
                
                response = requests.post(
                    url,
                    json=payload,
                    headers=headers,
                    timeout=10,
                    verify=False  # Disable SSL verification for development
                )
                
                if 200 <= response.status_code < 300:
                    logger.info(f"SMS sent via MSG91 (SSL bypass) to {phone_number}")
                    return {
                        'success': True,
                        'provider': 'msg91',
                        'phone': phone_number,
                        'message_id': response.json().get('message_id', '') if response.text else '',
                        'note': 'SSL verification bypassed (development mode)'
                    }
                else:
                    logger.error(f"MSG91 error (SSL bypass) {response.status_code}: {response.text}")
                    return {
                        'success': False,
                        'provider': 'msg91',
                        'error': f'HTTP {response.status_code} (SSL bypass failed)',
                        'phone': phone_number
                    }
                    
            except Exception as retry_error:
                logger.error(f"MSG91 SSL bypass also failed: {str(retry_error)}")
                return {
                    'success': False,
                    'provider': 'msg91',
                    'error': f'SSL Error + Retry Failed: {str(retry_error)}',
                    'phone': phone_number
                }
                
        except requests.exceptions.Timeout:
            logger.error("MSG91 request timeout")
            return {
                'success': False,
                'provider': 'msg91',
                'error': 'Request timeout',
                'phone': phone_number
            }
        except Exception as e:
            logger.error(f"MSG91 error: {str(e)}")
            
            # Capture error in Sentry
            if SENTRY_AVAILABLE:
                SentryHelper.capture_sms_error(e, phone_number, "msg91")
            
            return {
                'success': False,
                'provider': 'msg91',
                'error': str(e),
                'phone': phone_number
            }
    
    @staticmethod
    def send_via_twilio(phone_number: str, message: str) -> dict:
        """Send SMS via Twilio API (International)"""
        try:
            account_sid = config('TWILIO_ACCOUNT_SID')
            auth_token = config('TWILIO_AUTH_TOKEN')
            from_phone = config('TWILIO_PHONE_NUMBER')
            
            if not all([account_sid, auth_token, from_phone]):
                return {
                    'success': False,
                    'error': 'Twilio credentials not configured',
                    'phone': phone_number
                }
            
            from twilio.rest import Client
            
            client = Client(account_sid, auth_token)
            
            # Normalize phone number
            if not phone_number.startswith('+'):
                phone_number = '+' + phone_number
            
            sms = client.messages.create(
                body=message[:160],  # SMS length limit
                from_=from_phone,
                to=phone_number
            )
            
            logger.info(f"SMS sent via Twilio to {phone_number}, SID: {sms.sid}")
            return {
                'success': True,
                'provider': 'twilio',
                'phone': phone_number,
                'message_id': sms.sid
            }
            
        except Exception as e:
            logger.error(f"Twilio error: {str(e)}")
            
            # Capture error in Sentry
            if SENTRY_AVAILABLE:
                SentryHelper.capture_sms_error(e, phone_number, "twilio")
            
            return {
                'success': False,
                'provider': 'twilio',
                'error': str(e),
                'phone': phone_number
            }


class EmergencySMSAlert:
    """Specialized SMS alerts for emergency scenarios"""
    
    @staticmethod
    def send_emergency_alert(contact_phone: str, alert_type: str, location: str, user_name: str, user_phone: str = None) -> dict:
        """Send emergency alert SMS"""
        message = f"🚨 EMERGENCY ALERT\n\n{user_name} needs help!\nType: {alert_type}\nLocation: {location}"
        
        if user_phone:
            message += f"\nContact: {user_phone}"
        
        message += "\n\nCheck ResQNav app for live location."
        
        return SMSServiceProduction.send_sms(contact_phone, message, 'emergency')
    
    @staticmethod
    def send_otp(phone_number: str, otp_code: str) -> dict:
        """Send OTP verification code"""
        message = f"Your ResQNav verification code is: {otp_code}. Valid for 10 minutes. Do not share this code."
        return SMSServiceProduction.send_sms(phone_number, message, 'otp')
    
    @staticmethod
    def send_test_message(phone_number: str) -> dict:
        """Send test SMS to verify service is working"""
        message = "ResQNav SMS service test. If you received this message, SMS delivery is working correctly."
        return SMSServiceProduction.send_sms(phone_number, message, 'test')


# Backward compatibility with existing code
class SMSService:
    """Legacy wrapper for backward compatibility"""
    
    @staticmethod
    def send_emergency_alert(phone_number: str, message: str, user_name: str = None, location: str = None) -> dict:
        """Legacy method - use EmergencySMSAlert.send_emergency_alert instead"""
        if user_name and location:
            return EmergencySMSAlert.send_emergency_alert(phone_number, "Emergency", location, user_name)
        return SMSServiceProduction.send_sms(phone_number, message, 'alert')