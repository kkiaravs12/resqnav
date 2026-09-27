#!/usr/bin/env python
"""Debug MSG91 API response"""
import os
import sys
import django
import requests
import json

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.conf import settings
from decouple import config
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

print("="*80)
print("MSG91 API Debug - Check Actual Response")
print("="*80)

# Get credentials
auth_key = config('MSG91_AUTH_KEY')
sender_id = config('MSG91_SENDER_ID', default='RESQNV')
route = config('MSG91_ROUTE', default='4')

print(f"\n[Config]")
print(f"  AUTH_KEY: {auth_key[:10]}...")
print(f"  SENDER_ID: {sender_id}")
print(f"  ROUTE: {route}")

# Test phone numbers
test_numbers = [
    "918355974985",  # Your test number
    "919876543210",  # Placeholder
]

for phone in test_numbers:
    print(f"\n[Test] Sending to: {phone}")
    
    url = "https://api.msg91.com/api/v2/sendsms"
    
    payload = {
        "sender": sender_id,
        "route": route,
        "country": "91",
        "sms": [{
            "message": "ResQNav Test SMS",
            "to": [phone]
        }]
    }
    
    headers = {
        "authkey": auth_key,
        "content-type": "application/json"
    }
    
    print(f"  URL: {url}")
    print(f"  Payload: {json.dumps(payload, indent=2)}")
    print(f"  Headers (authkey masked): authkey={auth_key[:10]}...")
    
    try:
        response = requests.post(
            url,
            json=payload,
            headers=headers,
            timeout=10,
            verify=False
        )
        
        print(f"\n  Response Status: {response.status_code}")
        print(f"  Response Headers: {dict(response.headers)}")
        print(f"  Response Body:")
        print(f"  {response.text}")
        
        if response.text:
            try:
                data = response.json()
                print(f"\n  Parsed JSON:")
                print(f"  {json.dumps(data, indent=2)}")
                
                # Check for errors in response
                if 'message' in data and 'error' in data.get('message', [{}])[0]:
                    print(f"\n  ✗ ERROR in MSG91 response: {data['message'][0].get('error')}")
                elif data.get('type') == 'error':
                    print(f"\n  ✗ MSG91 Error: {data.get('message')}")
                else:
                    print(f"\n  ✓ MSG91 Response looks OK")
            except:
                pass
        
    except Exception as e:
        print(f"  ✗ Exception: {e}")
        import traceback
        traceback.print_exc()

print("\n" + "="*80)
