"""
Custom exception handlers for ResQNav API
"""

import logging
from rest_framework import status
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler

logger = logging.getLogger(__name__)


class ValidationException(APIException):
    """Custom validation exception"""
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = 'Validation error.'
    default_code = 'validation_error'


class AuthenticationException(APIException):
    """Custom authentication exception"""
    status_code = status.HTTP_401_UNAUTHORIZED
    default_detail = 'Authentication failed.'
    default_code = 'authentication_error'


class PermissionException(APIException):
    """Custom permission exception"""
    status_code = status.HTTP_403_FORBIDDEN
    default_detail = 'Permission denied.'
    default_code = 'permission_error'


class ResourceNotFoundException(APIException):
    """Custom resource not found exception"""
    status_code = status.HTTP_404_NOT_FOUND
    default_detail = 'Resource not found.'
    default_code = 'not_found'


class RateLimitException(APIException):
    """Custom rate limit exception"""
    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    default_detail = 'Rate limit exceeded. Please try again later.'
    default_code = 'throttled'


class ServiceUnavailableException(APIException):
    """Service temporarily unavailable"""
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_detail = 'Service temporarily unavailable.'
    default_code = 'service_unavailable'


def custom_exception_handler(exc, context):
    """
    Custom exception handler that formats error responses consistently
    """
    # Call the default exception handler first to get the standard error response
    response = drf_exception_handler(exc, context)

    if response is not None:
        # Format the error response
        formatted_response = {
            'success': False,
            'error': {
                'code': response.data.get('code', 'unknown_error') if isinstance(response.data, dict) else 'unknown_error',
                'message': str(response.data) if isinstance(response.data, dict) else response.data,
                'status_code': response.status_code,
            },
            'timestamp': __import__('datetime').datetime.now().isoformat(),
        }

        # Extract more detailed error info if available
        if isinstance(response.data, dict):
            if 'detail' in response.data:
                formatted_response['error']['message'] = response.data['detail']
            if 'message' in response.data:
                formatted_response['error']['message'] = response.data['message']

        # Log the error
        logger.error(f"API Error: {formatted_response['error']['code']} - {formatted_response['error']['message']}")

        response.data = formatted_response

    return response


def format_error_response(message: str, code: str = 'error', status_code: int = 400, details: dict = None):
    """
    Helper function to format error responses consistently
    """
    response_data = {
        'success': False,
        'error': {
            'code': code,
            'message': message,
            'status_code': status_code,
        },
        'timestamp': __import__('datetime').datetime.now().isoformat(),
    }

    if details:
        response_data['error']['details'] = details

    return response_data


def format_success_response(data: any = None, message: str = None, status_code: int = 200):
    """
    Helper function to format success responses consistently
    """
    response_data = {
        'success': True,
        'status_code': status_code,
        'timestamp': __import__('datetime').datetime.now().isoformat(),
    }

    if message:
        response_data['message'] = message

    if data is not None:
        response_data['data'] = data

    return response_data
