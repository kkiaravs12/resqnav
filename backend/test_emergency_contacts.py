#!/usr/bin/env python
"""Test emergency contacts API"""
import os
import sys
import django
import json

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

User = get_user_model()

print("="*80)
print("Testing Emergency Contacts API")
print("="*80)

# Step 1: Create test user
print("\n[Step 1] Creating test user...")
user, created = User.objects.get_or_create(
    username="emergency_test",
    defaults={
        "email": "emergency@test.com",
        "is_active": True,
    }
)
user.set_password("testpass123")
user.save()
print(f"✓ Test user: {user.username}")

# Step 2: Get authentication token
print("\n[Step 2] Getting auth token...")
client = APIClient()
response = client.post('/api/auth/login/', {
    'username': 'emergency_test',
    'password': 'testpass123'
})

if response.status_code == 200:
    tokens = response.json()
    access_token = tokens.get('access')
    print(f"✓ Got access token: {access_token[:20]}...")
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
else:
    print(f"✗ Login failed: {response.status_code}")
    print(f"Response: {response.json()}")
    sys.exit(1)

# Step 3: Create emergency contact
print("\n[Step 3] Creating emergency contact...")
contact_data = {
    'name': 'Mom',
    'phone': '919876543210',
    'relationship': 'Mother',
    'is_primary': True
}

response = client.post('/api/emergency-contacts/', contact_data, format='json')
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")

if response.status_code in [200, 201]:
    contact_id = response.json().get('id')
    print(f"✓ Emergency contact created: ID={contact_id}")
else:
    print(f"✗ Failed to create contact")

# Step 4: Get emergency contacts
print("\n[Step 4] Getting emergency contacts...")
response = client.get('/api/emergency-contacts/')
print(f"Status: {response.status_code}")
contacts = response.json()
print(f"✓ Retrieved {len(contacts)} contacts")
for contact in contacts:
    print(f"  - {contact['name']} ({contact['phone']})")

# Step 5: Trigger emergency alert
print("\n[Step 5] Triggering emergency alert...")
alert_data = {
    'alert_type': 'sos',
    'message': 'Testing emergency alert',
    'latitude': 28.7041,
    'longitude': 77.1025,
}

response = client.post('/api/emergency-alert/', alert_data, format='json')
print(f"Status: {response.status_code}")
response_data = response.json()
print(f"Response: {json.dumps(response_data, indent=2)}")

if response.status_code == 200:
    print(f"✓ Alert triggered")
    print(f"  - Notifications sent: {response_data.get('notifications_sent')}")
    print(f"  - Notifications failed: {response_data.get('notifications_failed')}")
else:
    print(f"✗ Failed to trigger alert")

# Step 6: Get alerts
print("\n[Step 6] Getting emergency alerts...")
response = client.get('/api/emergency-alerts/')
print(f"Status: {response.status_code}")
alerts = response.json()
print(f"✓ Retrieved {len(alerts)} alerts")
for alert in alerts:
    print(f"  - {alert['alert_type']} - {alert['status']}")

# Step 7: Get notifications
print("\n[Step 7] Getting emergency notifications...")
response = client.get('/api/emergency-notifications/')
print(f"Status: {response.status_code}")
notifications = response.json()
print(f"✓ Retrieved {len(notifications)} notifications")
for notif in notifications:
    print(f"  - {notif['notification_type']} to {notif['recipient']}: {notif['status']}")

print("\n" + "="*80)
print("Emergency API Test Complete")
print("="*80)
