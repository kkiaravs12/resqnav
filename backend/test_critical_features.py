"""
Critical feature testing: Password reset email + Emergency alert SMS
"""
import os
import django
from django.contrib.auth import get_user_model

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from api.models import EmergencyContact, EmergencyAlert
from api.email_services import EmailService
from api.sms_service import SMSServiceProduction
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from django.contrib.auth.tokens import default_token_generator

User = get_user_model()


def test_password_reset_email():
    """Test password reset email sending"""
    print("\n" + "="*60)
    print("TEST 1: Password Reset Email")
    print("="*60)
    
    # Get or create test user
    user, created = User.objects.get_or_create(
        username='testuser_pw_reset',
        defaults={'email': 'testuser_pw@example.com', 'first_name': 'Test'}
    )
    
    if created:
        user.set_password('password123')
        user.save()
        print(f"✓ Created test user: {user.email}")
    else:
        print(f"✓ Using existing test user: {user.email}")
    
    # Generate reset token
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    reset_token = f"{uid}:{token}"
    
    print(f"✓ Generated reset token: {reset_token[:30]}...")
    
    # Send password reset email
    try:
        result = EmailService.send_password_reset_email(user, reset_token)
        if result:
            print(f"✓ Password reset email sent to {user.email}")
            print(f"✓ Reset URL: http://localhost:3000/reset-password?token={reset_token[:50]}...")
        else:
            print(f"✗ Failed to send password reset email")
            return False
    except Exception as e:
        print(f"✗ Error sending password reset email: {str(e)}")
        return False
    
    return True


def test_emergency_alert_sms():
    """Test emergency alert SMS to saved contacts"""
    print("\n" + "="*60)
    print("TEST 2: Emergency Alert SMS to Saved Contacts")
    print("="*60)
    
    # Get or create test user
    user, created = User.objects.get_or_create(
        username='testuser_emergency',
        defaults={'email': 'testuser_emergency@example.com', 'first_name': 'Emergency'}
    )
    
    if created:
        user.set_password('password123')
        user.save()
        print(f"✓ Created test user: {user.username}")
    else:
        print(f"✓ Using existing test user: {user.username}")
    
    # Create or get emergency contacts
    contact1, created1 = EmergencyContact.objects.get_or_create(
        user=user,
        phone='+919876543210',
        defaults={'name': 'Emergency Contact 1', 'relationship': 'Family', 'is_primary': True}
    )
    
    if created1:
        print(f"✓ Created emergency contact 1: {contact1.name} ({contact1.phone})")
    else:
        print(f"✓ Using existing emergency contact 1: {contact1.name} ({contact1.phone})")
    
    contact2, created2 = EmergencyContact.objects.get_or_create(
        user=user,
        phone='+919876543211',
        defaults={'name': 'Emergency Contact 2', 'relationship': 'Friend'}
    )
    
    if created2:
        print(f"✓ Created emergency contact 2: {contact2.name} ({contact2.phone})")
    else:
        print(f"✓ Using existing emergency contact 2: {contact2.name} ({contact2.phone})")
    
    # Create emergency alert
    alert = EmergencyAlert.objects.create(
        user=user,
        alert_type='sos',
        message='Test emergency alert',
        latitude=28.6139,
        longitude=77.2090,
        address='Test Location'
    )
    print(f"✓ Created emergency alert: {alert.id}")
    
    # Get all emergency contacts
    emergency_contacts = EmergencyContact.objects.filter(user=user)
    print(f"✓ Found {emergency_contacts.count()} emergency contacts")
    
    if not emergency_contacts.exists():
        print("✗ No emergency contacts found!")
        return False
    
    # Send SMS to each contact
    notifications_sent = 0
    notifications_failed = 0
    
    for contact in emergency_contacts:
        print(f"\n  Sending SMS to: {contact.name} ({contact.phone})")
        
        message = f"🚨 EMERGENCY: {user.get_full_name()} needs help! {alert.message}. Location: {alert.address}"
        
        try:
            # Send SMS using SMSServiceProduction
            sms_result = SMSServiceProduction.send_sms(
                phone_number=contact.phone,
                message=message,
                sms_type='alert'
            )
            
            if sms_result.get('success'):
                print(f"  ✓ SMS sent via {sms_result.get('provider', 'unknown')}")
                notifications_sent += 1
            else:
                error = sms_result.get('error', 'Unknown error')
                print(f"  ✗ SMS failed: {error}")
                notifications_failed += 1
        except Exception as e:
            print(f"  ✗ Error sending SMS: {str(e)}")
            notifications_failed += 1
    
    print(f"\n✓ Summary: {notifications_sent} sent, {notifications_failed} failed")
    
    return notifications_sent > 0


def test_sms_service_directly():
    """Test SMS service directly with test numbers"""
    print("\n" + "="*60)
    print("TEST 3: Direct SMS Service Test")
    print("="*60)
    
    test_numbers = [
        '+919876543210',  # Indian number with country code
        '9876543210',     # Indian number without country code
    ]
    
    for phone in test_numbers:
        print(f"\nTesting SMS to: {phone}")
        
        result = SMSServiceProduction.send_sms(
            phone_number=phone,
            message="Test message from ResQNav emergency system",
            sms_type='alert'
        )
        
        if result.get('success'):
            print(f"  ✓ SMS sent via {result.get('provider')}")
        else:
            print(f"  ✗ SMS failed: {result.get('error')}")


def main():
    print("\n" + "█"*60)
    print("█  ResQNav Critical Features Test")
    print("█  Password Reset Email + Emergency Alert SMS")
    print("█"*60)
    
    # Run tests
    pw_reset_ok = test_password_reset_email()
    emergency_sms_ok = test_emergency_alert_sms()
    
    # Additional direct SMS test
    test_sms_service_directly()
    
    # Summary
    print("\n" + "="*60)
    print("RESULTS")
    print("="*60)
    print(f"Password Reset Email: {'✓ PASS' if pw_reset_ok else '✗ FAIL'}")
    print(f"Emergency Alert SMS: {'✓ PASS' if emergency_sms_ok else '✗ FAIL'}")
    
    if pw_reset_ok and emergency_sms_ok:
        print("\n✓ All critical features working!")
    else:
        print("\n✗ Some features need fixing")


if __name__ == '__main__':
    main()
