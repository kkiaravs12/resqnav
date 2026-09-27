from django.core.management.base import BaseCommand

from api.models import EmergencyService


# ============================================================
# COMPREHENSIVE SEED DATA — Mumbai + Pune + Delhi + Bangalore
# ============================================================

SERVICES = [
    # ──────────────────────────────────────────────────────────
    # HOSPITALS — Mumbai
    # ──────────────────────────────────────────────────────────
    {
        "name": "Lilavati Hospital & Research Centre",
        "category": "Hospital",
        "address": "A-791, Bandra Reclamation, Bandra West, Mumbai 400050",
        "phone": "+91 22 6931 0000",
        "latitude": 19.0509,
        "longitude": 72.8293,
        "status": "Open 24 hours",
    },
    {
        "name": "Kokilaben Dhirubhai Ambani Hospital",
        "category": "Hospital",
        "address": "Four Bungalows, Andheri West, Mumbai 400053",
        "phone": "+91 22 4269 6969",
        "latitude": 19.1364,
        "longitude": 72.8273,
        "status": "Open 24 hours",
    },
    {
        "name": "Nanavati Max Super Speciality Hospital",
        "category": "Hospital",
        "address": "S V Road, Vile Parle West, Mumbai 400056",
        "phone": "+91 22 2626 7500",
        "latitude": 19.0957,
        "longitude": 72.8424,
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
        "latitude": 19.0330,
        "longitude": 72.8397,
        "status": "Open 24 hours",
    },
    {
        "name": "Breach Candy Hospital",
        "category": "Hospital",
        "address": "60-A, Bhulabhai Desai Road, Mumbai 400026",
        "phone": "+91 22 2366 7878",
        "latitude": 18.9694,
        "longitude": 72.8074,
        "status": "Open 24 hours",
    },
    {
        "name": "Holy Family Hospital",
        "category": "Hospital",
        "address": "St Andrew's Road, Bandra West, Mumbai 400050",
        "phone": "+91 22 6650 3333",
        "latitude": 19.0563,
        "longitude": 72.8383,
        "status": "Open 24 hours",
    },
    {
        "name": "Jaslok Hospital & Research Centre",
        "category": "Hospital",
        "address": "15, Dr G Deshmukh Marg, Pedder Road, Mumbai 400026",
        "phone": "+91 22 6657 3333",
        "latitude": 18.9720,
        "longitude": 72.8087,
        "status": "Open 24 hours",
    },
    {
        "name": "Sir H. N. Reliance Foundation Hospital",
        "category": "Hospital",
        "address": "Raja Ram Mohan Roy Road, Girgaon, Mumbai 400004",
        "phone": "+91 22 6766 1000",
        "latitude": 18.9547,
        "longitude": 72.8173,
        "status": "Open 24 hours",
    },
    {
        "name": "Wockhardt Hospital (Mumbai Central)",
        "category": "Hospital",
        "address": "1877, Dr Anand Rao Nair Road, Mumbai Central, Mumbai 400011",
        "phone": "+91 22 6178 8000",
        "latitude": 18.9693,
        "longitude": 72.8261,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # AMBULANCE — Mumbai
    # ──────────────────────────────────────────────────────────
    {
        "name": "ResQ Ambulance Point – Bandra",
        "category": "Ambulance",
        "address": "SV Road, Bandra West, Mumbai 400050",
        "phone": "108",
        "latitude": 19.0596,
        "longitude": 72.8295,
        "status": "Available",
    },
    {
        "name": "Emergency Ambulance Unit – Andheri",
        "category": "Ambulance",
        "address": "JB Nagar, Andheri East, Mumbai 400059",
        "phone": "108",
        "latitude": 19.1197,
        "longitude": 72.8697,
        "status": "Available",
    },
    {
        "name": "Rapid Medical Response – Dadar",
        "category": "Ambulance",
        "address": "Gokhale Road, Dadar West, Mumbai 400028",
        "phone": "108",
        "latitude": 19.0178,
        "longitude": 72.8478,
        "status": "Available",
    },
    {
        "name": "Ziqitza Healthcare Ambulance – Borivali",
        "category": "Ambulance",
        "address": "SV Road, Borivali West, Mumbai 400092",
        "phone": "1298",
        "latitude": 19.2307,
        "longitude": 72.8567,
        "status": "Available",
    },
    # ──────────────────────────────────────────────────────────
    # POLICE — Mumbai
    # ──────────────────────────────────────────────────────────
    {
        "name": "Bandra Police Station",
        "category": "Police",
        "address": "SV Road, Bandra West, Mumbai 400050",
        "phone": "100",
        "latitude": 19.0540,
        "longitude": 72.8317,
        "status": "Open 24 hours",
    },
    {
        "name": "Andheri Police Station",
        "category": "Police",
        "address": "Veera Desai Road, Andheri West, Mumbai 400053",
        "phone": "100",
        "latitude": 19.1190,
        "longitude": 72.8463,
        "status": "Open 24 hours",
    },
    {
        "name": "Dadar Police Station",
        "category": "Police",
        "address": "Raja Ram Mohan Roy Road, Dadar West, Mumbai 400028",
        "phone": "100",
        "latitude": 19.0192,
        "longitude": 72.8391,
        "status": "Open 24 hours",
    },
    {
        "name": "Colaba Police Station",
        "category": "Police",
        "address": "Cuffe Parade, Colaba, Mumbai 400005",
        "phone": "100",
        "latitude": 18.9123,
        "longitude": 72.8227,
        "status": "Open 24 hours",
    },
    {
        "name": "Kurla Police Station",
        "category": "Police",
        "address": "LBS Marg, Kurla West, Mumbai 400070",
        "phone": "100",
        "latitude": 19.0726,
        "longitude": 72.8792,
        "status": "Open 24 hours",
    },
    {
        "name": "Borivali Police Station",
        "category": "Police",
        "address": "SV Road, Borivali West, Mumbai 400092",
        "phone": "100",
        "latitude": 19.2294,
        "longitude": 72.8560,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # FIRE STATIONS — Mumbai
    # ──────────────────────────────────────────────────────────
    {
        "name": "Bandra Fire Station",
        "category": "Fire Station",
        "address": "SV Road, Bandra West, Mumbai 400050",
        "phone": "101",
        "latitude": 19.0578,
        "longitude": 72.8265,
        "status": "Open 24 hours",
    },
    {
        "name": "Andheri Fire Station",
        "category": "Fire Station",
        "address": "Mahakali Caves Road, Andheri East, Mumbai 400093",
        "phone": "101",
        "latitude": 19.1184,
        "longitude": 72.8630,
        "status": "Open 24 hours",
    },
    {
        "name": "Dadar Fire Station",
        "category": "Fire Station",
        "address": "Gokhale Road South, Dadar West, Mumbai 400028",
        "phone": "101",
        "latitude": 19.0128,
        "longitude": 72.8443,
        "status": "Open 24 hours",
    },
    {
        "name": "Borivali Fire Station",
        "category": "Fire Station",
        "address": "SV Road, Borivali West, Mumbai 400092",
        "phone": "101",
        "latitude": 19.2281,
        "longitude": 72.8545,
        "status": "Open 24 hours",
    },
    {
        "name": "Worli Fire Station",
        "category": "Fire Station",
        "address": "NS Patkar Marg, Worli, Mumbai 400018",
        "phone": "101",
        "latitude": 19.0038,
        "longitude": 72.8173,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # PHARMACIES — Mumbai
    # ──────────────────────────────────────────────────────────
    {
        "name": "Apollo Pharmacy – Bandra West",
        "category": "Pharmacy",
        "address": "Linking Road, Bandra West, Mumbai 400050",
        "phone": "+91 22 2604 2211",
        "latitude": 19.0571,
        "longitude": 72.8301,
        "status": "Open now",
    },
    {
        "name": "Wellness Forever – Andheri West",
        "category": "Pharmacy",
        "address": "Andheri West, Mumbai 400058",
        "phone": "+91 22 4011 2200",
        "latitude": 19.1304,
        "longitude": 72.8354,
        "status": "Open now",
    },
    {
        "name": "Tata 1mg Pharmacy – Dadar West",
        "category": "Pharmacy",
        "address": "Gokhale Road, Dadar West, Mumbai 400028",
        "phone": "+91 22 2431 9000",
        "latitude": 19.0215,
        "longitude": 72.8427,
        "status": "Open now",
    },
    {
        "name": "MedPlus Pharmacy – Borivali",
        "category": "Pharmacy",
        "address": "SV Road, Borivali West, Mumbai 400092",
        "phone": "+91 22 2898 3456",
        "latitude": 19.2315,
        "longitude": 72.8572,
        "status": "Open now",
    },
    {
        "name": "Noble Chemist – Colaba",
        "category": "Pharmacy",
        "address": "Colaba Causeway, Mumbai 400005",
        "phone": "+91 22 2283 1001",
        "latitude": 18.9208,
        "longitude": 72.8313,
        "status": "Open now",
    },
    # ──────────────────────────────────────────────────────────
    # HOSPITALS — Pune
    # ──────────────────────────────────────────────────────────
    {
        "name": "Ruby Hall Clinic",
        "category": "Hospital",
        "address": "40, Sassoon Road, Pune 411001",
        "phone": "+91 20 6645 5555",
        "latitude": 18.5346,
        "longitude": 73.8836,
        "status": "Open 24 hours",
    },
    {
        "name": "Jehangir Hospital",
        "category": "Hospital",
        "address": "32, Sassoon Road, Pune 411001",
        "phone": "+91 20 6681 5000",
        "latitude": 18.5329,
        "longitude": 73.8818,
        "status": "Open 24 hours",
    },
    {
        "name": "Deenanath Mangeshkar Hospital",
        "category": "Hospital",
        "address": "Erandwane, Pune 411004",
        "phone": "+91 20 4015 1000",
        "latitude": 18.5148,
        "longitude": 73.8238,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # POLICE — Pune
    # ──────────────────────────────────────────────────────────
    {
        "name": "Shivajinagar Police Station",
        "category": "Police",
        "address": "Shivajinagar, Pune 411005",
        "phone": "100",
        "latitude": 18.5308,
        "longitude": 73.8474,
        "status": "Open 24 hours",
    },
    {
        "name": "Pune Camp Police Station",
        "category": "Police",
        "address": "MG Road, Camp, Pune 411001",
        "phone": "100",
        "latitude": 18.5188,
        "longitude": 73.8798,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # FIRE — Pune
    # ──────────────────────────────────────────────────────────
    {
        "name": "Pune Fire Brigade – Headquarters",
        "category": "Fire Station",
        "address": "Shivajinagar, Pune 411005",
        "phone": "101",
        "latitude": 18.5305,
        "longitude": 73.8459,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # AMBULANCE — Pune
    # ──────────────────────────────────────────────────────────
    {
        "name": "Pune Emergency Ambulance",
        "category": "Ambulance",
        "address": "Shivajinagar, Pune 411005",
        "phone": "108",
        "latitude": 18.5286,
        "longitude": 73.8461,
        "status": "Available",
    },
    # ──────────────────────────────────────────────────────────
    # HOSPITALS — Delhi
    # ──────────────────────────────────────────────────────────
    {
        "name": "AIIMS New Delhi",
        "category": "Hospital",
        "address": "Ansari Nagar East, New Delhi 110029",
        "phone": "+91 11 2658 8500",
        "latitude": 28.5672,
        "longitude": 77.2100,
        "status": "Open 24 hours",
    },
    {
        "name": "Safdarjung Hospital",
        "category": "Hospital",
        "address": "Ansari Nagar West, New Delhi 110029",
        "phone": "+91 11 2616 5060",
        "latitude": 28.5683,
        "longitude": 77.2067,
        "status": "Open 24 hours",
    },
    {
        "name": "Apollo Hospital – Sarita Vihar",
        "category": "Hospital",
        "address": "Mathura Road, Sarita Vihar, New Delhi 110044",
        "phone": "+91 11 2692 5858",
        "latitude": 28.5289,
        "longitude": 77.2919,
        "status": "Open 24 hours",
    },
    {
        "name": "Fortis Escorts Heart Institute",
        "category": "Hospital",
        "address": "Okhla Road, New Delhi 110025",
        "phone": "+91 11 4713 5000",
        "latitude": 28.5621,
        "longitude": 77.2757,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # POLICE — Delhi
    # ──────────────────────────────────────────────────────────
    {
        "name": "Connaught Place Police Station",
        "category": "Police",
        "address": "Connaught Place, New Delhi 110001",
        "phone": "100",
        "latitude": 28.6329,
        "longitude": 77.2195,
        "status": "Open 24 hours",
    },
    {
        "name": "Lajpat Nagar Police Station",
        "category": "Police",
        "address": "Lajpat Nagar, New Delhi 110024",
        "phone": "100",
        "latitude": 28.5659,
        "longitude": 77.2430,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # FIRE — Delhi
    # ──────────────────────────────────────────────────────────
    {
        "name": "Delhi Fire Service – Connaught Place",
        "category": "Fire Station",
        "address": "Barakhamba Road, New Delhi 110001",
        "phone": "101",
        "latitude": 28.6317,
        "longitude": 77.2241,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # AMBULANCE — Delhi
    # ──────────────────────────────────────────────────────────
    {
        "name": "Delhi Ambulance Service",
        "category": "Ambulance",
        "address": "Connaught Place, New Delhi 110001",
        "phone": "108",
        "latitude": 28.6320,
        "longitude": 77.2190,
        "status": "Available",
    },
    # ──────────────────────────────────────────────────────────
    # HOSPITALS — Bangalore
    # ──────────────────────────────────────────────────────────
    {
        "name": "Manipal Hospital – Old Airport Road",
        "category": "Hospital",
        "address": "98, HAL Airport Road, Bangalore 560017",
        "phone": "+91 80 2502 4444",
        "latitude": 12.9698,
        "longitude": 77.6498,
        "status": "Open 24 hours",
    },
    {
        "name": "Fortis Hospital – Bannerghatta Road",
        "category": "Hospital",
        "address": "154/9, Bannerghatta Road, Bangalore 560076",
        "phone": "+91 80 6621 4444",
        "latitude": 12.8888,
        "longitude": 77.5976,
        "status": "Open 24 hours",
    },
    {
        "name": "Victoria Hospital",
        "category": "Hospital",
        "address": "Fort Road, Bangalore 560002",
        "phone": "+91 80 2670 1150",
        "latitude": 12.9628,
        "longitude": 77.5700,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # POLICE — Bangalore
    # ──────────────────────────────────────────────────────────
    {
        "name": "MG Road Police Station",
        "category": "Police",
        "address": "MG Road, Bangalore 560001",
        "phone": "100",
        "latitude": 12.9756,
        "longitude": 77.6094,
        "status": "Open 24 hours",
    },
    {
        "name": "Electronic City Police Station",
        "category": "Police",
        "address": "Electronic City Phase 1, Bangalore 560100",
        "phone": "100",
        "latitude": 12.8395,
        "longitude": 77.6770,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # FIRE — Bangalore
    # ──────────────────────────────────────────────────────────
    {
        "name": "Bangalore Fire Station – Shivajinagar",
        "category": "Fire Station",
        "address": "Shivajinagar, Bangalore 560001",
        "phone": "101",
        "latitude": 12.9864,
        "longitude": 77.5979,
        "status": "Open 24 hours",
    },
    # ──────────────────────────────────────────────────────────
    # AMBULANCE — Bangalore
    # ──────────────────────────────────────────────────────────
    {
        "name": "Bangalore Emergency Ambulance",
        "category": "Ambulance",
        "address": "Shivajinagar, Bangalore 560001",
        "phone": "108",
        "latitude": 12.9852,
        "longitude": 77.5968,
        "status": "Available",
    },
    # ──────────────────────────────────────────────────────────
    # PHARMACIES — Delhi & Bangalore
    # ──────────────────────────────────────────────────────────
    {
        "name": "Apollo Pharmacy – Connaught Place",
        "category": "Pharmacy",
        "address": "Connaught Place, New Delhi 110001",
        "phone": "+91 11 2336 5000",
        "latitude": 28.6330,
        "longitude": 77.2197,
        "status": "Open now",
    },
    {
        "name": "MedPlus Pharmacy – MG Road Bangalore",
        "category": "Pharmacy",
        "address": "MG Road, Bangalore 560001",
        "phone": "+91 80 4112 3456",
        "latitude": 12.9753,
        "longitude": 77.6090,
        "status": "Open now",
    },
    {
        "name": "Wellness Forever – Pune Camp",
        "category": "Pharmacy",
        "address": "MG Road, Camp, Pune 411001",
        "phone": "+91 20 2612 3300",
        "latitude": 18.5190,
        "longitude": 73.8794,
        "status": "Open now",
    },
    # ──────────────────────────────────────────────────────────
    # HOME SERVICES — Mumbai
    # ──────────────────────────────────────────────────────────
    {
        "name": "Mumbai Plumbing Solutions",
        "category": "Plumber",
        "address": "Bandra West, Mumbai 400050",
        "phone": "+91 22 2604 5678",
        "latitude": 19.0596,
        "longitude": 72.8295,
        "status": "Available",
    },
    {
        "name": "QuickFix Plumber Service",
        "category": "Plumber",
        "address": "Andheri West, Mumbai 400053", 
        "phone": "+91 22 2674 9999",
        "latitude": 19.1136,
        "longitude": 72.8697,
        "status": "Open 24 hours",
    },
    {
        "name": "PowerTech Electricians",
        "category": "Electrician",
        "address": "Dadar West, Mumbai 400028",
        "phone": "+91 22 2430 8888",
        "latitude": 19.0178,
        "longitude": 72.8478,
        "status": "Available",
    },
    {
        "name": "Mumbai Auto Mechanic", 
        "category": "Mechanic",
        "address": "Kurla West, Mumbai 400070",
        "phone": "+91 22 2511 3456",
        "latitude": 19.0726,
        "longitude": 72.8792,
        "status": "Open now",
    },
    {
        "name": "24x7 Locksmith Mumbai",
        "category": "Locksmith",
        "address": "Colaba, Mumbai 400005",
        "phone": "+91 22 2283 7777",
        "latitude": 18.9123,
        "longitude": 72.8227,
        "status": "Open 24 hours",
    },
]


class Command(BaseCommand):
    help = "Seed ResQNav emergency services (Mumbai, Pune, Delhi, Bangalore)"

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
                defaults=service,
            )
            if was_created:
                created += 1
            else:
                updated += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"✓ Emergency services seeded. "
                f"Created: {created}, Updated: {updated}, Total: {created + updated}"
            )
        )
