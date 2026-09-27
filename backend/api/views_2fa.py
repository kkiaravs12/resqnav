"""
Two-Factor Authentication views for ResQNav
"""

import logging
from datetime import timedelta

from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models_2fa import TwoFactorMethod, TwoFactorOTP, TwoFactorBackupCode
from .models_auth import AuditLog
from .serializers import (
    TwoFactorMethodSerializer,
    TwoFactorOTPSerializer,
    RequestOTPSerializer,
    VerifyOTPSerializer,
    SetupTwoFactorSerializer,
    TwoFactorBackupCodeSerializer,
)
from .services import SMSService, EmailService
from .throttling import GeneralUserThrottle

logger = logging.getLogger(__name__)


class RequestOTPView(APIView):
    """Request OTP for 2FA verification"""
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [GeneralUserThrottle]

    def post(self, request):
        serializer = RequestOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        method_type = serializer.validated_data['method_type']
        user = request.user

        # Get or create 2FA method
        two_fa_method, _ = TwoFactorMethod.objects.get_or_create(
            user=user,
            defaults={'method_type': method_type}
        )

        if method_type == 'sms':
            phone_number = serializer.validated_data.get('phone_number')
            if not phone_number:
                phone_number = two_fa_method.phone_number
            
            if not phone_number:
                return Response(
                    {'error': 'Phone number is required for SMS 2FA.'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            recipient = phone_number
            two_fa_method.phone_number = phone_number

        else:  # email
            recipient = user.email

        # Generate OTP
        code = TwoFactorOTP.generate_code()
        otp = TwoFactorOTP.objects.create(
            user=user,
            code=code,
            method_type=method_type,
            recipient=recipient,
            expires_at=timezone.now() + timedelta(minutes=10)
        )

        # Send OTP
        if method_type == 'sms':
            result = SMSService.send_otp(recipient, code)
            if not result.get('success'):
                otp.status = 'failed'
                otp.save()
                return Response(
                    {'error': f"Failed to send SMS: {result.get('error', 'Unknown error')}"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        else:  # email
            result = EmailService.send_otp(recipient, code)
            if not result.get('success'):
                otp.status = 'failed'
                otp.save()
                return Response(
                    {'error': f"Failed to send email: {result.get('error', 'Unknown error')}"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

        two_fa_method.save()

        return Response({
            'message': f'OTP sent to {method_type}',
            'method_type': method_type,
            'recipient': self._mask_recipient(recipient, method_type),
            'expires_in_minutes': 10,
            'otp_id': otp.id
        })

    def _mask_recipient(self, recipient, method_type):
        """Mask recipient for privacy"""
        if method_type == 'sms':
            return recipient[-4:].rjust(len(recipient), '*')
        else:  # email
            parts = recipient.split('@')
            masked_local = parts[0][0] + '*' * (len(parts[0]) - 2) + parts[0][-1]
            return f"{masked_local}@{parts[1]}"

    def get_client_ip(self):
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip


class VerifyOTPView(APIView):
    """Verify OTP for 2FA"""
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [GeneralUserThrottle]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        code = serializer.validated_data['code']
        user = request.user

        # Get the most recent pending OTP
        otp = TwoFactorOTP.objects.filter(
            user=user,
            status='pending'
        ).order_by('-created_at').first()

        if not otp:
            return Response(
                {'error': 'No pending OTP found. Request a new one.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Verify the code
        if not otp.verify(code):
            remaining_attempts = otp.max_attempts - otp.attempts
            return Response(
                {
                    'error': 'Invalid OTP code.',
                    'remaining_attempts': max(0, remaining_attempts)
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Update 2FA method
        two_fa_method, _ = TwoFactorMethod.objects.get_or_create(user=user)
        two_fa_method.method_type = otp.method_type
        if otp.method_type == 'sms':
            two_fa_method.phone_number = otp.recipient
        two_fa_method.enabled = True
        two_fa_method.save()

        # Log audit
        AuditLog.objects.create(
            user=user,
            action='profile_update',
            description=f'2FA verified via {otp.method_type}',
            ip_address=self.get_client_ip()
        )

        return Response({
            'message': '2FA verified successfully!',
            'otp': TwoFactorOTPSerializer(otp).data
        })

    def get_client_ip(self):
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip


class SetupTwoFactorView(APIView):
    """Setup 2FA for user"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get current 2FA setup status"""
        try:
            two_fa = TwoFactorMethod.objects.get(user=request.user)
            serializer = TwoFactorMethodSerializer(two_fa)
            return Response(serializer.data)
        except TwoFactorMethod.DoesNotExist:
            return Response({
                'method_type': None,
                'enabled': False,
                'backup_codes_count': 0
            })

    def post(self, request):
        """Setup or update 2FA method"""
        serializer = SetupTwoFactorSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        method_type = serializer.validated_data['method_type']
        user = request.user

        two_fa_method, created = TwoFactorMethod.objects.get_or_create(user=user)
        two_fa_method.method_type = method_type

        if method_type == 'sms':
            phone_number = serializer.validated_data.get('phone_number')
            if not phone_number:
                return Response(
                    {'error': 'Phone number is required for SMS 2FA.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            two_fa_method.phone_number = phone_number

        two_fa_method.save()

        # Log audit
        from .models_auth import AuditLog
        AuditLog.objects.create(
            user=user,
            action='profile_update',
            description=f'2FA setup initiated with {method_type}',
            ip_address=self.get_client_ip()
        )

        return Response({
            'message': f'2FA method set to {method_type}. Please verify by requesting an OTP.',
            'method': TwoFactorMethodSerializer(two_fa_method).data
        })

    def delete(self, request):
        """Disable 2FA"""
        try:
            two_fa = TwoFactorMethod.objects.get(user=request.user)
            two_fa.enabled = False
            two_fa.save()

            # Log audit
            from .models_auth import AuditLog
            AuditLog.objects.create(
                user=request.user,
                action='profile_update',
                description='2FA disabled',
                ip_address=self.get_client_ip()
            )

            return Response({'message': '2FA has been disabled.'})
        except TwoFactorMethod.DoesNotExist:
            return Response(
                {'error': '2FA is not set up for this account.'},
                status=status.HTTP_404_NOT_FOUND
            )

    def get_client_ip(self):
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip


class BackupCodesView(APIView):
    """Manage backup codes for 2FA recovery"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get unused backup codes"""
        backup_codes = TwoFactorBackupCode.objects.filter(
            user=request.user,
            used=False
        ).order_by('-created_at')

        serializer = TwoFactorBackupCodeSerializer(backup_codes, many=True)
        return Response({
            'count': len(backup_codes),
            'codes': serializer.data
        })

    def post(self, request):
        """Generate new backup codes"""
        # Delete old codes
        TwoFactorBackupCode.objects.filter(user=request.user).delete()

        # Generate new codes
        codes = TwoFactorBackupCode.generate_codes(10)
        backup_code_objs = [
            TwoFactorBackupCode(user=request.user, code=code)
            for code in codes
        ]
        TwoFactorBackupCode.objects.bulk_create(backup_code_objs)

        # Log audit
        AuditLog.objects.create(
            user=request.user,
            action='profile_update',
            description='Generated new 2FA backup codes',
            ip_address=self.get_client_ip()
        )

        return Response({
            'message': 'New backup codes generated. Save them in a safe place.',
            'codes': codes,
            'warning': 'Each code can only be used once. Keep them safe!'
        }, status=status.HTTP_201_CREATED)

    def get_client_ip(self):
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip


class VerifyBackupCodeView(APIView):
    """Verify backup code for 2FA recovery"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        """Use backup code to verify identity"""
        code = request.data.get('code', '').strip()

        if not code:
            return Response(
                {'error': 'Backup code is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        backup_code = TwoFactorBackupCode.objects.filter(
            user=request.user,
            code=code,
            used=False
        ).first()

        if not backup_code:
            return Response(
                {'error': 'Invalid or already used backup code.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Mark as used
        backup_code.use()

        # Log audit
        AuditLog.objects.create(
            user=request.user,
            action='profile_update',
            description='Used backup code for 2FA recovery',
            ip_address=self.get_client_ip()
        )

        return Response({
            'message': 'Backup code verified successfully.',
            'remaining_codes': TwoFactorBackupCode.objects.filter(
                user=request.user,
                used=False
            ).count()
        })

    def get_client_ip(self):
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = self.request.META.get('REMOTE_ADDR')
        return ip
