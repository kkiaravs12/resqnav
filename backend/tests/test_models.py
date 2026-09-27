"""Model unit tests"""
import pytest
from django.contrib.auth.models import User
from api.models import (
    EmergencyContact, EmergencyAlert, EmergencyService, SearchHistory
)
from api.models_tokens import TokenBlacklist, DeviceToken, SessionLog


@pytest.mark.django_db
class TestEmergencyContactModel:

    def test_str_representation(self, emergency_contact):
        assert "Jane Doe" in str(emergency_contact)
        assert "Spouse" in str(emergency_contact)

    def test_default_relationship(self, db, user):
        contact = EmergencyContact.objects.create(
            user=user, name="No Rel", phone="1234567890"
        )
        assert contact.relationship == "Family"

    def test_is_primary_default_false(self, db, user):
        contact = EmergencyContact.objects.create(
            user=user, name="Normal", phone="1111111111"
        )
        assert contact.is_primary is False

    def test_ordering_primary_first(self, db, user):
        secondary = EmergencyContact.objects.create(
            user=user, name="Secondary", phone="2222222222", is_primary=False
        )
        primary = EmergencyContact.objects.create(
            user=user, name="Primary", phone="3333333333", is_primary=True
        )
        contacts = list(EmergencyContact.objects.filter(user=user))
        assert contacts[0].pk == primary.pk


@pytest.mark.django_db
class TestEmergencyAlertModel:

    def test_str_representation(self, emergency_alert):
        s = str(emergency_alert)
        assert "testuser" in s
        assert "sos" in s

    def test_default_status_active(self, emergency_alert):
        assert emergency_alert.status == EmergencyAlert.Status.ACTIVE

    def test_default_type_sos(self, emergency_alert):
        assert emergency_alert.alert_type == EmergencyAlert.AlertType.SOS

    def test_alert_choices(self):
        types = [c[0] for c in EmergencyAlert.AlertType.choices]
        assert "sos" in types
        assert "medical" in types
        assert "accident" in types


@pytest.mark.django_db
class TestEmergencyServiceModel:

    def test_str_representation(self, emergency_service):
        assert "City Hospital" in str(emergency_service)
        assert "Hospital" in str(emergency_service)

    def test_active_by_default(self, emergency_service):
        assert emergency_service.is_active is True

    def test_categories_include_all_required(self):
        categories = [c[0] for c in EmergencyService.Category.choices]
        required = ["Hospital", "Police", "Fire Station", "Ambulance",
                    "Plumber", "Electrician", "Mechanic"]
        for cat in required:
            assert cat in categories


@pytest.mark.django_db
class TestTokenBlacklistModel:

    def test_cleanup_expired(self, db, user):
        from django.utils import timezone
        import datetime
        # Create an expired token entry
        TokenBlacklist.objects.create(
            user=user,
            token="expired.token.here",
            token_type="access",
            expires_at=timezone.now() - datetime.timedelta(hours=1),
        )
        assert TokenBlacklist.objects.filter(user=user).count() == 1
        TokenBlacklist.cleanup_expired()
        assert TokenBlacklist.objects.filter(user=user).count() == 0

    def test_is_token_blacklisted(self, db, user):
        from django.utils import timezone
        import datetime
        TokenBlacklist.objects.create(
            user=user,
            token="some.jwt.token",
            token_type="access",
            expires_at=timezone.now() + datetime.timedelta(hours=1),
        )
        assert TokenBlacklist.is_token_blacklisted("some.jwt.token") is True
        assert TokenBlacklist.is_token_blacklisted("other.token") is False


@pytest.mark.django_db
class TestDeviceTokenModel:

    def test_create_device_token(self, db, user):
        device = DeviceToken.objects.create(
            user=user,
            device_id="device-abc-123",
            device_type="android",
            push_token="fcm-token-xyz",
        )
        assert device.is_active is True
        assert "testuser" in str(device)

    def test_unique_device_id(self, db, user):
        DeviceToken.objects.create(
            user=user, device_id="unique-id", device_type="ios",
            push_token="apns-token",
        )
        with pytest.raises(Exception):
            DeviceToken.objects.create(
                user=user, device_id="unique-id", device_type="ios",
                push_token="apns-token-2",
            )


@pytest.mark.django_db
class TestSessionLogModel:

    def test_session_duration_calculation(self, db, user):
        from django.utils import timezone
        import datetime
        session = SessionLog.objects.create(
            user=user,
            ip_address="127.0.0.1",
            user_agent="TestAgent/1.0",
        )
        session.logout_at = session.login_at + datetime.timedelta(minutes=30)
        session.save()
        session.calculate_duration()
        assert session.duration_seconds == 1800  # 30 minutes
