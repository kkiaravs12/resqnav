# ResQNav Backend Testing Guide

**Comprehensive Testing Instructions for All Endpoints**

---

## Table of Contents

1. [Setup](#setup)
2. [Manual Testing](#manual-testing)
3. [Testing Checklist](#testing-checklist)
4. [Common Issues](#common-issues)
5. [Performance Testing](#performance-testing)

---

## Setup

### Prerequisites

- Backend running locally or deployed
- Postman or similar API testing tool
- Real phone number for SMS testing (with MSG91 or Twilio)
- Email account for testing

### Test Account Credentials

Create a test account or use existing one:

```json
{
  "email": "test@example.com",
  "password": "TestPassword123!",
  "phone_number": "+919876543210"
}
```

---

## Manual Testing

### 1. Authentication Tests

#### 1.1 User Registration

**Endpoint:** `POST /api/auth/register/`

**Request:**
```bash
curl -X POST http://localhost:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Test User",
    "email": "testuser@example.com",
    "password": "TestPassword123"
  }'
```

**Expected Response (201):**
```json
{
  "user": {
    "id": 1,
    "username": "testuser@example.com",
    "email": "testuser@example.com",
    "first_name": "John",
    "last_name": "Test User",
    "full_name": "John Test User"
  },
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "message": "Account created! Please verify your email to enable all features.",
  "requires_email_verification": true
}
```

**Verification:**
- [ ] User created successfully
- [ ] JWT tokens returned
- [ ] Email verification message sent
- [ ] User profile created

---

#### 1.2 Email Verification

**Check Email:**
- Look for verification email in your mailbox
- Extract the verification token from the email or email body

**Endpoint:** `POST /api/auth/verify-email/`

**Request:**
```bash
curl -X POST http://localhost:8000/api/auth/verify-email/ \
  -H "Content-Type: application/json" \
  -d '{
    "token": "verification-token-from-email"
  }'
```

**Expected Response (200):**
```json
{
  "message": "Email verified successfully! Your account is now fully verified.",
  "user": { ... }
}
```

**Verification:**
- [ ] Verification token accepted
- [ ] Email marked as verified in database
- [ ] User profile updated with verified status

---

#### 1.3 User Login

**Endpoint:** `POST /api/auth/login/`

**Request:**
```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser@example.com",
    "password": "TestPassword123"
  }'
```

**Expected Response (200):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Verification:**
- [ ] Login successful with correct credentials
- [ ] Login attempt tracked in LoginHistory
- [ ] Tokens returned

---

#### 1.4 Token Refresh

**Endpoint:** `POST /api/auth/refresh/`

**Request:**
```bash
curl -X POST http://localhost:8000/api/auth/refresh/ \
  -H "Content-Type: application/json" \
  -d '{
    "refresh": "refresh-token-from-login"
  }'
```

**Expected Response (200):**
```json
{
  "access": "new-access-token"
}
```

**Verification:**
- [ ] New access token generated
- [ ] Old token still works during refresh

---

### 2. Profile Tests

#### 2.1 Get User Details

**Endpoint:** `GET /api/user/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X GET http://localhost:8000/api/user/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
```

**Expected Response (200):**
```json
{
  "id": 1,
  "username": "testuser@example.com",
  "email": "testuser@example.com",
  "first_name": "John",
  "last_name": "Test User",
  "full_name": "John Test User",
  "profile": { ... },
  "date_joined": "2026-09-25T10:00:00Z"
}
```

**Verification:**
- [ ] User profile retrieved successfully
- [ ] All user information present

---

#### 2.2 Update Profile

**Endpoint:** `PATCH /api/profile/settings/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X PATCH http://localhost:8000/api/profile/settings/ \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+919876543210",
    "bio": "Emergency responder",
    "location": "New York",
    "blood_group": "O+",
    "medical_conditions": "Allergic to penicillin"
  }'
```

**Expected Response (200):**
```json
{
  "id": 1,
  "phone_number": "+919876543210",
  "bio": "Emergency responder",
  "location": "New York",
  "blood_group": "O+",
  "medical_conditions": "Allergic to penicillin",
  ...
}
```

**Verification:**
- [ ] Profile updated successfully
- [ ] Changes reflected in subsequent GET requests
- [ ] Audit log entry created

---

### 3. Password Management Tests

#### 3.1 Change Password

**Endpoint:** `POST /api/auth/change-password/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X POST http://localhost:8000/api/auth/change-password/ \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "old_password": "TestPassword123",
    "new_password": "NewPassword456",
    "confirm_password": "NewPassword456"
  }'
```

**Expected Response (200):**
```json
{
  "message": "Password changed successfully."
}
```

**Verification:**
- [ ] Password changed successfully
- [ ] Can login with new password
- [ ] Old password no longer works
- [ ] Confirmation email sent

---

#### 3.2 Forgot Password

**Endpoint:** `POST /api/auth/forgot-password/`

**Request:**
```bash
curl -X POST http://localhost:8000/api/auth/forgot-password/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com"
  }'
```

**Expected Response (200):**
```json
{
  "message": "If an account exists for that email, a reset link has been sent."
}
```

**Verification:**
- [ ] Response indicates email sent (even if account doesn't exist)
- [ ] Check email for reset link
- [ ] Rate limit applied (3/hour)

---

#### 3.3 Reset Password

**Get Reset Token:**
- Check email for password reset message
- Extract `uid` and `token` from email body or link

**Endpoint:** `POST /api/auth/reset-password/`

**Request:**
```bash
curl -X POST http://localhost:8000/api/auth/reset-password/ \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "uid-from-email",
    "token": "token-from-email",
    "password": "NewResetPassword789"
  }'
```

**Expected Response (200):**
```json
{
  "message": "Password updated. You can sign in now."
}
```

**Verification:**
- [ ] Password reset successfully
- [ ] Can login with new password
- [ ] Old token is no longer valid

---

### 4. Two-Factor Authentication (2FA) Tests

#### 4.1 Setup 2FA (SMS)

**Endpoint:** `POST /api/security/2fa/setup/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X POST http://localhost:8000/api/security/2fa/setup/ \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "method_type": "sms",
    "phone_number": "+919876543210"
  }'
```

**Expected Response (200):**
```json
{
  "message": "2FA method set to sms. Please verify by requesting an OTP.",
  "method": {
    "id": 1,
    "method_type": "sms",
    "enabled": false,
    "phone_number": "+919876543210",
    ...
  }
}
```

**Verification:**
- [ ] 2FA method configured
- [ ] Phone number saved

---

#### 4.2 Request OTP (SMS)

**Endpoint:** `POST /api/security/2fa/request-otp/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X POST http://localhost:8000/api/security/2fa/request-otp/ \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "method_type": "sms",
    "phone_number": "+919876543210"
  }'
```

**Expected Response (200):**
```json
{
  "message": "OTP sent to sms",
  "method_type": "sms",
  "recipient": "****3210",
  "expires_in_minutes": 10,
  "otp_id": 1
}
```

**Real Phone Test:**
- [ ] SMS received with 6-digit OTP code
- [ ] OTP valid for 10 minutes
- [ ] Recipient masked in response

---

#### 4.3 Verify OTP

**Endpoint:** `POST /api/security/2fa/verify-otp/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X POST http://localhost:8000/api/security/2fa/verify-otp/ \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "123456"
  }'
```

**Expected Response (200):**
```json
{
  "message": "2FA verified successfully!",
  "otp": { ... }
}
```

**Verification:**
- [ ] OTP verified successfully
- [ ] 2FA enabled on account
- [ ] Audit log entry created

---

#### 4.4 Generate Backup Codes

**Endpoint:** `POST /api/security/2fa/backup-codes/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X POST http://localhost:8000/api/security/2fa/backup-codes/ \
  -H "Authorization: Bearer {access_token}"
```

**Expected Response (201):**
```json
{
  "message": "New backup codes generated. Save them in a safe place.",
  "codes": [
    "ABC12345-DEF67890",
    "GHI34567-JKL89012",
    ...
  ],
  "warning": "Each code can only be used once. Keep them safe!"
}
```

**Verification:**
- [ ] 10 backup codes generated
- [ ] Codes follow format XXXXXXXX-XXXXXXXX
- [ ] Each code is unique

---

### 5. Emergency Services Tests

#### 5.1 List Services with Location

**Endpoint:** `GET /api/emergency-services/`

**Query Parameters:**
- `latitude`: User latitude
- `longitude`: User longitude
- `radius`: Search radius in km
- `category`: Filter by category (optional)

**Request:**
```bash
curl "http://localhost:8000/api/emergency-services/?latitude=40.7128&longitude=-74.0060&radius=5&category=Hospital"
```

**Expected Response (200):**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "St. Luke's Hospital",
      "category": "Hospital",
      "address": "113 W 113th St, New York, NY 10025",
      "phone": "+12125231000",
      "latitude": 40.8153,
      "longitude": -73.9581,
      "status": "Open 24 hours",
      "is_active": true,
      "distance_km": 0.8,
      ...
    }
  ]
}
```

**Verification:**
- [ ] Services returned within radius
- [ ] Distance calculated correctly
- [ ] Sorted by distance (nearest first)
- [ ] Pagination working

---

### 6. Emergency Contacts Tests

#### 6.1 Add Emergency Contact

**Endpoint:** `POST /api/emergency-contacts/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X POST http://localhost:8000/api/emergency-contacts/ \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Doe",
    "relationship": "Spouse",
    "phone": "+919876543210",
    "is_primary": true
  }'
```

**Expected Response (201):**
```json
{
  "id": 1,
  "name": "Jane Doe",
  "relationship": "Spouse",
  "phone": "+919876543210",
  "is_primary": true,
  "created_at": "2026-09-25T10:00:00Z"
}
```

**Verification:**
- [ ] Contact created successfully
- [ ] Phone number stored correctly
- [ ] Primary status set

---

### 7. Emergency Alert Tests

#### 7.1 Trigger Emergency Alert

**Endpoint:** `POST /api/emergency-alert/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X POST http://localhost:8000/api/emergency-alert/ \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "alert_type": "sos",
    "message": "I need immediate assistance",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address": "123 Main St, New York, NY"
  }'
```

**Expected Response (201):**
```json
{
  "alert": {
    "id": 1,
    "alert_type": "sos",
    "status": "active",
    "message": "I need immediate assistance",
    ...
  },
  "notifications_sent": 1,
  "notifications_failed": 0,
  "total_contacts": 1,
  "message": "Emergency alert sent! 1 SMS sent successfully",
  "maps_link": "https://www.google.com/maps?q=40.7128,-74.0060"
}
```

**Real SMS Test:**
- [ ] SMS received on emergency contact phone
- [ ] Contains user name, message, and location
- [ ] Google Maps link included
- [ ] Timestamp recorded

---

#### 7.2 Resolve Emergency Alert

**Endpoint:** `POST /api/emergency-alerts/{alert_id}/resolve/`

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```bash
curl -X POST http://localhost:8000/api/emergency-alerts/1/resolve/ \
  -H "Authorization: Bearer {access_token}"
```

**Expected Response (200):**
```json
{
  "alert": {
    "id": 1,
    "status": "resolved",
    "resolved_at": "2026-09-25T15:05:00Z",
    ...
  },
  "message": "Emergency alert resolved."
}
```

**Verification:**
- [ ] Alert marked as resolved
- [ ] Resolution timestamp recorded

---

## Testing Checklist

### Authentication & Security
- [ ] Registration works with valid data
- [ ] Registration rejected with invalid email
- [ ] Email verification required before full access
- [ ] Password reset token expires after 1 hour
- [ ] Wrong password verification fails gracefully
- [ ] Rate limiting active on auth endpoints
- [ ] JWT tokens refresh properly
- [ ] Expired tokens rejected

### 2FA (Two-Factor Authentication)
- [ ] SMS OTP generated and sent
- [ ] Email OTP generated and sent
- [ ] OTP expires after 10 minutes
- [ ] Wrong OTP rejected (max 3 attempts)
- [ ] Backup codes work as fallback
- [ ] Each backup code used only once
- [ ] 2FA can be disabled

### Profile Management
- [ ] Profile updated successfully
- [ ] Blood group saved correctly
- [ ] Medical conditions tracked
- [ ] Notification preferences saved
- [ ] Profile picture uploaded (if applicable)

### Emergency Services
- [ ] Services found by category
- [ ] Distance calculated correctly
- [ ] Radius filter working
- [ ] Search filter working
- [ ] Pagination works
- [ ] Service details accurate

### Emergency Alerts
- [ ] SMS sent to all contacts
- [ ] Location tracked correctly
- [ ] Alert status updates properly
- [ ] Notifications logged
- [ ] Failed SMS retried

### Error Handling
- [ ] 404 for non-existent resources
- [ ] 400 for invalid data
- [ ] 401 for unauthorized access
- [ ] 429 for rate limit exceeded
- [ ] Error messages clear and helpful
- [ ] Errors logged properly

### Performance
- [ ] Response time < 500ms for list endpoints
- [ ] Response time < 200ms for detail endpoints
- [ ] Rate limiting doesn't affect legitimate traffic
- [ ] Database queries optimized

---

## Common Issues

### SMS Not Received

**Troubleshooting:**

1. **Check MSG91 Credentials**
   ```bash
   # Verify in .env file
   echo $MSG91_AUTH_KEY
   echo $MSG91_SENDER_ID
   ```

2. **Check Account Balance**
   - Log into MSG91 dashboard
   - Verify account has SMS credits

3. **Test Direct API**
   ```bash
   curl -X GET "https://api.msg91.com/api/v2/balance" \
     -H "authkey: YOUR_KEY"
   ```

4. **Check Phone Number Format**
   - Must include country code
   - Format: +919876543210 (not just 9876543210)

5. **Verify Template**
   - If using MSG91 templates, check template is approved

---

### Email Not Sending

**Troubleshooting:**

1. **Check Email Configuration**
   ```bash
   python manage.py shell
   from django.conf import settings
   print(settings.EMAIL_HOST_USER)
   print(settings.EMAIL_HOST_PASSWORD)
   ```

2. **Test Email Backend**
   ```python
   from django.core.mail import send_mail
   send_mail(
       'Test Subject',
       'Test Message',
       'from@example.com',
       ['to@example.com'],
       fail_silently=False,
   )
   ```

3. **Check Gmail App Password**
   - Verify 2FA enabled on Google account
   - Generate new App Password at myaccount.google.com/apppasswords

4. **Check Email Logs**
   ```bash
   tail -f /var/log/resqnav/resqnav.log | grep -i email
   ```

---

### Rate Limiting Issues

**Check Throttle Status:**
```python
python manage.py shell
from rest_framework_simplejwt.tokens import RefreshToken
from api.throttling import AuthThrottle

# Check throttle configuration
import inspect
print(inspect.getsource(AuthThrottle))
```

---

## Performance Testing

### Load Testing with Apache Bench

```bash
# Test emergency services endpoint
ab -n 1000 -c 10 http://localhost:8000/api/emergency-services/

# Test with authentication
ab -n 100 -c 5 \
  -H "Authorization: Bearer TOKEN" \
  http://localhost:8000/api/user/
```

### Load Testing with Locust

Create `locustfile.py`:

```python
from locust import HttpUser, task

class ResQNavUser(HttpUser):
    @task
    def get_services(self):
        self.client.get("/api/emergency-services/")
    
    @task
    def get_profile(self):
        headers = {"Authorization": f"Bearer {TOKEN}"}
        self.client.get("/api/user/", headers=headers)
```

Run:
```bash
locust -f locustfile.py --host=http://localhost:8000
```

---

## Success Criteria

✅ All tests passing
✅ SMS delivery verified with real numbers
✅ Email delivery verified
✅ Rate limiting working
✅ Performance acceptable
✅ Error handling comprehensive
✅ Security headers present
✅ Logs capturing events properly

---

**Last Updated:** September 25, 2026
