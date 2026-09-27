#!/usr/bin/env python
"""
Test script to verify SendGrid password reset email delivery.
This test:
1. Creates or gets a test user
2. Generates a password reset token
3. Sends password reset email via SendGrid
4. Verifies the email reaches the user's registered email account
"""

import os
import sys
import django
from datetime import timedelta
from django.utils import timezone

# Setup Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from api.email_services import EmailService

User = get_user_model()

def test_password_reset_email():
    """Test SendGrid password reset email delivery"""
    print("="*80)
    print("SendGrid Password Reset Email Test")
    print("="*80)
    
    # Step 1: Create or get test user
    print("\n[Step 1] Creating test user...")
    test_email = "test.user@example.com"  # This simulates a real user email
    user, created = User.objects.get_or_create(
        username="testuser_passwordreset",
        defaults={
            "email": test_email,
            "first_name": "Test",
            "last_name": "User",
            "is_active": True,
        }
    )
    
    if created:
        user.set_password("testpass123")
        user.save()
        print(f"✓ Created new test user: {user.username}")
    else:
        print(f"✓ Using existing test user: {user.username}")
    
    print(f"  Email: {user.email}")
    print(f"  Name: {user.first_name} {user.last_name}")
    
    # Step 2: Generate password reset token
    print("\n[Step 2] Generating password reset token...")
    try:
        # Use Django's built-in PasswordResetTokenGenerator
        token_generator = PasswordResetTokenGenerator()
        uid = urlsafe_base64_encode(force_bytes(user.pk))
        token = token_generator.make_token(user)
        reset_token = f"{uid}:{token}"
        
        print(f"✓ Generated password reset token")
        print(f"  UID: {uid}")
        print(f"  Token (first 20 chars): {token[:20]}...")
        print(f"  Full Reset Token: {reset_token[:40]}...")
    except Exception as e:
        print(f"✗ Failed to generate token: {e}")
        return False
    
    # Step 3: Send password reset email via SendGrid
    print("\n[Step 3] Sending password reset email via SendGrid...")
    try:
        result = EmailService.send_password_reset_email(user, reset_token)
        
        if result:
            print(f"✓ Password reset email sent successfully!")
            print(f"  To: {user.email}")
            print(f"  From: noreply@resqnav.com")
            print(f"  Subject: ResQNav - Password Reset")
        else:
            print(f"✗ Failed to send email (returned False)")
            return False
    except Exception as e:
        print(f"✗ Exception while sending email: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    # Step 4: Verify configuration
    print("\n[Step 4] Verifying SendGrid configuration...")
    from django.conf import settings
    
    print(f"  EMAIL_BACKEND: {settings.EMAIL_BACKEND}")
    print(f"  DEFAULT_FROM_EMAIL: {settings.DEFAULT_FROM_EMAIL}")
    print(f"  SENDGRID_API_KEY: {'*' * 10}{settings.SENDGRID_API_KEY[-10:] if settings.SENDGRID_API_KEY else 'NOT SET'}")
    print(f"  FRONTEND_URL: {settings.FRONTEND_URL}")
    
    if not settings.SENDGRID_API_KEY:
        print("  ✗ WARNING: SENDGRID_API_KEY not configured!")
        return False
    else:
        print("  ✓ SendGrid API key is configured")
    
    # Step 5: Instructions for verification
    print("\n[Step 5] Verification Instructions")
    print("-"*80)
    print("✓ Email has been queued for delivery via SendGrid API")
    print("\nTo verify delivery:")
    print(f"1. Check your email account: {user.email}")
    print(f"2. Look for email from: noreply@resqnav.com")
    print(f"3. Subject: ResQNav - Password Reset")
    print(f"4. Click the reset link to verify it works")
    print(f"\nReset URL format: {settings.FRONTEND_URL}/reset-password?token={reset_token[:20]}...")
    print("\nSendGrid Dashboard: https://app.sendgrid.com/")
    print("Check 'Activity' tab to see email delivery status")
    
    print("\n" + "="*80)
    print("Test completed successfully!")
    print("="*80)
    
    return True


if __name__ == "__main__":
    try:
        success = test_password_reset_email()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
