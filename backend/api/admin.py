from django.contrib import admin
from django.contrib.auth.models import User
from django.utils.html import format_html

from .models import (
    EmergencyAlert, 
    EmergencyContact, 
    EmergencyNotification, 
    EmergencyService, 
    SearchHistory
)


# ============================================================
# EMERGENCY SERVICE ADMIN
# ============================================================

@admin.register(EmergencyService)
class EmergencyServiceAdmin(admin.ModelAdmin):
    list_display  = (
        "name", "category_badge", "address_short",
        "phone", "status_badge", "is_active", "created_at",
    )
    list_filter   = ("category", "status", "is_active")
    search_fields = ("name", "address", "phone")
    ordering      = ("category", "name")
    list_editable = ("is_active",)
    list_per_page = 30

    fieldsets = (
        ("Service Details", {
            "fields": ("name", "category", "address", "phone", "status", "is_active"),
        }),
        ("Location", {
            "fields": ("latitude", "longitude"),
            "description": "Decimal degrees — e.g. 19.0760, 72.8777",
        }),
        ("Timestamps", {
            "fields": ("created_at", "updated_at"),
            "classes": ("collapse",),
        }),
    )
    readonly_fields = ("created_at", "updated_at")

    # ── Custom display helpers ──

    @admin.display(description="Category")
    def category_badge(self, obj):
        colours = {
            "Hospital":     "#dc2626",
            "Ambulance":    "#ea580c", 
            "Police":       "#2563eb",
            "Fire Station": "#d97706",
            "Pharmacy":     "#16a34a",
            "Plumber":      "#8b5cf6",
            "Electrician":  "#f59e0b",
            "Mechanic":     "#6b7280",
            "Locksmith":    "#84cc16",
            "Cleaning":     "#06b6d4",
            "Taxi":         "#eab308",
            "Towing":       "#ef4444",
            "Veterinary":   "#10b981",
        }
        colour = colours.get(obj.category, "#64748b")
        return format_html(
            '<span style="'
            'background:{c};color:#fff;padding:2px 10px;'
            'border-radius:12px;font-size:11px;font-weight:600">'
            "{label}</span>",
            c=colour,
            label=obj.category,
        )

    @admin.display(description="Address")
    def address_short(self, obj):
        return obj.address[:60] + ("…" if len(obj.address) > 60 else "")

    @admin.display(description="Status")
    def status_badge(self, obj):
        colours = {
            "Open 24 hours": "#16a34a",
            "Available":     "#16a34a",
            "Open now":      "#0891b2",
            "Closed":        "#dc2626",
        }
        colour = colours.get(obj.status, "#64748b")
        return format_html(
            '<span style="color:{c};font-weight:600;font-size:12px">{s}</span>',
            c=colour, s=obj.status,
        )

    # ── Actions ──

    @admin.action(description="Mark selected as Active")
    def make_active(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f"{updated} service(s) marked as active.")

    @admin.action(description="Mark selected as Inactive")
    def make_inactive(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f"{updated} service(s) marked as inactive.")

    actions = [make_active, make_inactive]


# ============================================================
# SEARCH HISTORY ADMIN
# ============================================================

@admin.register(SearchHistory)
class SearchHistoryAdmin(admin.ModelAdmin):
    list_display  = (
        "user", "type_badge", "destination_name",
        "distance_km_display", "created_at",
    )
    list_filter   = ("search_type", "created_at")
    search_fields = ("user__username", "user__email", "destination_name", "query")
    ordering      = ("-created_at",)
    readonly_fields = (
        "user", "search_type", "query",
        "destination_name", "destination_address",
        "category", "latitude", "longitude",
        "distance_meters", "duration_seconds", "created_at",
    )
    list_per_page = 40

    @admin.display(description="Type")
    def type_badge(self, obj):
        colour = "#dc2626" if obj.search_type == "emergency" else "#2563eb"
        label  = obj.search_type.capitalize()
        return format_html(
            '<span style="'
            'background:{c};color:#fff;padding:2px 9px;'
            'border-radius:12px;font-size:11px;font-weight:600">'
            "{l}</span>",
            c=colour, l=label,
        )

    @admin.display(description="Distance")
    def distance_km_display(self, obj):
        if obj.distance_meters:
            km = obj.distance_meters / 1000
            return f"{km:.1f} km"
        return "—"

    # ── Actions ──

    @admin.action(description="Delete selected history entries")
    def delete_selected_history(self, request, queryset):
        count = queryset.count()
        queryset.delete()
        self.message_user(request, f"Deleted {count} history entry/entries.")

    actions = ["delete_selected_history"]


# ============================================================
# EMERGENCY CONTACT ADMIN
# ============================================================

@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display  = (
        "name", "user", "relationship",
        "phone", "primary_badge", "created_at",
    )
    list_filter   = ("is_primary", "relationship")
    search_fields = ("name", "phone", "user__username", "user__email")
    ordering      = ("-is_primary", "-created_at")
    readonly_fields = ("created_at",)
    list_per_page = 40

    @admin.display(description="Primary")
    def primary_badge(self, obj):
        if obj.is_primary:
            return format_html(
                '<span style="'
                'background:#16a34a;color:#fff;padding:2px 9px;'
                'border-radius:12px;font-size:11px;font-weight:600">'
                "✓ Primary</span>"
            )
        return format_html('<span style="color:#94a3b8;font-size:12px">—</span>')


# ============================================================
# EMERGENCY ALERT ADMIN
# ============================================================

@admin.register(EmergencyAlert)
class EmergencyAlertAdmin(admin.ModelAdmin):
    list_display = (
        "user", "alert_type_badge", "status_badge", 
        "message_short", "address_short", "created_at",
    )
    list_filter = ("alert_type", "status", "created_at")
    search_fields = ("user__username", "user__email", "message", "address")
    ordering = ("-created_at",)
    readonly_fields = ("created_at",)
    list_per_page = 30

    fieldsets = (
        ("Alert Details", {
            "fields": ("user", "alert_type", "status", "message"),
        }),
        ("Location", {
            "fields": ("latitude", "longitude", "address"),
        }),
        ("Timestamps", {
            "fields": ("created_at", "resolved_at"),
        }),
    )

    @admin.display(description="Type")
    def alert_type_badge(self, obj):
        colours = {
            "sos": "#dc2626",
            "medical": "#ea580c",
            "accident": "#d97706", 
            "safety": "#2563eb",
            "custom": "#64748b",
        }
        colour = colours.get(obj.alert_type, "#64748b")
        return format_html(
            '<span style="'
            'background:{c};color:#fff;padding:2px 9px;'
            'border-radius:12px;font-size:11px;font-weight:600">'
            "{label}</span>",
            c=colour,
            label=obj.alert_type.upper(),
        )

    @admin.display(description="Status")
    def status_badge(self, obj):
        colours = {
            "active": "#dc2626",
            "resolved": "#16a34a",
            "cancelled": "#64748b",
        }
        colour = colours.get(obj.status, "#64748b")
        return format_html(
            '<span style="color:{c};font-weight:600;font-size:12px">{s}</span>',
            c=colour, s=obj.status.capitalize(),
        )

    @admin.display(description="Message")
    def message_short(self, obj):
        if obj.message:
            return obj.message[:50] + ("…" if len(obj.message) > 50 else "")
        return "—"

    @admin.display(description="Address")
    def address_short(self, obj):
        if obj.address:
            return obj.address[:40] + ("…" if len(obj.address) > 40 else "")
        return "—"


# ============================================================
# EMERGENCY NOTIFICATION ADMIN
# ============================================================

@admin.register(EmergencyNotification)
class EmergencyNotificationAdmin(admin.ModelAdmin):
    list_display = (
        "emergency_contact", "alert_type_display", "notification_type_badge",
        "status_badge", "recipient", "sent_at",
    )
    list_filter = ("notification_type", "status", "sent_at")
    search_fields = (
        "emergency_contact__name", "emergency_contact__phone",
        "recipient", "message",
    )
    ordering = ("-created_at",)
    readonly_fields = ("created_at",)
    list_per_page = 40

    @admin.display(description="Alert Type")
    def alert_type_display(self, obj):
        return obj.emergency_alert.alert_type.upper()

    @admin.display(description="Type")
    def notification_type_badge(self, obj):
        colours = {
            "sms": "#16a34a",
            "email": "#2563eb",
            "push": "#8b5cf6",
        }
        colour = colours.get(obj.notification_type, "#64748b")
        return format_html(
            '<span style="'
            'background:{c};color:#fff;padding:2px 9px;'
            'border-radius:12px;font-size:11px;font-weight:600">'
            "{label}</span>",
            c=colour,
            label=obj.notification_type.upper(),
        )

    @admin.display(description="Status")
    def status_badge(self, obj):
        colours = {
            "pending": "#d97706",
            "sent": "#16a34a",
            "failed": "#dc2626",
            "delivered": "#059669",
        }
        colour = colours.get(obj.status, "#64748b")
        return format_html(
            '<span style="color:{c};font-weight:600;font-size:12px">{s}</span>',
            c=colour, s=obj.status.capitalize(),
        )


# ============================================================
# SITE HEADER
# ============================================================

admin.site.site_header  = "ResQNav Administration"
admin.site.site_title   = "ResQNav Admin"
admin.site.index_title  = "ResQNav Dashboard"
