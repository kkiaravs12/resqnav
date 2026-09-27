"""
Test email configuration for production setup
"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.core.mail import send_mail
from django.conf import settings

def test_email_config():
    print("\n" + "="*70)
    print("ResQNav Email Configuration Test")
    print("="*70)
    
    print(f"\nCurrent Configuration:")
    print(f"  EMAIL_BACKEND: {settings.EMAIL_BACKEND}")
    print(f"  EMAIL_HOST: {settings.EMAIL_HOST}")
    print(f"  EMAIL_PORT: {settings.EMAIL_PORT}")
    print(f"  EMAIL_USE_TLS: {settings.EMAIL_USE_TLS}")
    print(f"  EMAIL_HOST_USER: {settings.EMAIL_HOST_USER}")
    print(f"  DEFAULT_FROM_EMAIL: {settings.DEFAULT_FROM_EMAIL}")
    
    print("\n" + "="*70)
    print("Testing Email Delivery...")
    print("="*70)
    
    try:
        result = send_mail(
            'ResQNav - Production Email Test',
            '''This is a test email from ResQNav.

If you received this, your email configuration is working correctly!

The password reset and emergency alert emails will now work in production.

Best regards,
ResQNav Team''',
            settings.DEFAULT_FROM_EMAIL,
            [settings.EMAIL_HOST_USER],  # Send to your own email
            fail_silently=False,
        )
        
        if result == 1:
            print("\n✓ SUCCESS! Email sent successfully!")
            print(f"✓ From: {settings.DEFAULT_FROM_EMAIL}")
            print(f"✓ To: {settings.EMAIL_HOST_USER}")
            print("\n✓ Check your inbox!")
            print("\n✓ Production email is READY")
            return True
        else:
            print("\n✗ Email send returned 0")
            return False
            
    except Exception as e:
        print(f"\n✗ Email delivery failed!")
        print(f"\nError: {str(e)}")
        print("\nTROUBLESHOOTING:")
        print("1. Password/credentials incorrect")
        print("2. Gmail might need app-specific password (not account password)")
        print("3. Gmail security settings need adjustment")
        print("\nGmail Setup Instructions:")
        print("  1. Go to: https://myaccount.google.com/apppasswords")
        print("  2. Select 'Mail' and 'Windows Computer'")
        print("  3. Copy the 16-char password")
        print("  4. Update .env with EMAIL_HOST_PASSWORD=<copied password>")
        return False

if __name__ == '__main__':
    success = test_email_config()
    sys.exit(0 if success else 1)
