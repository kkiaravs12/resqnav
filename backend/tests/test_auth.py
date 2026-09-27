"""Authentication endpoint tests"""
import pytest
from django.urls import reverse
from django.contrib.auth.models import User
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken


@pytest.mark.django_db
class TestRegistration:
    url = "/api/auth/register/"

    def test_register_success(self, api_client):
        data = {
            "full_name": "John Doe",
            "email": "new@resqnav.com",
            "password": "StrongPass123!",
        }
        response = api_client.post(self.url, data)
        assert response.status_code == status.HTTP_201_CREATED
        assert User.objects.filter(email="new@resqnav.com").exists()

    def test_register_duplicate_email(self, api_client, user):
        data = {
            "full_name": "Another User",
            "email": "test@resqnav.com",  # already exists
            "password": "StrongPass123!",
        }
        response = api_client.post(self.url, data)
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_register_missing_fields(self, api_client):
        response = api_client.post(self.url, {"full_name": "Incomplete"})
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestTokenObtain:
    url = "/api/auth/token/"

    def test_login_success(self, api_client, user):
        response = api_client.post(self.url, {
            "username": "testuser",
            "password": "SecurePass123!",
        })
        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data
        assert "refresh" in response.data

    def test_login_wrong_password(self, api_client, user):
        response = api_client.post(self.url, {
            "username": "testuser",
            "password": "WrongPassword",
        })
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_login_nonexistent_user(self, api_client):
        response = api_client.post(self.url, {
            "username": "nobody",
            "password": "pass",
        })
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_login_inactive_user(self, api_client, db):
        inactive = User.objects.create_user(
            username="inactive", password="pass123", is_active=False
        )
        response = api_client.post(self.url, {
            "username": "inactive",
            "password": "pass123",
        })
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestTokenRefresh:
    url = "/api/auth/token/refresh/"

    def test_refresh_success(self, api_client, user):
        refresh = RefreshToken.for_user(user)
        response = api_client.post(self.url, {"refresh": str(refresh)})
        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data

    def test_refresh_invalid_token(self, api_client):
        response = api_client.post(self.url, {"refresh": "invalid.token.here"})
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_refresh_missing_token(self, api_client):
        response = api_client.post(self.url, {})
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestLogout:
    url = "/api/auth/logout/"

    def test_logout_success(self, auth_client, user):
        refresh = RefreshToken.for_user(user)
        response = auth_client.post(self.url, {"refresh": str(refresh)})
        assert response.status_code == status.HTTP_200_OK

    def test_logout_missing_refresh(self, auth_client):
        response = auth_client.post(self.url, {})
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_logout_unauthenticated(self, api_client, user):
        refresh = RefreshToken.for_user(user)
        response = api_client.post(self.url, {"refresh": str(refresh)})
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestForgotPassword:
    url = "/api/auth/forgot-password/"

    def test_forgot_password_existing_email(self, api_client, user):
        response = api_client.post(self.url, {"email": "test@resqnav.com"})
        # Should return 200 regardless (don't leak user existence)
        assert response.status_code == status.HTTP_200_OK

    def test_forgot_password_nonexistent_email(self, api_client):
        response = api_client.post(self.url, {"email": "nobody@resqnav.com"})
        assert response.status_code == status.HTTP_200_OK

    def test_forgot_password_missing_email(self, api_client):
        response = api_client.post(self.url, {})
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestSessionHistory:
    url = "/api/auth/sessions/"

    def test_session_history_authenticated(self, auth_client):
        response = auth_client.get(self.url)
        assert response.status_code == status.HTTP_200_OK
        assert "results" in response.data

    def test_session_history_unauthenticated(self, api_client):
        response = api_client.get(self.url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
