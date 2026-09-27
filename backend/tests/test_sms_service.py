"""SMS service unit tests (mocked to avoid real API calls)"""
import pytest
from unittest.mock import patch, MagicMock
from api.sms_service import SMSServiceProduction, EmergencySMSAlert


class TestSMSServiceProduction:

    @patch("api.sms_service.requests.post")
    def test_send_via_msg91_success(self, mock_post):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.text = '{"message_id": "abc123"}'
        mock_response.json.return_value = {"message_id": "abc123"}
        mock_post.return_value = mock_response

        with patch("api.sms_service.config", side_effect=lambda k, **kw: {
            "MSG91_AUTH_KEY": "test_key",
            "MSG91_SENDER_ID": "RESQNV",
            "MSG91_ROUTE": "4",
        }.get(k, kw.get("default", ""))):
            result = SMSServiceProduction.send_via_msg91("9876543210", "Test SMS")

        assert result["success"] is True
        assert result["provider"] == "msg91"

    @patch("api.sms_service.requests.post")
    def test_send_via_msg91_api_error(self, mock_post):
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        mock_post.return_value = mock_response

        with patch("api.sms_service.config", side_effect=lambda k, **kw: {
            "MSG91_AUTH_KEY": "test_key",
            "MSG91_SENDER_ID": "RESQNV",
            "MSG91_ROUTE": "4",
        }.get(k, kw.get("default", ""))):
            result = SMSServiceProduction.send_via_msg91("9876543210", "Test SMS")

        assert result["success"] is False

    def test_no_provider_configured(self):
        with patch("api.sms_service.config", return_value=""):
            result = SMSServiceProduction.send_sms("9876543210", "Test")
        assert result["success"] is False
        assert "No SMS provider" in result["error"]

    def test_empty_phone_number(self):
        result = SMSServiceProduction.send_sms("", "Test")
        assert result["success"] is False

    def test_phone_normalization(self):
        """10-digit number should be prefixed with 91."""
        with patch("api.sms_service.requests.post") as mock_post, \
             patch("api.sms_service.config", side_effect=lambda k, **kw: {
                 "MSG91_AUTH_KEY": "key",
                 "MSG91_SENDER_ID": "RESQNV",
                 "MSG91_ROUTE": "4",
             }.get(k, kw.get("default", ""))):
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.text = "{}"
            mock_response.json.return_value = {}
            mock_post.return_value = mock_response

            SMSServiceProduction.send_via_msg91("9876543210", "Test")

            call_kwargs = mock_post.call_args
            payload = call_kwargs[1]["json"] if "json" in call_kwargs[1] else call_kwargs[0][1]
            phone_sent = payload["sms"][0]["to"][0]
            assert phone_sent == "919876543210"


class TestEmergencySMSAlert:

    @patch.object(SMSServiceProduction, "send_sms")
    def test_send_emergency_alert(self, mock_send):
        mock_send.return_value = {"success": True, "provider": "msg91"}
        result = EmergencySMSAlert.send_emergency_alert(
            "9876543210", "Medical", "123 Main St", "Test User"
        )
        assert result["success"] is True
        mock_send.assert_called_once()
        call_args = mock_send.call_args[0]
        assert "9876543210" == call_args[0]
        assert "EMERGENCY" in call_args[1].upper()

    @patch.object(SMSServiceProduction, "send_sms")
    def test_send_otp(self, mock_send):
        mock_send.return_value = {"success": True}
        result = EmergencySMSAlert.send_otp("9876543210", "123456")
        assert result["success"] is True
        call_args = mock_send.call_args[0]
        assert "123456" in call_args[1]
