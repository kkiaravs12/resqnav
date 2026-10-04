import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Represents a nearby emergency service location
class NearbyService {
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String? address;
  final String? phone;

  NearbyService({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.address,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'distance_km': distanceKm,
        'address': address,
        'phone': phone,
      };
}

/// Location service for finding nearby emergency services using OpenStreetMap
class LocationService {
  // ================================================================
  // LOCATION PERMISSIONS & GPS
  // ================================================================

  /// Get current GPS position
  static Future<Position> getCurrentPosition() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception("Location service disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get current address from coordinates
  static Future<String> getCurrentAddress() async {
    try {
      Position position = await getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return "Location unavailable";

      Placemark place = placemarks.first;
      return "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
    } catch (e) {
      return "Location unavailable";
    }
  }

  // ================================================================
  // FIND NEARBY EMERGENCY SERVICES
  // ================================================================

  /// Find nearby services by category using OpenStreetMap
  static Future<List<NearbyService>> getNearbyServices({
    required String category,
    double radiusMeters = 15000,  // Increased from 5000 to 15000 meters (15 km)
  }) async {
    final position = await getCurrentPosition();

    // Map our categories to OpenStreetMap tags
    final osmQuery = _buildOSMQuery(category, radiusMeters, position);

    try {
      final stopwatch = Stopwatch()..start();

      final response = await http
          .post(
            Uri.parse("https://overpass-api.de/api/interpreter"),
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
              "User-Agent": "ResQNavApp/1.0 (emergency response app)",
            },
            body: {"data": osmQuery},
          )
          .timeout(const Duration(seconds: 30));

      print(
          "OpenStreetMap query for $category took: ${stopwatch.elapsedMilliseconds}ms");

      if (response.statusCode != 200) {
        print("OpenStreetMap error: ${response.statusCode}");
        return [];
      }

      final data = jsonDecode(response.body);
      final elements = data["elements"] as List;

      final services = <NearbyService>[];

      for (final e in elements) {
        final tags = e["tags"] ?? {};
        final name = _extractName(tags, category);

        double lat, lon;
        if (e["type"] == "node") {
          lat = e["lat"];
          lon = e["lon"];
        } else if (e["center"] != null) {
          lat = e["center"]["lat"];
          lon = e["center"]["lon"];
        } else {
          continue;
        }

        final distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              lat,
              lon,
            ) /
            1000;

        services.add(NearbyService(
          name: name,
          category: category,
          latitude: lat,
          longitude: lon,
          distanceKm: distance,
          address: tags["addr:full"] ?? tags["addr:street"],
          phone: tags["phone"] ?? tags["contact:phone"],
        ));
      }

      // Sort by distance
      services.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      // Return top 10
      return services.take(10).toList();
    } catch (e) {
      print("Error fetching nearby services: $e");
      return [];
    }
  }

  /// Build OpenStreetMap Overpass query for specific category
  static String _buildOSMQuery(
      String category, double radius, Position position) {
    final lat = position.latitude;
    final lon = position.longitude;

    String tagQuery;

    switch (category.toLowerCase()) {
      case 'hospital':
        tagQuery = '''
          nwr["amenity"="hospital"](around:$radius,$lat,$lon);
          nwr["amenity"="clinic"](around:$radius,$lat,$lon);
          nwr["healthcare"="hospital"](around:$radius,$lat,$lon);
          nwr["name"~"hospital|Hospital|हॉस्पिटल|medical"](around:$radius,$lat,$lon);
        ''';
        break;

      case 'police':
        tagQuery = '''
          nwr["amenity"="police"](around:$radius,$lat,$lon);
          nwr["police"="yes"](around:$radius,$lat,$lon);
          nwr["name"~"police|Police|पुलिस"](around:$radius,$lat,$lon);
        ''';
        break;

      case 'fire station':
        tagQuery = '''
          nwr["amenity"="fire_station"](around:$radius,$lat,$lon);
          nwr["emergency"="fire_station"](around:$radius,$lat,$lon);
          nwr["name"~"fire|Fire|फायर"](around:$radius,$lat,$lon);
        ''';
        break;

      case 'pharmacy':
        tagQuery = '''
          nwr["amenity"="pharmacy"](around:$radius,$lat,$lon);
          nwr["healthcare"="pharmacy"](around:$radius,$lat,$lon);
          nwr["name"~"pharmacy|Pharmacy|दवा|medicine"](around:$radius,$lat,$lon);
        ''';
        break;

      case 'ambulance':
        tagQuery = '''
          nwr["amenity"="hospital"](around:$radius,$lat,$lon);
          nwr["emergency"="ambulance_station"](around:$radius,$lat,$lon);
        ''';
        break;

      case 'mechanic':
        tagQuery = '''
          nwr["shop"="car_repair"](around:$radius,$lat,$lon);
          nwr["craft"="car_repair"](around:$radius,$lat,$lon);
          nwr["amenity"="car_repair"](around:$radius,$lat,$lon);
        ''';
        break;

      default:
        tagQuery = 'nwr["amenity"="hospital"](around:$radius,$lat,$lon);';
    }

    return '''
      [out:json][timeout:25];
      ($tagQuery);
      out center;
    ''';
  }

  /// Extract appropriate name from OSM tags
  static String _extractName(Map tags, String category) {
    // Try different name variants
    final name = tags["name"] ?? 
                 tags["name:en"] ?? 
                 tags["official_name"] ?? 
                 tags["brand"];

    if (name != null && name.toString().isNotEmpty) {
      return name;
    }

    // Fallback names by category
    switch (category.toLowerCase()) {
      case 'hospital':
        return "Medical Center";
      case 'police':
        return "Police Station";
      case 'fire station':
        return "Fire Station";
      case 'pharmacy':
        return "Pharmacy";
      case 'ambulance':
        return "Ambulance Service";
      case 'mechanic':
        return "Auto Repair Shop";
      default:
        return "Emergency Service";
    }
  }

  // ================================================================
  // QUICK ACTIONS
  // ================================================================

  /// Open Google Maps to search for nearest location of a category
  static Future<void> openNearestOnMap(String category) async {
    try {
      final position = await getCurrentPosition();
      final query = _getMapSearchQuery(category);
      
      final Uri maps = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$query&center=${position.latitude},${position.longitude}",
      );

      if (await canLaunchUrl(maps)) {
        await launchUrl(maps, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("Error opening maps: $e");
    }
  }

  /// Get appropriate search query for Google Maps
  static String _getMapSearchQuery(String category) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return 'hospital';
      case 'police':
        return 'police+station';
      case 'fire station':
        return 'fire+station';
      case 'pharmacy':
        return 'pharmacy';
      case 'ambulance':
        return 'ambulance+service';
      case 'mechanic':
        return 'car+repair';
      default:
        return category.replaceAll(' ', '+');
    }
  }

  /// Open specific location in Google Maps
  static Future<void> openLocationInMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final Uri maps = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=${label ?? 'Location'}",
    );

    if (await canLaunchUrl(maps)) {
      await launchUrl(maps, mode: LaunchMode.externalApplication);
    }
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
