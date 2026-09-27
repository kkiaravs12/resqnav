#!/usr/bin/env python
"""Test Gmail SMTP directly"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Gmail credentials from .env
EMAIL = "kkiaravs12@gmail.com"
PASSWORD = "yaei ezmp jpfl eqqn"  # App password

print("Testing Gmail SMTP Connection...")
print(f"Email: {EMAIL}")
print()

try:
    # Connect to Gmail SMTP
    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.starttls()
    
    print("✓ Connected to smtp.gmail.com:587")
    print("  Attempting login...")
    
    # Login
    server.login(EMAIL, PASSWORD)
    print(f"✓ Login successful!")
    
    # Prepare test email
    msg = MIMEMultipart('alternative')
    msg['Subject'] = 'ResQNav - Password Reset Test'
    msg['From'] = EMAIL
    msg['To'] = 'test.user@example.com'
    
    text = "Test password reset email"
    html = "<html><body><p>Test password reset email</p></body></html>"
    
    part1 = MIMEText(text, 'plain')
    part2 = MIMEText(html, 'html')
    
    msg.attach(part1)
    msg.attach(part2)
    
    # Send email
    print("\n  Sending test email...")
    server.sendmail(EMAIL, ['test.user@example.com'], msg.as_string())
    print(f"✓ Test email sent successfully to test.user@example.com")
    
    server.quit()
    
    print("\n✓ Gmail SMTP is working correctly!")
    print("✓ Password reset emails will be sent to real user accounts")
    
except Exception as e:
    print(f"\n✗ Error: {e}")
    import traceback
    traceback.print_exc()
