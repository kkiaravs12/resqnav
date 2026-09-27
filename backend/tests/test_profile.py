"""User profile and search history tests"""
import pytest
from rest_framework import status
from django.contrib.auth.models import User


PROFILE_URL = "/api/profile/"
HISTORY_URL = "/api/history/"
HISTORY_DETAIL_URL = "/api/history/{}/"


@pytest.mark.django_db
class TestProfile:

    def test_get_profile_authenticated(self, auth_client, user):
        response = auth_client.get(PROFILE_URL)
        assert response.status_code == status.HTTP_200_OK

    def test_get_profile_unauthenticated(self, api_client):
        response = api_client.get(PROFILE_URL)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_update_profile(self, auth_client, user):
        response = auth_client.patch(PROFILE_URL, {"first_name": "Updated"})
        assert response.status_code == status.HTTP_200_OK


@pytest.mark.django_db
class TestSearchHistory:

    def test_list_own_history(self, auth_client, search_history):
        response = auth_client.get(HISTORY_URL)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1

    def test_history_isolated_per_user(self, auth_client_second, search_history):
        response = auth_client_second.get(HISTORY_URL)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 0

    def test_create_history(self, auth_client):
        data = {
            "search_type": "emergency",
            "query": "hospital near me",
            "destination_name": "General Hospital",
            "destination_address": "456 Oak Ave",
            "category": "Hospital",
        }
        response = auth_client.post(HISTORY_URL, data)
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["destination_name"] == "General Hospital"

    def test_delete_history_entry(self, auth_client, search_history):
        response = auth_client.delete(HISTORY_DETAIL_URL.format(search_history.pk))
        assert response.status_code == status.HTTP_204_NO_CONTENT

    def test_cannot_delete_other_user_history(self, auth_client_second, search_history):
        response = auth_client_second.delete(HISTORY_DETAIL_URL.format(search_history.pk))
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_unauthenticated_rejected(self, api_client):
        response = api_client.get(HISTORY_URL)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
