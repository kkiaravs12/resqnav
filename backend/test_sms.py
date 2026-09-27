#!/usr/bin/env python
"""Test SMS Service"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from api.services import SMSService

print("Testing SMS Service...")
print("=" * 50)

result = SMSService.send_emergency_alert(
    phone_number="+919876543210",
    message="Test emergency alert from ResQNav",
    user_name="Test User",
    location="Test Location"
)

print(f"\nSMS Service Test Result:")
print(f"  Success: {result.get('success')}")
print(f"  Provider: {result.get('provider')}")
print(f"  Message: {result.get('message')}")
print(f"  Phone: {result.get('phone')}")

if result.get('provider') == 'mock':
    print("\n⚠️  Note: SMS service is in MOCK mode")
    print("   To enable real SMS:")
    print("   1. Get MSG91 API key from https://msg91.com/")
    print("   2. Add to backend/.env: MSG91_AUTH_KEY=your-key")
    print("   3. Restart backend")
else:
    print("\n✓ SMS Service is ACTIVE and ready!")

print("=" * 50)
