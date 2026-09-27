"""Emergency Contacts endpoint tests"""
import pytest
from rest_framework import status


LIST_URL = "/api/emergency-contacts/"
DETAIL_URL = "/api/emergency-contacts/{}/"


@pytest.mark.django_db
class TestEmergencyContactList:

    def test_list_own_contacts(self, auth_client, emergency_contact):
        response = auth_client.get(LIST_URL)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1
        assert response.data["results"][0]["name"] == "Jane Doe"

    def test_cannot_see_other_user_contacts(self, auth_client_second, emergency_contact):
        # emergency_contact belongs to 'user', not 'second_user'
        response = auth_client_second.get(LIST_URL)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 0

    def test_unauthenticated_rejected(self, api_client):
        response = api_client.get(LIST_URL)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_create_contact_success(self, auth_client):
        data = {
            "name": "Bob Smith",
            "phone": "9999988888",
            "relationship": "Friend",
            "is_primary": False,
        }
        response = auth_client.post(LIST_URL, data)
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["name"] == "Bob Smith"

    def test_create_contact_missing_phone(self, auth_client):
        response = auth_client.post(LIST_URL, {"name": "No Phone"})
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_contact_missing_name(self, auth_client):
        response = auth_client.post(LIST_URL, {"phone": "9999900000"})
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestEmergencyContactDetail:

    def test_retrieve_own_contact(self, auth_client, emergency_contact):
        response = auth_client.get(DETAIL_URL.format(emergency_contact.pk))
        assert response.status_code == status.HTTP_200_OK
        assert response.data["name"] == "Jane Doe"

    def test_cannot_retrieve_other_user_contact(self, auth_client_second, emergency_contact):
        response = auth_client_second.get(DETAIL_URL.format(emergency_contact.pk))
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_own_contact(self, auth_client, emergency_contact):
        response = auth_client.patch(
            DETAIL_URL.format(emergency_contact.pk),
            {"name": "Jane Updated"},
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["name"] == "Jane Updated"

    def test_delete_own_contact(self, auth_client, emergency_contact):
        response = auth_client.delete(DETAIL_URL.format(emergency_contact.pk))
        assert response.status_code == status.HTTP_204_NO_CONTENT

    def test_cannot_delete_other_user_contact(self, auth_client_second, emergency_contact):
        response = auth_client_second.delete(DETAIL_URL.format(emergency_contact.pk))
        assert response.status_code == status.HTTP_404_NOT_FOUND
