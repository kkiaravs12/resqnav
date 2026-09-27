"""Emergency Alert (SOS) endpoint tests"""
import pytest
from rest_framework import status
from api.models import EmergencyAlert


TRIGGER_URL = "/api/emergency-alert/"
LIST_URL = "/api/emergency-alerts/"
RESOLVE_URL = "/api/emergency-alerts/{}/resolve/"


@pytest.mark.django_db
class TestTriggerAlert:

    def test_trigger_sos_with_location(self, auth_client):
        data = {
            "alert_type": "sos",
            "message": "Need help urgently",
            "latitude": 28.6139,
            "longitude": 77.2090,
            "address": "New Delhi, India",
        }
        response = auth_client.post(TRIGGER_URL, data)
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["alert_type"] == "sos"
        assert response.data["status"] == "active"

    def test_trigger_medical_alert(self, auth_client):
        data = {
            "alert_type": "medical",
            "latitude": 19.0760,
            "longitude": 72.8777,
        }
        response = auth_client.post(TRIGGER_URL, data)
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["alert_type"] == "medical"

    def test_trigger_alert_no_location(self, auth_client):
        """Alert without coords is allowed (location may not be available)."""
        response = auth_client.post(TRIGGER_URL, {"alert_type": "sos"})
        assert response.status_code == status.HTTP_201_CREATED

    def test_trigger_alert_unauthenticated(self, api_client):
        response = api_client.post(TRIGGER_URL, {"alert_type": "sos"})
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_trigger_invalid_alert_type(self, auth_client):
        response = auth_client.post(TRIGGER_URL, {"alert_type": "unknown_type"})
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestAlertList:

    def test_list_own_alerts(self, auth_client, emergency_alert):
        response = auth_client.get(LIST_URL)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1

    def test_cannot_see_other_user_alerts(self, auth_client_second, emergency_alert):
        response = auth_client_second.get(LIST_URL)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 0

    def test_unauthenticated_rejected(self, api_client):
        response = api_client.get(LIST_URL)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestResolveAlert:

    def test_resolve_own_alert(self, auth_client, emergency_alert):
        response = auth_client.post(RESOLVE_URL.format(emergency_alert.pk))
        assert response.status_code == status.HTTP_200_OK
        emergency_alert.refresh_from_db()
        assert emergency_alert.status == EmergencyAlert.Status.RESOLVED

    def test_cannot_resolve_other_user_alert(self, auth_client_second, emergency_alert):
        response = auth_client_second.post(RESOLVE_URL.format(emergency_alert.pk))
        assert response.status_code in (
            status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND
        )

    def test_resolve_nonexistent_alert(self, auth_client):
        response = auth_client.post(RESOLVE_URL.format(99999))
        assert response.status_code == status.HTTP_404_NOT_FOUND
