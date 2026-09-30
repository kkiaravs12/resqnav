import 'package:flutter/material.dart';

// ============================================================
// APP-WIDE CONSTANTS
// ============================================================

class AppConstants {
  AppConstants._();

  // ──────────────────────────────────────────────────────────
  // App info
  // ──────────────────────────────────────────────────────────

  static const String appName        = 'ResQNav';
  static const String appTagline     = 'Smart Emergency Navigator';
  static const String appVersion     = '1.0.0';
  static const String appDescription =
      'Find nearby emergency services and navigate to any destination.';

  // ──────────────────────────────────────────────────────────
  // National emergency numbers (India)
  // ──────────────────────────────────────────────────────────

  static const String numberPolice       = '100';
  static const String numberAmbulance    = '108';
  static const String numberFire         = '101';
  static const String numberDisaster     = '108';
  static const String numberWomen        = '1091';
  static const String numberChildHelpline = '1098';
  static const String numberRoadAccident = '1073';
  static const String numberNationalEmergency = '112'; // Single national number

  // ──────────────────────────────────────────────────────────
  // Emergency categories
  // ──────────────────────────────────────────────────────────

  static const List<EmergencyCategory> emergencyCategories = [
    EmergencyCategory(
      id: 'Hospital',
      label: 'Hospital',
      shortLabel: 'Hospital',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFDC2626),
      emergencyNumber: numberAmbulance,
      description: 'Emergency medical care, ICU, trauma',
    ),
    EmergencyCategory(
      id: 'Ambulance',
      label: 'Ambulance',
      shortLabel: 'Ambulance',
      icon: Icons.emergency_rounded,
      color: Color(0xFFEA580C),
      emergencyNumber: numberAmbulance,
      description: 'Pre-hospital emergency transport',
    ),
    EmergencyCategory(
      id: 'Police',
      label: 'Police',
      shortLabel: 'Police',
      icon: Icons.local_police_rounded,
      color: Color(0xFF2563EB),
      emergencyNumber: numberPolice,
      description: 'Law enforcement, safety assistance',
    ),
    EmergencyCategory(
      id: 'Fire Station',
      label: 'Fire Station',
      shortLabel: 'Fire',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFD97706),
      emergencyNumber: numberFire,
      description: 'Fire & rescue operations',
    ),
    EmergencyCategory(
      id: 'Pharmacy',
      label: 'Pharmacy',
      shortLabel: 'Pharmacy',
      icon: Icons.local_pharmacy_rounded,
      color: Color(0xFF16A34A),
      emergencyNumber: '',
      description: 'Medicines, first-aid supplies',
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // Home service categories
  // ──────────────────────────────────────────────────────────

  static const List<EmergencyCategory> homeServiceCategories = [
    EmergencyCategory(
      id: 'Plumber',
      label: 'Plumber',
      shortLabel: 'Plumber',
      icon: Icons.plumbing_rounded,
      color: Color(0xFF8B5CF6),
      emergencyNumber: '',
      description: 'Plumbing repairs, water leaks, drainage',
    ),
    EmergencyCategory(
      id: 'Electrician',
      label: 'Electrician',
      shortLabel: 'Electrician',
      icon: Icons.electrical_services_rounded,
      color: Color(0xFFF59E0B),
      emergencyNumber: '',
      description: 'Electrical repairs, wiring, power issues',
    ),
    EmergencyCategory(
      id: 'Mechanic',
      label: 'Mechanic',
      shortLabel: 'Mechanic',
      icon: Icons.build_rounded,
      color: Color(0xFF6B7280),
      emergencyNumber: '',
      description: 'Vehicle repairs, maintenance, breakdown',
    ),
    EmergencyCategory(
      id: 'Locksmith',
      label: 'Locksmith',
      shortLabel: 'Locksmith',
      icon: Icons.lock_rounded,
      color: Color(0xFF84CC16),
      emergencyNumber: '',
      description: 'Lock repairs, key cutting, security',
    ),
    EmergencyCategory(
      id: 'Cleaning',
      label: 'Cleaning',
      shortLabel: 'Cleaning',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF06B6D4),
      emergencyNumber: '',
      description: 'Home cleaning, sanitization services',
    ),
    EmergencyCategory(
      id: 'Carpenter',
      label: 'Carpenter',
      shortLabel: 'Carpenter',
      icon: Icons.handyman_rounded,
      color: Color(0xFF92400E),
      emergencyNumber: '',
      description: 'Furniture repair, woodwork, installations',
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // Professional service categories
  // ──────────────────────────────────────────────────────────

  static const List<EmergencyCategory> professionalServiceCategories = [
    EmergencyCategory(
      id: 'Taxi',
      label: 'Taxi',
      shortLabel: 'Taxi',
      icon: Icons.local_taxi_rounded,
      color: Color(0xFFEAB308),
      emergencyNumber: '',
      description: 'Transportation, cab services',
    ),
    EmergencyCategory(
      id: 'Towing',
      label: 'Towing',
      shortLabel: 'Towing',
      icon: Icons.fire_truck_rounded,
      color: Color(0xFFEF4444),
      emergencyNumber: '',
      description: 'Vehicle towing, roadside assistance',
    ),
    EmergencyCategory(
      id: 'Veterinary',
      label: 'Veterinary',
      shortLabel: 'Vet',
      icon: Icons.pets_rounded,
      color: Color(0xFF10B981),
      emergencyNumber: '',
      description: 'Pet care, animal medical services',
    ),
    EmergencyCategory(
      id: 'Pest Control',
      label: 'Pest Control',
      shortLabel: 'Pest Control',
      icon: Icons.pest_control_rounded,
      color: Color(0xFF7C2D12),
      emergencyNumber: '',
      description: 'Pest management, extermination',
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // All categories combined
  // ──────────────────────────────────────────────────────────

  static List<EmergencyCategory> get allCategories => [
    ...emergencyCategories,
    ...homeServiceCategories,
    ...professionalServiceCategories,
  ];

  // ──────────────────────────────────────────────────────────
  // Category helper methods
  // ──────────────────────────────────────────────────────────

  /// Get category by ID
  static EmergencyCategory? getCategoryById(String id) {
    try {
      return allCategories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get emergency-only categories
  static List<EmergencyCategory> get emergencyOnly => emergencyCategories;

  /// Get home service categories  
  static List<EmergencyCategory> get homeServicesOnly => homeServiceCategories;

  /// Get professional service categories
  static List<EmergencyCategory> get professionalServicesOnly => professionalServiceCategories;

  /// Check if category is emergency-related
  static bool isEmergencyCategory(String categoryId) {
    return emergencyCategories.any((cat) => cat.id == categoryId);
  }

  // ──────────────────────────────────────────────────────────
  // Quick-dial numbers shown on the Emergency page
  // ──────────────────────────────────────────────────────────

  static const List<QuickDial> quickDials = [
    QuickDial(
      label: 'National Emergency',
      number: numberNationalEmergency,
      icon: Icons.sos_rounded,
      color: Color(0xFFDC2626),
    ),
    QuickDial(
      label: 'Ambulance',
      number: numberAmbulance,
      icon: Icons.emergency_rounded,
      color: Color(0xFFEA580C),
    ),
    QuickDial(
      label: 'Police',
      number: numberPolice,
      icon: Icons.local_police_rounded,
      color: Color(0xFF2563EB),
    ),
    QuickDial(
      label: 'Fire Brigade',
      number: numberFire,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFD97706),
    ),
    QuickDial(
      label: 'Women Helpline',
      number: numberWomen,
      icon: Icons.shield_rounded,
      color: Color(0xFF7C3AED),
    ),
    QuickDial(
      label: 'Road Accident',
      number: numberRoadAccident,
      icon: Icons.car_crash_rounded,
      color: Color(0xFF0891B2),
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // Default map location (Mumbai)
  // ──────────────────────────────────────────────────────────

  static const double defaultLat = 19.0760;
  static const double defaultLng = 72.8777;

  // ──────────────────────────────────────────────────────────
  // Map zoom levels
  // ──────────────────────────────────────────────────────────

  static const double zoomCity        = 12.0;
  static const double zoomNeighborhood = 14.0;
  static const double zoomStreet      = 16.0;
  static const double zoomBuilding    = 18.0;
}

// ============================================================
// EMERGENCY CATEGORY MODEL
// ============================================================

class EmergencyCategory {
  final String id;
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final String emergencyNumber;
  final String description;

  const EmergencyCategory({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.emergencyNumber,
    required this.description,
  });
}

// ============================================================
// QUICK-DIAL MODEL
// ============================================================

class QuickDial {
  final String label;
  final String number;
  final IconData icon;
  final Color color;

  const QuickDial({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
  });
}
