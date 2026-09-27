from django.core.management.base import BaseCommand

from api.models import EmergencyService


# ============================================================
# MATUNGA AREA EMERGENCY SERVICES - Mumbai
# ============================================================

SERVICES = [
    # ──────────────────────────────────────────────────────────
    # HOSPITALS — Matunga & Vikhroli
    # ──────────────────────────────────────────────────────────
    {
        "name": "Sion Hospital (Lokmanya Tilak Municipal General Hospital)",
        "category": "Hospital",
        "address": "Sion, Mumbai 400022",
        "phone": "+91 22 2407 6101",
        "latitude": 19.0433,
        "longitude": 72.8618,
        "status": "Open 24 hours",
    },
    {
        "name": "KEM Hospital & Trauma Centre",
        "category": "Hospital",
        "address": "Acharya Donde Marg, Parel, Mumbai 400012",
        "phone": "+91 22 2410 7000",
        "latitude": 19.0029,
        "longitude": 72.8428,
        "status": "Open 24 hours",
    },
    {
        "name": "P. D. Hinduja National Hospital",
        "category": "Hospital",
        "address": "Veer Savarkar Marg, Mahim, Mumbai 400016",
        "phone": "+91 22 2445 1515",
        "latitude": 19.0379,
        "longitude": 72.8405,
        "status": "Open 24 hours",
    },
    {
        "name": "Rajawadi Hospital",
        "category": "Hospital",
        "address": "Rajawadi, Ghatkopar East, Mumbai 400077",
        "phone": "+91 22 2501 8989",
        "latitude": 19.0863,
        "longitude": 72.9081,
        "status": "Open 24 hours",
    },
    {
        "name": "Fortis Hospital Mulund",
        "category": "Hospital",
        "address": "Mulund-Goregaon Link Road, Mulund West, Mumbai 400078",
        "phone": "+91 22 6754 7000",
        "latitude": 19.1716,
        "longitude": 72.9574,
        "status": "Open 24 hours",
    },
    {
        "name": "Fortis Hiranandani Hospital",
        "category": "Hospital",
        "address": "Hill Side Avenue, Hiranandani Gardens, Powai, Mumbai 400076",
        "phone": "+91 22 6746 7000",
        "latitude": 19.1208,
        "longitude": 72.9074,
        "status": "Open 24 hours",
    },
    {
        "name": "Agarwal Hospital - Vikhroli",
        "category": "Hospital",
        "address": "Vikhroli East, Mumbai 400083",
        "phone": "+91 22 2578 8989",
        "latitude": 19.1120,
        "longitude": 72.9430,
        "status": "Open 24 hours",
    },
    {
        "name": "Bhabha Hospital",
        "category": "Hospital",
        "address": "Hill Road, Bandra West, Mumbai 400050",
        "phone": "+91 22 2640 1767",
        "latitude": 19.0597,
        "longitude": 72.8295,
        "status": "Open 24 hours",
    },

    # ──────────────────────────────────────────────────────────
    # POLICE STATIONS — Matunga & Vikhroli
    # ──────────────────────────────────────────────────────────
    {
        "name": "Matunga Police Station",
        "category": "Police",
        "address": "Telang Road, Matunga East, Mumbai 400019",
        "phone": "+91 22 2414 9302",
        "latitude": 19.0286,
        "longitude": 72.8534,
        "status": "Open 24 hours",
    },
    {
        "name": "Vikhroli Police Station",
        "category": "Police",
        "address": "LBS Marg, Vikhroli West, Mumbai 400083",
        "phone": "+91 22 2577 4763",
        "latitude": 19.1090,
        "longitude": 72.9305,
        "status": "Open 24 hours",
    },
    {
        "name": "Parksite Police Station",
        "category": "Police",
        "address": "Parksite, Vikhroli East, Mumbai 400083",
        "phone": "+91 22 2578 2222",
        "latitude": 19.1125,
        "longitude": 72.9435,
        "status": "Open 24 hours",
    },
    {
        "name": "Dharavi Police Station",
        "category": "Police",
        "address": "90 Feet Road, Dharavi, Mumbai 400017",
        "phone": "+91 22 2402 8403",
        "latitude": 19.0467,
        "longitude": 72.8567,
        "status": "Open 24 hours",
    },
    {
        "name": "Mahim Police Station",
        "category": "Police",
        "address": "Veer Savarkar Marg, Mahim, Mumbai 400016",
        "phone": "+91 22 2444 4545",
        "latitude": 19.0381,
        "longitude": 72.8408,
        "status": "Open 24 hours",
    },
    {
        "name": "Dadar Police Station",
        "category": "Police",
        "address": "Tilak Bridge, Dadar, Mumbai 400014",
        "phone": "+91 22 2414 3714",
        "latitude": 19.0176,
        "longitude": 72.8442,
        "status": "Open 24 hours",
    },
    {
        "name": "Sion Police Station",
        "category": "Police",
        "address": "Sion Circle, Sion, Mumbai 400022",
        "phone": "+91 22 2407 6923",
        "latitude": 19.0433,
        "longitude": 72.8618,
        "status": "Open 24 hours",
    },

    # ──────────────────────────────────────────────────────────
    # FIRE STATIONS — Matunga & Vikhroli
    # ──────────────────────────────────────────────────────────
    {
        "name": "Matunga Fire Station",
        "category": "Fire Station",
        "address": "Lady Jamshedji Road, Mahim, Mumbai 400016",
        "phone": "101",
        "latitude": 19.0310,
        "longitude": 72.8456,
        "status": "Open 24 hours",
    },
    {
        "name": "Vikhroli Fire Station",
        "category": "Fire Station",
        "address": "LBS Marg, Vikhroli, Mumbai 400083",
        "phone": "101",
        "latitude": 19.1092,
        "longitude": 72.9308,
        "status": "Open 24 hours",
    },
    {
        "name": "Dadar Fire Station",
        "category": "Fire Station",
        "address": "Dadar, Mumbai 400028",
        "phone": "101",
        "latitude": 19.0188,
        "longitude": 72.8478,
        "status": "Open 24 hours",
    },
    {
        "name": "Mumbai Fire Brigade Headquarters",
        "category": "Fire Station",
        "address": "Byculla, Mumbai 400027",
        "phone": "+91 22 2373 5533",
        "latitude": 18.9771,
        "longitude": 72.8329,
        "status": "Open 24 hours",
    },

    # ──────────────────────────────────────────────────────────
    # AMBULANCE SERVICES — Matunga & Vikhroli
    # ──────────────────────────────────────────────────────────
    {
        "name": "108 Emergency Ambulance Service",
        "category": "Ambulance",
        "address": "Mumbai Region",
        "phone": "108",
        "latitude": 19.0280,
        "longitude": 72.8534,
        "status": "Open 24 hours",
    },
    {
        "name": "Ziqitza Healthcare Limited (ZHL) Ambulance",
        "category": "Ambulance",
        "address": "Mumbai",
        "phone": "+91 22 4141 0808",
        "latitude": 19.0760,
        "longitude": 72.8777,
        "status": "Open 24 hours",
    },
    {
        "name": "Red Cross Ambulance Service",
        "category": "Ambulance",
        "address": "Mumbai Red Cross, Fort, Mumbai",
        "phone": "+91 22 2262 2855",
        "latitude": 18.9388,
        "longitude": 72.8355,
        "status": "Open 24 hours",
    },

    # ──────────────────────────────────────────────────────────
    # PHARMACIES — Matunga & Vikhroli
    # ──────────────────────────────────────────────────────────
    {
        "name": "Apollo Pharmacy - Matunga",
        "category": "Pharmacy",
        "address": "King's Circle, Matunga, Mumbai 400019",
        "phone": "+91 22 2401 3456",
        "latitude": 19.0275,
        "longitude": 72.8520,
        "status": "Open 24 hours",
    },
    {
        "name": "MedPlus Pharmacy - Mahim",
        "category": "Pharmacy",
        "address": "Mahim Causeway, Mahim, Mumbai 400016",
        "phone": "+91 22 2446 7890",
        "latitude": 19.0382,
        "longitude": 72.8410,
        "status": "Open 24 hours",
    },
    {
        "name": "Wellness Forever - Dadar",
        "category": "Pharmacy",
        "address": "Dadar West, Mumbai 400028",
        "phone": "+91 22 2430 9876",
        "latitude": 19.0179,
        "longitude": 72.8431,
        "status": "9:00 AM - 11:00 PM",
    },
    {
        "name": "Apollo Pharmacy - Vikhroli",
        "category": "Pharmacy",
        "address": "Vikhroli West, Mumbai 400079",
        "phone": "+91 22 2577 1234",
        "latitude": 19.1084,
        "longitude": 72.9294,
        "status": "Open 24 hours",
    },
    {
        "name": "MedPlus - Vikhroli East",
        "category": "Pharmacy",
        "address": "Kannamwar Nagar, Vikhroli East, Mumbai 400083",
        "phone": "+91 22 2578 5678",
        "latitude": 19.1127,
        "longitude": 72.9437,
        "status": "8:00 AM - 11:00 PM",
    },

    # ──────────────────────────────────────────────────────────
    # MECHANICS — Matunga & Vikhroli (Emergency Vehicle Repair)
    # ──────────────────────────────────────────────────────────
    {
        "name": "24x7 Auto Repair - Matunga",
        "category": "Mechanic",
        "address": "LBS Marg, Matunga, Mumbai 400019",
        "phone": "+91 98208 12345",
        "latitude": 19.0270,
        "longitude": 72.8540,
        "status": "Open 24 hours",
    },
    {
        "name": "Emergency Roadside Assistance - Matunga",
        "category": "Mechanic",
        "address": "King's Circle, Matunga East, Mumbai 400019",
        "phone": "+91 98209 23456",
        "latitude": 19.0282,
        "longitude": 72.8528,
        "status": "Open 24 hours",
    },
    {
        "name": "Quick Fix Auto - Vikhroli",
        "category": "Mechanic",
        "address": "LBS Marg, Vikhroli West, Mumbai 400079",
        "phone": "+91 98210 34567",
        "latitude": 19.1085,
        "longitude": 72.9300,
        "status": "Open 24 hours",
    },
    {
        "name": "24/7 Vehicle Rescue - Vikhroli",
        "category": "Mechanic",
        "address": "Vikhroli East, Mumbai 400083",
        "phone": "+91 98211 45678",
        "latitude": 19.1130,
        "longitude": 72.9445,
        "status": "Open 24 hours",
    },
]


class Command(BaseCommand):
    help = "Seed emergency services for Matunga area"

    def add_arguments(self, parser):
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Clear existing services before seeding",
        )

    def handle(self, *args, **options):
        if options.get("clear"):
            deleted, _ = EmergencyService.objects.all().delete()
            self.stdout.write(self.style.WARNING(f"Cleared {deleted} existing services."))

        created = 0
        updated = 0

        for service in SERVICES:
            obj, was_created = EmergencyService.objects.update_or_create(
                name=service["name"],
                category=service["category"],
                defaults={
                    "address": service["address"],
                    "phone": service["phone"],
                    "latitude": service["latitude"],
                    "longitude": service["longitude"],
                    "status": service.get("status", "Open"),
                    "is_active": True,
                },
            )
            if was_created:
                created += 1
            else:
                updated += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"✓ Seeding complete: {created} created, {updated} updated."
            )
        )
