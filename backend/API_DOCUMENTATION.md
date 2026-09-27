# ResQNav API Documentation

**Base URL:** `http://localhost:8000/api/`

**Version:** 1.0.0

---

## Table of Contents

1. [Authentication](#authentication)
2. [User Management](#user-management)
3. [Emergency Services](#emergency-services)
4. [Emergency Contacts](#emergency-contacts)
5. [Emergency Alerts](#emergency-alerts)
6. [Search History](#search-history)
7. [Security & Audit](#security--audit)
8. [Error Handling](#error-handling)

---

## Authentication

### Register New Account

**POST** `/auth/register/`

Creates a new user account and sends email verification.

**Request Body:**
```json
{
  "full_name": "John Doe",
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response (201 Created):**
```json
{
  "user": {
    "id": 1,
    "username": "john@example.com",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "full_name": "John Doe"
  },
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "message": "Account created! Please verify your email to enable all features.",
  "requires_email_verification": true
}
```

**Rate Limit:** 5 requests/minute (per IP)

---

### Login (JWT)

**POST** `/auth/login/`

Authenticate and receive JWT tokens.

**Request Body:**
```json
{
  "username": "john@example.com",
  "password": "securepassword123"
}
```

**Response (200 OK):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Rate Limit:** 5 requests/minute

---

### Refresh Token

**POST** `/auth/refresh/`

Get new access token using refresh token.

**Request Body:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response (200 OK):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

---

### Forgot Password

**POST** `/auth/forgot-password/`

Request password reset token (sent via email).

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Response (200 OK):**
```json
{
  "message": "If an account exists for that email, a reset link has been sent."
}
```

**Rate Limit:** 3 requests/hour

---

### Reset Password

**POST** `/auth/reset-password/`

Reset password using token from email.

**Request Body:**
```json
{
  "uid": "MQ==",
  "token": "abc123def456",
  "password": "newpassword123"
}
```

**Response (200 OK):**
```json
{
  "message": "Password updated. You can sign in now."
}
```

**Rate Limit:** 3 requests/hour

---

### Change Password

**POST** `/auth/change-password/`

Change password for authenticated user.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "old_password": "currentpassword",
  "new_password": "newpassword123",
  "confirm_password": "newpassword123"
}
```

**Response (200 OK):**
```json
{
  "message": "Password changed successfully."
}
```

---

### Send Email Verification

**POST** `/auth/verify-email/send/`

Send verification email to user.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "message": "Verification email sent. Please check your inbox.",
  "expires_in_hours": 24
}
```

**Rate Limit:** 10 requests/hour

---

### Verify Email

**POST** `/auth/verify-email/`

Verify email using token from verification email.

**Request Body:**
```json
{
  "token": "verification-token-from-email"
}
```

**Response (200 OK):**
```json
{
  "message": "Email verified successfully! Your account is now fully verified.",
  "user": {
    "id": 1,
    "username": "john@example.com",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "full_name": "John Doe",
    "profile": { ... }
  }
}
```

**Rate Limit:** 10 requests/hour

---

### Google OAuth Callback

**POST** `/auth/google/callback/`

Authenticate using Google OAuth.

**Request Body:**
```json
{
  "id_token": "google-jwt-token",
  "code": "authorization-code"
}
```

**Response (200 OK or 201 Created):**
```json
{
  "user": { ... },
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "created": false,
  "message": "Welcome back, John!"
}
```

**Rate Limit:** 20 requests/hour

---

## User Management

### Get User Details

**GET** `/user/`

Get authenticated user's profile and details.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "john@example.com",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "full_name": "John Doe",
  "profile": {
    "id": 1,
    "username": "john@example.com",
    "email": "john@example.com",
    "phone_number": "+919876543210",
    "avatar": "https://...",
    "bio": "Emergency responder",
    "location": "New York",
    "blood_group": "O+",
    "medical_conditions": "Allergic to penicillin",
    "emergency_verified": true,
    "sms_notifications": true,
    "email_notifications": true,
    "push_notifications": true,
    "two_factor_enabled": false,
    "two_factor_method": "sms",
    "created_at": "2026-09-25T10:00:00Z",
    "updated_at": "2026-09-25T10:00:00Z"
  },
  "date_joined": "2026-09-25T10:00:00Z"
}
```

---

### Get Profile Settings

**GET** `/profile/settings/`

Get user profile with all settings.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "john@example.com",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+919876543210",
  "avatar": null,
  "bio": "Emergency responder",
  "location": "New York",
  "blood_group": "O+",
  "medical_conditions": "Allergic to penicillin",
  "emergency_verified": true,
  "sms_notifications": true,
  "email_notifications": true,
  "push_notifications": true,
  "two_factor_enabled": false,
  "two_factor_method": "sms",
  "created_at": "2026-09-25T10:00:00Z",
  "updated_at": "2026-09-25T10:00:00Z"
}
```

---

### Update Profile Settings

**PATCH** `/profile/settings/`

Update user profile information.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "phone_number": "+919876543210",
  "bio": "Emergency responder",
  "location": "New York",
  "blood_group": "O+",
  "medical_conditions": "Allergic to penicillin",
  "sms_notifications": true,
  "email_notifications": true,
  "push_notifications": false
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "john@example.com",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+919876543210",
  "bio": "Emergency responder",
  "location": "New York",
  "blood_group": "O+",
  "medical_conditions": "Allergic to penicillin",
  "emergency_verified": true,
  "sms_notifications": true,
  "email_notifications": true,
  "push_notifications": false,
  "two_factor_enabled": false,
  "two_factor_method": "sms",
  "created_at": "2026-09-25T10:00:00Z",
  "updated_at": "2026-09-25T10:00:00Z"
}
```

---

### Get Security Settings

**GET** `/security/settings/`

Get security and notification preferences.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "two_factor_enabled": false,
  "two_factor_method": "sms",
  "email_notifications": true,
  "sms_notifications": true,
  "push_notifications": true
}
```

---

### Update Security Settings

**POST** `/security/settings/`

Update security preferences including 2FA.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "two_factor_enabled": true,
  "two_factor_method": "sms",
  "email_notifications": true,
  "sms_notifications": true,
  "push_notifications": false
}
```

**Response (200 OK):**
```json
{
  "message": "Security settings updated.",
  "settings": {
    "two_factor_enabled": true,
    "two_factor_method": "sms",
    "email_notifications": true,
    "sms_notifications": true,
    "push_notifications": false
  }
}
```

---

### Get Login History

**GET** `/security/login-history/`

Get user's login history (last 50 entries).

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 3,
      "ip_address": "192.168.1.100",
      "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)...",
      "device_name": "Chrome on Windows 10",
      "location": "New York, US",
      "success": true,
      "reason_failed": null,
      "created_at": "2026-09-25T15:30:00Z"
    },
    ...
  ]
}
```

---

### Get Audit Logs

**GET** `/security/audit-logs/`

Get user's activity audit logs (last 100 entries).

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 5,
      "action": "password_change",
      "action_display": "Password Changed",
      "description": "User changed their password",
      "ip_address": "192.168.1.100",
      "timestamp": "2026-09-25T14:20:00Z"
    },
    {
      "id": 4,
      "action": "profile_update",
      "action_display": "Profile Updated",
      "description": "Updated profile",
      "ip_address": "192.168.1.100",
      "timestamp": "2026-09-25T14:15:00Z"
    },
    ...
  ]
}
```

---

## Emergency Services

### List Emergency Services

**GET** `/emergency-services/`

List all active emergency services with optional filtering and location-based search.

**Query Parameters:**
- `category` (optional): Filter by service category
- `search` (optional): Search by name or address
- `latitude` (optional): User's latitude for distance calculation
- `longitude` (optional): User's longitude for distance calculation
- `radius` (optional): Search radius in kilometers
- `page` (optional): Page number for pagination
- `ordering` (optional): Sort by field (name, category, status, created_at)

**Example:**
```
GET /emergency-services/?category=Hospital&latitude=40.7128&longitude=-74.0060&radius=5
```

**Response (200 OK):**
```json
{
  "count": 25,
  "next": "http://localhost:8000/api/emergency-services/?page=2",
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
      "created_at": "2026-09-25T10:00:00Z",
      "updated_at": "2026-09-25T10:00:00Z"
    },
    ...
  ]
}
```

---

### Get Service Details

**GET** `/emergency-services/{id}/`

Get details of a specific emergency service.

**Response (200 OK):**
```json
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
  "distance_km": null,
  "created_at": "2026-09-25T10:00:00Z",
  "updated_at": "2026-09-25T10:00:00Z"
}
```

---

## Emergency Contacts

### List Emergency Contacts

**GET** `/emergency-contacts/`

Get user's emergency contacts.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Jane Doe",
      "relationship": "Spouse",
      "phone": "+919876543210",
      "is_primary": true,
      "created_at": "2026-09-25T10:00:00Z"
    },
    ...
  ]
}
```

---

### Create Emergency Contact

**POST** `/emergency-contacts/`

Add a new emergency contact.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "name": "Jane Doe",
  "relationship": "Spouse",
  "phone": "+919876543210",
  "is_primary": true
}
```

**Response (201 Created):**
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

---

### Update Emergency Contact

**PATCH** `/emergency-contacts/{id}/`

Update an emergency contact.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "phone": "+919999999999"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "Jane Doe",
  "relationship": "Spouse",
  "phone": "+919999999999",
  "is_primary": true,
  "created_at": "2026-09-25T10:00:00Z"
}
```

---

### Delete Emergency Contact

**DELETE** `/emergency-contacts/{id}/`

Delete an emergency contact.

**Headers:** `Authorization: Bearer {access_token}`

**Response (204 No Content)**

---

## Emergency Alerts

### Trigger Emergency Alert

**POST** `/emergency-alert/`

Trigger an emergency alert and notify all emergency contacts via SMS/Email.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "alert_type": "sos",
  "message": "I need immediate assistance",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "address": "123 Main St, New York, NY"
}
```

**Response (201 Created):**
```json
{
  "alert": {
    "id": 1,
    "alert_type": "sos",
    "status": "active",
    "message": "I need immediate assistance",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address": "123 Main St, New York, NY",
    "created_at": "2026-09-25T15:00:00Z",
    "resolved_at": null
  },
  "notifications_sent": 2,
  "notifications_failed": 0,
  "total_contacts": 2,
  "message": "Emergency alert sent! 2 SMS sent successfully",
  "maps_link": "https://www.google.com/maps?q=40.7128,-74.0060"
}
```

**Rate Limit:** 10 requests/minute

---

### List Emergency Alerts

**GET** `/emergency-alerts/`

Get user's emergency alerts.

**Headers:** `Authorization: Bearer {access_token}`

**Query Parameters:**
- `status` (optional): Filter by status (active, resolved, cancelled)
- `alert_type` (optional): Filter by alert type

**Response (200 OK):**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "alert_type": "sos",
      "status": "resolved",
      "message": "I need immediate assistance",
      "latitude": 40.7128,
      "longitude": -74.0060,
      "address": "123 Main St, New York, NY",
      "created_at": "2026-09-25T15:00:00Z",
      "resolved_at": "2026-09-25T15:05:00Z"
    },
    ...
  ]
}
```

---

### Resolve Emergency Alert

**POST** `/emergency-alerts/{alert_id}/resolve/`

Mark an emergency alert as resolved.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "alert": {
    "id": 1,
    "alert_type": "sos",
    "status": "resolved",
    "message": "I need immediate assistance",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address": "123 Main St, New York, NY",
    "created_at": "2026-09-25T15:00:00Z",
    "resolved_at": "2026-09-25T15:05:00Z"
  },
  "message": "Emergency alert resolved."
}
```

---

### List Emergency Notifications

**GET** `/emergency-notifications/`

Get notifications sent for user's emergency alerts.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "count": 2,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "emergency_alert": 1,
      "emergency_contact": 1,
      "emergency_contact_name": "Jane Doe",
      "notification_type": "sms",
      "status": "sent",
      "message": "🚨 EMERGENCY: John Doe needs help!...",
      "recipient": "+919876543210",
      "sent_at": "2026-09-25T15:00:15Z",
      "delivered_at": null,
      "error_message": "",
      "created_at": "2026-09-25T15:00:00Z"
    },
    ...
  ]
}
```

---

## Search History

### List Search History

**GET** `/history/`

Get user's search history.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "count": 10,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "search_type": "destination",
      "query": "Hospital",
      "destination_name": "St. Luke's Hospital",
      "destination_address": "113 W 113th St, New York, NY 10025",
      "category": "Hospital",
      "latitude": 40.8153,
      "longitude": -73.9581,
      "distance_meters": 500.0,
      "duration_seconds": 120.0,
      "created_at": "2026-09-25T14:30:00Z"
    },
    ...
  ]
}
```

---

### Clear Search History

**DELETE** `/history/`

Delete all user's search history.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "message": "Deleted 10 history records."
}
```

---

## Error Handling

All errors follow a consistent format:

**Error Response Format:**
```json
{
  "success": false,
  "error": {
    "code": "error_code",
    "message": "Error description",
    "status_code": 400
  },
  "timestamp": "2026-09-25T15:00:00Z"
}
```

### Common Error Codes

| Status | Code | Message |
|--------|------|---------|
| 400 | `validation_error` | Validation error in request data |
| 401 | `authentication_error` | Authentication failed or token invalid |
| 403 | `permission_error` | User doesn't have permission |
| 404 | `not_found` | Resource not found |
| 429 | `throttled` | Rate limit exceeded |
| 500 | `server_error` | Internal server error |

### Example Error Response

```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Email with this address already exists.",
    "status_code": 400
  },
  "timestamp": "2026-09-25T15:00:00Z"
}
```

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| `/auth/register/` | 5/minute |
| `/auth/login/` | 5/minute |
| `/auth/forgot-password/` | 3/hour |
| `/auth/reset-password/` | 3/hour |
| `/auth/verify-email/` | 10/hour |
| `/auth/google/callback/` | 20/hour |
| General Authenticated User | 1000/hour |
| Emergency Alert | 10/minute |

---

## Security Headers

All responses include security headers:

```
Strict-Transport-Security: max-age=15768000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
```

---

## Authentication

All protected endpoints require JWT token in the `Authorization` header:

```
Authorization: Bearer {access_token}
```

---

## Version History

- **v1.0.0** (2026-09-25): Initial API release
  - User authentication and profile management
  - Emergency services search and discovery
  - Emergency contacts and alert system
  - Email verification and password reset
  - Google OAuth integration
  - Security audit logs and login history
  - Rate limiting and comprehensive error handling


---

## Two-Factor Authentication (2FA)

### Setup 2FA

**GET** `/security/2fa/setup/`

Get current 2FA setup status.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "id": 1,
  "method_type": "sms",
  "enabled": false,
  "phone_number": "",
  "created_at": "2026-09-25T10:00:00Z",
  "updated_at": "2026-09-25T10:00:00Z"
}
```

---

### Setup 2FA Method

**POST** `/security/2fa/setup/`

Setup or change 2FA method.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "method_type": "sms",
  "phone_number": "+919876543210"
}
```

**Response (200 OK):**
```json
{
  "message": "2FA method set to sms. Please verify by requesting an OTP.",
  "method": {
    "id": 1,
    "method_type": "sms",
    "enabled": false,
    "phone_number": "+919876543210",
    "created_at": "2026-09-25T10:00:00Z",
    "updated_at": "2026-09-25T10:00:00Z"
  }
}
```

---

### Disable 2FA

**DELETE** `/security/2fa/setup/`

Disable 2FA for the account.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "message": "2FA has been disabled."
}
```

---

### Request OTP

**POST** `/security/2fa/request-otp/`

Request a One-Time Password for 2FA verification.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "method_type": "sms",
  "phone_number": "+919876543210"
}
```

**Response (200 OK):**
```json
{
  "message": "OTP sent to sms",
  "method_type": "sms",
  "recipient": "****3210",
  "expires_in_minutes": 10,
  "otp_id": 1
}
```

---

### Verify OTP

**POST** `/security/2fa/verify-otp/`

Verify OTP code to enable 2FA.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "code": "123456"
}
```

**Response (200 OK):**
```json
{
  "message": "2FA verified successfully!",
  "otp": {
    "id": 1,
    "code": "123456",
    "method_type": "sms",
    "recipient": "+919876543210",
    "status": "verified",
    "attempts": 1,
    "max_attempts": 3,
    "created_at": "2026-09-25T15:00:00Z",
    "expires_at": "2026-09-25T15:10:00Z",
    "verified_at": "2026-09-25T15:00:30Z"
  }
}
```

---

### Get Backup Codes

**GET** `/security/2fa/backup-codes/`

Get unused 2FA backup codes.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**
```json
{
  "count": 10,
  "codes": [
    {
      "id": 1,
      "code": "ABC12345-DEF67890",
      "used": false,
      "used_at": null,
      "created_at": "2026-09-25T10:00:00Z"
    },
    ...
  ]
}
```

---

### Generate New Backup Codes

**POST** `/security/2fa/backup-codes/`

Generate new backup codes for 2FA recovery. Old codes will be invalidated.

**Headers:** `Authorization: Bearer {access_token}`

**Response (201 Created):**
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

---

### Verify Backup Code

**POST** `/security/2fa/backup-code/verify/`

Use backup code to verify identity when OTP is unavailable.

**Headers:** `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "code": "ABC12345-DEF67890"
}
```

**Response (200 OK):**
```json
{
  "message": "Backup code verified successfully.",
  "remaining_codes": 9
}
```

---

## 2FA Configuration

### Supported Methods

1. **SMS**: Receive OTP via text message
2. **Email**: Receive OTP via email
3. **TOTP**: Use authenticator app (future enhancement)

### OTP Details

- **Length**: 6-digit codes
- **Validity**: 10 minutes
- **Max Attempts**: 3 attempts per OTP
- **Backup Codes**: 10 codes per setup (single-use)
- **Storage**: Keep backup codes in a secure location

### 2FA Setup Flow

1. Call `POST /security/2fa/setup/` to configure method
2. Call `POST /security/2fa/request-otp/` to receive code
3. Call `POST /security/2fa/verify-otp/` with code to enable
4. Call `POST /security/2fa/backup-codes/` to generate recovery codes
5. Store backup codes securely

### Recovery Process

If OTP method is unavailable:
1. Call `POST /security/2fa/backup-code/verify/` with backup code
2. Each backup code can only be used once
3. Generate new backup codes after use

---
