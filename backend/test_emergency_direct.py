#!/usr/bin/env python
"""Test emergency contacts directly (not via API)"""
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
print("Testing Emergency Contacts - Direct Test")
print("="*80)

# Step 1: Create test user
print("\n[Step 1] Creating test user...")
user, created = User.objects.get_or_create(
    username="emer_direct_test",
    defaults={
        "email": "emer@test.com",
        "first_name": "Test",
        "is_active": True,
    }
)
user.set_password("test123")
user.save()
print(f"✓ User: {user.username} ({user.email})")

# Step 2: Create emergency contacts
print("\n[Step 2] Creating emergency contacts...")
contact1, created1 = EmergencyContact.objects.get_or_create(
    user=user,
    phone='919876543210',
    defaults={
        'name': 'Mom',
        'relationship': 'Mother',
        'is_primary': True
    }
)
print(f"✓ Contact 1: {contact1.name} ({contact1.phone})")

contact2, created2 = EmergencyContact.objects.get_or_create(
    user=user,
    phone='919876543211',
    defaults={
        'name': 'Dad',
        'relationship': 'Father',
        'is_primary': False
    }
)
print(f"✓ Contact 2: {contact2.name} ({contact2.phone})")

# Step 3: Retrieve contacts
print("\n[Step 3] Retrieving emergency contacts...")
contacts = EmergencyContact.objects.filter(user=user)
print(f"✓ Found {contacts.count()} contacts:")
for contact in contacts:
    print(f"  - {contact.name} ({contact.phone}) - Primary: {contact.is_primary}")

if not contacts.exists():
    print("✗ NO CONTACTS FOUND!")
    sys.exit(1)

# Step 4: Create emergency alert
print("\n[Step 4] Creating emergency alert...")
alert = EmergencyAlert.objects.create(
    user=user,
    alert_type='sos',
    message='Test emergency alert',
    latitude=28.7041,
    longitude=77.1025,
    address='New Delhi, India',
    status='active'
)
print(f"✓ Alert created: {alert.id} - {alert.alert_type}")

# Step 5: Test SMS sending
print("\n[Step 5] Testing SMS sending...")
for contact in contacts:
    print(f"\n  Sending to {contact.name} ({contact.phone})...")
    
    try:
        result = SMSService.send_emergency_alert(
            phone_number=contact.phone,
            message=f"🚨 EMERGENCY: {user.first_name} needs help at {alert.address}!",
            user_name=user.first_name,
            location=alert.address
        )
        print(f"  Result: {result}")
        
        if result.get('success'):
            print(f"  ✓ SMS sent successfully")
        else:
            print(f"  ✗ SMS failed: {result.get('error')}")
    except Exception as e:
        print(f"  ✗ Exception: {e}")
        import traceback
        traceback.print_exc()

# Step 6: Check database
print("\n[Step 6] Checking database...")
print(f"Total users: {User.objects.count()}")
print(f"Total emergency contacts: {EmergencyContact.objects.count()}")
print(f"Total emergency alerts: {EmergencyAlert.objects.count()}")

print("\n" + "="*80)
print("Direct Test Complete")
print("="*80)
