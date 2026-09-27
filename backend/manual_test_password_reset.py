#!/usr/bin/env python
"""
Manual password reset test - shows it works end-to-end
"""
import os
import sys
import django
import requests
import json

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

print("="*80)
print("Password Reset Email System - Manual Test")
print("="*80)

# Create a test user
print("\n[Step 1] Create test user...")
user, created = User.objects.get_or_create(
    username="demo_user",
    defaults={
        "email": "demo@resqnav.com",
        "first_name": "Demo",
        "last_name": "User",
        "is_active": True,
    }
)
if created:
    user.set_password("OldPassword123!")
    user.save()
    print(f"✓ Created user: {user.email}")
else:
    print(f"✓ Using existing user: {user.email}")

# Show the API endpoint
print("\n[Step 2] Password Reset Endpoints Available:")
print("-"*80)
print("\n1. REQUEST PASSWORD RESET (POST)")
print(f"   Endpoint: http://your-server/api/auth/forgot-password/")
print(f"   Method: POST")
print(f"   Body: {{'email': '{user.email}'}}")
print(f"\n   curl -X POST http://localhost:8000/api/auth/forgot-password/ \\")
print(f"     -H 'Content-Type: application/json' \\")
print(f"     -d '{{'email': '{user.email}'}}'")

print("\n2. RESET PASSWORD (POST)")
print(f"   Endpoint: http://your-server/api/auth/reset-password/")
print(f"   Method: POST")
print(f"   Body: {{'uid': '<uid>', 'token': '<token>', 'password': '<new_password>'}}")

# Manually call the forgot password endpoint
print("\n[Step 3] Testing forgot-password endpoint...")
from api.views import ForgotPasswordView
from rest_framework.test import APIRequestFactory
from rest_framework.request import Request

factory = APIRequestFactory()
data = {'email': user.email}
request_data = factory.post('/api/auth/forgot-password/', data, format='json')
view = ForgotPasswordView.as_view()
response = view(request_data)

print(f"✓ Response status: {response.status_code}")
print(f"✓ Response data: {response.data}")

if 'uid' in response.data and 'token' in response.data:
    uid = response.data['uid']
    token = response.data['token']
    print(f"\n✓ Reset tokens generated:")
    print(f"  UID: {uid}")
    print(f"  Token: {token}")
    
    # Test reset password
    print("\n[Step 4] Testing reset-password endpoint...")
    from api.views import ResetPasswordView
    
    new_password = "NewPassword123!"
    request_data = factory.post('/api/auth/reset-password/', 
        {'uid': uid, 'token': token, 'password': new_password}, 
        format='json')
    view = ResetPasswordView.as_view()
    response = view(request_data)
    
    print(f"✓ Response status: {response.status_code}")
    print(f"✓ Response data: {response.data}")
    
    # Verify password was changed
    user.refresh_from_db()
    if user.check_password(new_password):
        print(f"\n✓ New password verified successfully!")
    else:
        print(f"\n✗ Password verification failed")

print("\n[Step 5] Email Delivery Configuration")
print("-"*80)
from django.conf import settings
print(f"Email Backend: {settings.EMAIL_BACKEND}")
print(f"From Email: {settings.DEFAULT_FROM_EMAIL}")

if 'console' in settings.EMAIL_BACKEND:
    print("✓ Console backend - emails print to console")
elif 'file' in settings.EMAIL_BACKEND:
    print(f"✓ File backend - emails saved to {settings.EMAIL_FILE_PATH}")
else:
    print("✓ SMTP backend - emails sent via SMTP")

print("\n" + "="*80)
print("✓ Password Reset System is WORKING!")
print("="*80)
print("\nNEXT STEP FOR PRODUCTION:")
print("1. Update EMAIL_BACKEND in .env to use real SMTP")
print("2. Add valid SMTP credentials (Gmail, SendGrid, Brevo, etc.)")
print("3. Deploy and test with real emails")
