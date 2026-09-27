"""Shared pytest fixtures for ResQNav tests"""
import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from api.models import (
    EmergencyContact, EmergencyAlert, EmergencyService, SearchHistory
)


# ─── User Fixtures ────────────────────────────────────────────

@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user(db):
    return User.objects.create_user(
        username="testuser",
        email="test@resqnav.com",
        password="SecurePass123!",
        first_name="Test",
        last_name="User",
    )


@pytest.fixture
def second_user(db):
    return User.objects.create_user(
        username="otheruser",
        email="other@resqnav.com",
        password="SecurePass123!",
    )


@pytest.fixture
def admin_user(db):
    return User.objects.create_superuser(
        username="admin",
        email="admin@resqnav.com",
        password="AdminPass123!",
    )


@pytest.fixture
def auth_client(api_client, user):
    """API client authenticated as a regular user."""
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {str(refresh.access_token)}")
    return api_client


@pytest.fixture
def auth_client_second(api_client, second_user):
    """API client authenticated as the second user."""
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(second_user)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {str(refresh.access_token)}")
    return client


# ─── Model Fixtures ───────────────────────────────────────────

@pytest.fixture
def emergency_contact(db, user):
    return EmergencyContact.objects.create(
        user=user,
        name="Jane Doe",
        phone="9876543210",
        relationship="Spouse",
        is_primary=True,
    )


@pytest.fixture
def emergency_alert(db, user):
    return EmergencyAlert.objects.create(
        user=user,
        alert_type=EmergencyAlert.AlertType.SOS,
        message="Test SOS alert",
        latitude=28.6139,
        longitude=77.2090,
        address="New Delhi, India",
    )


@pytest.fixture
def emergency_service(db):
    return EmergencyService.objects.create(
        name="City Hospital",
        category=EmergencyService.Category.HOSPITAL,
        address="123 Main St",
        phone="1800-000-001",
        latitude="28.614000",
        longitude="77.209000",
        status=EmergencyService.Status.OPEN_24_HOURS,
    )


@pytest.fixture
def search_history(db, user):
    return SearchHistory.objects.create(
        user=user,
        search_type=SearchHistory.SearchType.EMERGENCY,
        query="hospital nearby",
        destination_name="City Hospital",
        destination_address="123 Main St",
        category="Hospital",
        latitude="28.614000",
        longitude="77.209000",
    )
