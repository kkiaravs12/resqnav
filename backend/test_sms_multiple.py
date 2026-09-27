#!/usr/bin/env python
"""Test SMS sending to multiple numbers"""
import os
import sys
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth import get_user_model
from api.models import EmergencyContact, EmergencyAlert
from api.sms_service import SMSService

User = get_user_model()

print("="*80)
print("Testing SMS to Multiple Emergency Contacts")
print("="*80)

# Setup
user, _ = User.objects.get_or_create(
    username="multi_sms_test",
    defaults={"email": "multi@test.com", "first_name": "Multi", "is_active": True}
)

# Add multiple emergency contacts
print("\n[Step 1] Adding multiple emergency contacts...")

# REPLACE THESE WITH YOUR REAL PHONE NUMBERS
phone_numbers = [
    ("8355974985", "Mom"),         # Replace with your mom's number
    ("9004408118", "Dad"),         # Replace with your dad's number
    ("8425070061", "Sister"),      # Replace with your sister's number
]

for phone, name in phone_numbers:
    contact, created = EmergencyContact.objects.get_or_create(
        user=user,
        phone=phone,
        defaults={'name': name, 'relationship': name, 'is_primary': False}
    )
    status = "Created" if created else "Exists"
    print(f"  {status}: {name} ({phone})")

# Get all contacts
contacts = EmergencyContact.objects.filter(user=user)
print(f"\n✓ Total contacts: {contacts.count()}")

# Create alert
alert = EmergencyAlert.objects.create(
    user=user,
    alert_type='sos',
    message='Emergency alert - testing multiple SMS',
    address='New Delhi',
    status='active'
)

print(f"\n[Step 2] Sending SMS to ALL {contacts.count()} contacts...")

for contact in contacts:
    print(f"\n  → Sending to {contact.name} ({contact.phone})...")
    
    result = SMSService.send_emergency_alert(
        phone_number=contact.phone,
        message=f"🚨 EMERGENCY: {user.first_name} needs help!",
        user_name=user.first_name,
        location=alert.address
    )
    
    if result.get('success'):
        print(f"    ✓ SMS sent successfully")
    else:
        print(f"    ✗ Failed: {result.get('error')}")

print("\n" + "="*80)
print("✓ SMS Test Complete")
print("="*80)
print("\nTo send SMS to YOUR real contacts:")
print("1. Edit this file (test_sms_multiple.py)")
print("2. Replace the phone_numbers list with YOUR actual numbers")
print("3. Run: python test_sms_multiple.py")
print("4. All contacts will receive SMS automatically")
