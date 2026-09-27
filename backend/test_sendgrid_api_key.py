#!/usr/bin/env python
"""Test if SendGrid API key is valid"""

from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

API_KEY = "SG.4NHE2B3D1W614L4X49NY758K"

print("Testing SendGrid API Key...")
print(f"Key: {API_KEY[:10]}...")
print()

try:
    # Create a test email
    message = Mail(
        from_email='noreply@resqnav.com',
        to_emails='test@example.com',
        subject='SendGrid API Key Test',
        plain_text_content='This is a test email to verify the API key works.',
        html_content='<p>This is a test email to verify the API key works.</p>'
    )
    
    # Try to send
    sg = SendGridAPIClient(API_KEY)
    response = sg.send(message)
    
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.body}")
    print(f"Response Headers: {response.headers}")
    
    if response.status_code == 202:
        print("\n✓ SUCCESS: API key is valid and email queued for delivery!")
    else:
        print(f"\n✗ ERROR: Unexpected response code {response.status_code}")
        
except Exception as e:
    print(f"✗ Exception: {e}")
    import traceback
    traceback.print_exc()
