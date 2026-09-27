#!/usr/bin/env python
"""
Complete test of password reset functionality end-to-end:
1. User requests password reset (forgot-password endpoint)
2. Email is generated and sent
3. Verify email file is created
4. Extract reset token from email
5. Test password reset with that token
"""

import os
import sys
import django
from pathlib import Path

# Setup Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth import get_user_model
from django.test import Client
from rest_framework import status
import json

User = get_user_model()

def test_complete_password_reset():
    """Test complete password reset flow"""
    print("="*80)
    print("Complete Password Reset Flow Test")
    print("="*80)
    
    # Step 1: Create test user
    print("\n[Step 1] Creating test user...")
    user, created = User.objects.get_or_create(
        username="resettest",
        defaults={
            "email": "resettest@example.com",
            "first_name": "Reset",
            "last_name": "Tester",
            "is_active": True,
        }
    )
    if created:
        user.set_password("OldPassword123")
        user.save()
        print(f"✓ Created new user: {user.username}")
    else:
        print(f"✓ Using existing user: {user.username}")
    
    print(f"  Email: {user.email}")
    print(f"  Username: {user.username}")
    
    # Step 2: Clear old emails
    print("\n[Step 2] Clearing old emails...")
    from django.conf import settings
    email_dir = Path(settings.EMAIL_FILE_PATH)
    if email_dir.exists():
        for email_file in email_dir.glob("*"):
            email_file.unlink()
        print(f"✓ Cleared emails directory: {email_dir}")
    else:
        email_dir.mkdir(parents=True, exist_ok=True)
        print(f"✓ Created emails directory: {email_dir}")
    
    # Step 3: Request password reset via API
    print("\n[Step 3] Requesting password reset via API...")
    client = Client()
    
    response = client.post(
        '/api/auth/forgot-password/',
        data=json.dumps({'email': user.email}),
        content_type='application/json'
    )
    
    print(f"  Response Status: {response.status_code}")
    print(f"  Response Data: {response.json()}")
    
    if response.status_code != status.HTTP_200_OK:
        print(f"✗ Failed to request password reset")
        return False
    
    print("✓ Password reset request sent")
    
    # Step 4: Check if email file was created
    print("\n[Step 4] Verifying email was created...")
    email_files = list(email_dir.glob("*"))
    
    if not email_files:
        print("✗ No email files found")
        return False
    
    email_file = email_files[0]
    print(f"✓ Email file created: {email_file.name}")
    
    # Step 5: Read email content
    print("\n[Step 5] Reading email content...")
    with open(email_file, 'r') as f:
        email_content = f.read()
    
    print("Email Preview:")
    print("-"*80)
    print(email_content[:500])
    print("-"*80)
    
    # Extract reset token from email
    if 'reset-password?token=' in email_content:
        token_start = email_content.find('reset-password?token=') + len('reset-password?token=')
        token_end = email_content.find('\n', token_start)
        reset_token = email_content[token_start:token_end].strip()
        print(f"\n✓ Reset token extracted: {reset_token[:30]}...")
    else:
        print("✗ Reset token not found in email")
        return False
    
    # Step 6: Parse UID and token
    print("\n[Step 6] Parsing reset token...")
    if ':' not in reset_token:
        print("✗ Invalid token format (missing colon)")
        return False
    
    uid, token = reset_token.split(':', 1)
    print(f"✓ UID: {uid}")
    print(f"✓ Token: {token[:20]}...")
    
    # Step 7: Test password reset
    print("\n[Step 7] Testing password reset with extracted token...")
    new_password = "NewPassword123!"
    
    response = client.post(
        '/api/auth/reset-password/',
        data=json.dumps({
            'uid': uid,
            'token': token,
            'password': new_password
        }),
        content_type='application/json'
    )
    
    print(f"  Response Status: {response.status_code}")
    print(f"  Response Data: {response.json()}")
    
    if response.status_code not in [status.HTTP_200_OK, status.HTTP_201_CREATED]:
        print(f"✗ Password reset failed")
        return False
    
    print("✓ Password reset successful")
    
    # Step 8: Verify new password works
    print("\n[Step 8] Verifying new password...")
    user.refresh_from_db()
    
    if user.check_password(new_password):
        print("✓ New password verified successfully")
    else:
        print("✗ New password verification failed")
        return False
    
    print("\n" + "="*80)
    print("✓✓✓ Complete password reset flow works end-to-end! ✓✓✓")
    print("="*80)
    print("\nSummary:")
    print(f"1. ✓ User created: {user.email}")
    print(f"2. ✓ Password reset email generated")
    print(f"3. ✓ Email saved to: {email_file}")
    print(f"4. ✓ Reset token extracted from email")
    print(f"5. ✓ Password reset endpoint works")
    print(f"6. ✓ New password is valid")
    print("\n✓ Ready for production deployment!")
    
    return True


if __name__ == "__main__":
    try:
        success = test_complete_password_reset()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
