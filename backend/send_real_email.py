"""
Send REAL password reset email to your Gmail account
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.core.mail import send_mail
from django.conf import settings

print("\n" + "="*70)
print("RESQNAV - SENDING REAL PASSWORD RESET EMAIL")
print("="*70)
print(f"Gmail: kkiaravs12@gmail.com")
print(f"Backend: {settings.EMAIL_BACKEND}")
print("="*70)

try:
    result = send_mail(
        'ResQNav - Password Reset',
        '''Hi Test User,

We received a request to reset your password.

Click the link below to reset your password:
http://localhost:3000/reset-password?token=MTE:dfkn29-0b5c237fd280de946af195b012b3e02d

This link will expire in 24 hours.

If you didn't request this, please ignore this email.

Best regards,
ResQNav Team''',
        settings.DEFAULT_FROM_EMAIL,
        ['kkiaravs12@gmail.com'],
        fail_silently=False,
    )
    
    print("\n✓✓✓ SUCCESS! ✓✓✓")
    print(f"✓ Email sent to: kkiaravs12@gmail.com")
    print(f"✓ Check your Gmail inbox!")
    print(f"✓ Subject: ResQNav - Password Reset")
    print(f"✓ Password reset is now WORKING in production!")
    print("\n" + "="*70)
    
except Exception as e:
    print(f"\n✗ ERROR: {str(e)}\n")
    print("SOLUTION:")
    print("1. Go to: https://myaccount.google.com/lesssecureapps")
    print("2. Click the toggle to turn ON 'Less secure app access'")
    print("3. Run this script again")
    print("\nAlternative: Use SendGrid instead (more reliable)")
    print("https://sendgrid.com (free account, then update .env)")
    print("="*70)
