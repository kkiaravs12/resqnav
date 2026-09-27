"""Emergency Services endpoint tests"""
import pytest
from rest_framework import status
from api.models import EmergencyService


LIST_URL = "/api/emergency-services/"
DETAIL_URL = "/api/emergency-services/{}/"


@pytest.mark.django_db
class TestEmergencyServiceList:

    def test_list_services_authenticated(self, auth_client, emergency_service):
        response = auth_client.get(LIST_URL)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] >= 1

    def test_list_services_unauthenticated(self, api_client):
        response = api_client.get(LIST_URL)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_filter_by_category(self, auth_client, emergency_service):
        response = auth_client.get(f"{LIST_URL}?category=Hospital")
        assert response.status_code == status.HTTP_200_OK
        for item in response.data["results"]:
            assert item["category"] == "Hospital"

    def test_search_by_name(self, auth_client, emergency_service):
        response = auth_client.get(f"{LIST_URL}?search=City")
        assert response.status_code == status.HTTP_200_OK
        # emergency_service is named "City Hospital"
        assert any("City" in r["name"] for r in response.data["results"])

    def test_filter_inactive_services_hidden(self, auth_client, db):
        EmergencyService.objects.create(
            name="Closed Hospital",
            category=EmergencyService.Category.HOSPITAL,
            address="Dead End St",
            phone="000",
            latitude="0.000000",
            longitude="0.000000",
            is_active=False,
        )
        response = auth_client.get(LIST_URL)
        names = [r["name"] for r in response.data["results"]]
        assert "Closed Hospital" not in names


@pytest.mark.django_db
class TestEmergencyServiceDetail:

    def test_retrieve_service(self, auth_client, emergency_service):
        response = auth_client.get(DETAIL_URL.format(emergency_service.pk))
        assert response.status_code == status.HTTP_200_OK
        assert response.data["name"] == "City Hospital"
        assert response.data["category"] == "Hospital"

    def test_retrieve_nonexistent(self, auth_client):
        response = auth_client.get(DETAIL_URL.format(99999))
        assert response.status_code == status.HTTP_404_NOT_FOUND
