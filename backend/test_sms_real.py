#!/usr/bin/env python
"""Test SMS sending with real MSG91 credentials"""
import os
import sys
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from api.sms_service import SMSService
from django.conf import settings

print("="*80)
print("Testing SMS with Real MSG91 Credentials")
print("="*80)

print(f"\n[Config] MSG91_AUTH_KEY: {settings.MSG91_AUTH_KEY[:10]}...")
print(f"[Config] MSG91_SENDER_ID: {settings.MSG91_SENDER_ID}")
print(f"[Config] MSG91_ROUTE: {settings.MSG91_ROUTE}")

# Test SMS sending
test_phone = "919876543210"  # Replace with real phone number
test_message = "ResQNav Test SMS - Emergency alert system"

print(f"\n[Test] Sending SMS to: {test_phone}")
print(f"[Test] Message: {test_message}")

result = SMSService.send_emergency_alert(
    phone_number=test_phone,
    message=test_message,
    user_name="Test User",
    location="New Delhi"
)

print(f"\n[Result]")
print(f"  Success: {result.get('success')}")
print(f"  Provider: {result.get('provider')}")
print(f"  Phone: {result.get('phone')}")
print(f"  Message ID: {result.get('message_id')}")
if result.get('error'):
    print(f"  Error: {result.get('error')}")

if result.get('success'):
    print("\n✓ SMS sent successfully!")
    print("✓ Check your phone for the message")
else:
    print("\n✗ SMS failed")
    print(f"Error: {result}")

print("\n" + "="*80)
