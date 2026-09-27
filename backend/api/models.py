from django.conf import settings
from django.db import models


class EmergencyAlert(models.Model):
    class AlertType(models.TextChoices):
        SOS = "sos", "SOS Emergency"
        MEDICAL = "medical", "Medical Emergency"
        ACCIDENT = "accident", "Accident"
        SAFETY = "safety", "Safety Emergency"
        CUSTOM = "custom", "Custom"
    
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        RESOLVED = "resolved", "Resolved"
        CANCELLED = "cancelled", "Cancelled"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="emergency_alerts",
    )
    
    alert_type = models.CharField(
        max_length=20,
        choices=AlertType.choices,
        default=AlertType.SOS,
    )
    
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.ACTIVE,
    )
    
    message = models.TextField(blank=True)
    
    # Location when emergency was triggered
    latitude = models.FloatField(
        null=True,
        blank=True,
    )
    
    longitude = models.FloatField(
        null=True,
        blank=True,
    )
    
    address = models.CharField(max_length=500, blank=True)
    
    # Tracking
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.username} - {self.alert_type} - {self.status}"


class EmergencyNotification(models.Model):
    class NotificationType(models.TextChoices):
        SMS = "sms", "SMS"
        EMAIL = "email", "Email"
        PUSH = "push", "Push Notification"
    
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        SENT = "sent", "Sent"
        FAILED = "failed", "Failed"
        DELIVERED = "delivered", "Delivered"

    emergency_alert = models.ForeignKey(
        EmergencyAlert,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    
    emergency_contact = models.ForeignKey(
        'EmergencyContact',
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    
    notification_type = models.CharField(
        max_length=20,
        choices=NotificationType.choices,
    )
    
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
    )
    
    message = models.TextField()
    recipient = models.CharField(max_length=200)  # phone/email
    
    sent_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    error_message = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.emergency_contact.name} - {self.notification_type} - {self.status}"


class EmergencyService(models.Model):
    class Category(models.TextChoices):
        # Emergency Services
        HOSPITAL = "Hospital", "Hospital"
        AMBULANCE = "Ambulance", "Ambulance"
        POLICE = "Police", "Police"
        FIRE_STATION = "Fire Station", "Fire Station"
        PHARMACY = "Pharmacy", "Pharmacy"
        
        # Home Services
        PLUMBER = "Plumber", "Plumber"
        ELECTRICIAN = "Electrician", "Electrician"
        MECHANIC = "Mechanic", "Mechanic"
        CARPENTER = "Carpenter", "Carpenter"
        LOCKSMITH = "Locksmith", "Locksmith"
        CLEANING = "Cleaning", "Cleaning Service"
        PEST_CONTROL = "Pest Control", "Pest Control"
        
        # Professional Services
        TAXI = "Taxi", "Taxi"
        TOWING = "Towing", "Towing Service"
        VETERINARY = "Veterinary", "Veterinary"

    class Status(models.TextChoices):
        OPEN_24_HOURS = "Open 24 hours", "Open 24 hours"
        AVAILABLE = "Available", "Available"
        OPEN_NOW = "Open now", "Open now"
        CLOSED = "Closed", "Closed"

    name = models.CharField(max_length=200)
    category = models.CharField(
        max_length=30,
        choices=Category.choices,
    )
    address = models.CharField(max_length=300)
    phone = models.CharField(max_length=30)

    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
    )
    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
    )

    status = models.CharField(
        max_length=30,
        choices=Status.choices,
        default=Status.OPEN_NOW,
    )

    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.category})"


class SearchHistory(models.Model):
    class SearchType(models.TextChoices):
        DESTINATION = "destination", "Destination"
        EMERGENCY = "emergency", "Emergency"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="search_history",
    )

    search_type = models.CharField(
        max_length=20,
        choices=SearchType.choices,
    )

    query = models.CharField(
        max_length=255,
        blank=True,
    )

    destination_name = models.CharField(
        max_length=255,
        blank=True,
    )

    destination_address = models.CharField(
        max_length=500,
        blank=True,
    )

    category = models.CharField(
        max_length=30,
        blank=True,
    )

    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
    )

    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
    )

    distance_meters = models.FloatField(
        null=True,
        blank=True,
    )

    duration_seconds = models.FloatField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return (
            f"{self.user.username} - "
            f"{self.search_type} - "
            f"{self.destination_name or self.query}"
        )


class EmergencyContact(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="emergency_contacts",
    )
    name = models.CharField(max_length=150)
    relationship = models.CharField(
        max_length=50,
        blank=True,
        default="Family",
    )
    phone = models.CharField(max_length=30)
    is_primary = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-is_primary", "-created_at"]

    def __str__(self):
        return f"{self.name} ({self.relationship}) - {self.phone}"
