import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // =========================================================
  // BASE URL
  // =========================================================

  // Use production URL for deployed backend
  // For local development, change to: 'http://127.0.0.1:8000/api'
  static const String baseUrl = 'https://resqnav-ziqj.onrender.com/api';

  // =========================================================
  // TOKEN & USER STORAGE
  // =========================================================

  static String? accessToken;
  static String? refreshToken;
  static String? currentUserName;
  static String? currentUserEmail;

  static const String _accessTokenKey = 'resqnav_access_token';
  static const String _refreshTokenKey = 'resqnav_refresh_token';
  static const String _userNameKey = 'resqnav_user_name';
  static const String _userEmailKey = 'resqnav_user_email';

  // =========================================================
  // DISPLAY HELPERS
  // =========================================================

  static String get displayName {
    if (currentUserName != null && currentUserName!.trim().isNotEmpty) {
      return currentUserName!.trim();
    }
    return 'ResQNav User';
  }

  static String get displayInitial {
    final name = displayName;
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'R';
  }

  // =========================================================
  // INITIALIZE AUTH
  // =========================================================

  static Future<void> initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();

    accessToken = prefs.getString(_accessTokenKey);
    refreshToken = prefs.getString(_refreshTokenKey);
    currentUserName = prefs.getString(_userNameKey);
    currentUserEmail = prefs.getString(_userEmailKey);
  }

  // =========================================================
  // PERSIST TOKENS & USER DATA
  // =========================================================

  static Future<void> _persistTokens() async {
    final prefs = await SharedPreferences.getInstance();

    if (accessToken != null && accessToken!.isNotEmpty) {
      await prefs.setString(_accessTokenKey, accessToken!);
    } else {
      await prefs.remove(_accessTokenKey);
    }

    if (refreshToken != null && refreshToken!.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken!);
    } else {
      await prefs.remove(_refreshTokenKey);
    }
  }

  static Future<void> _persistUserData() async {
    final prefs = await SharedPreferences.getInstance();

    if (currentUserName != null && currentUserName!.isNotEmpty) {
      await prefs.setString(_userNameKey, currentUserName!);
    } else {
      await prefs.remove(_userNameKey);
    }

    if (currentUserEmail != null && currentUserEmail!.isNotEmpty) {
      await prefs.setString(_userEmailKey, currentUserEmail!);
    } else {
      await prefs.remove(_userEmailKey);
    }
  }

  // =========================================================
  // COMMON HEADERS
  // =========================================================

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> get _authHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${accessToken ?? ''}',
    };
  }

  // =========================================================
  // REGISTER
  // =========================================================

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim().toLowerCase();

    final requestBody = {
      'username': cleanEmail,
      'full_name': cleanName,
      'email': cleanEmail,
      'password': password,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: _jsonHeaders,
      body: jsonEncode(requestBody),
    );

    final data = _decodeResponse(response);

    debugPrint('REGISTER STATUS: ${response.statusCode}');

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    currentUserName = cleanName;
    currentUserEmail = cleanEmail;
    await _persistUserData();

    if (data is Map<String, dynamic>) {
      await _storeTokensIfPresent(data);
      return Map<String, dynamic>.from(data);
    }

    return {'message': 'Account created successfully.'};
  }

  // =========================================================
  // LOGIN
  // =========================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final requestBody = {
      'username': cleanEmail,
      'password': password,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: _jsonHeaders,
      body: jsonEncode(requestBody),
    );

    final data = _decodeResponse(response);

    debugPrint('LOGIN STATUS: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    await _storeTokensIfPresent(data);

    currentUserEmail = cleanEmail;
    await _persistUserData();

    // Silently fetch user profile to populate name
    try {
      await getProfile();
    } catch (_) {}

    return Map<String, dynamic>.from(data as Map);
  }

  // =========================================================
  // REFRESH ACCESS TOKEN
  // =========================================================

  static Future<bool> refreshAccessToken() async {
    final currentRefreshToken = refreshToken;

    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh/'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'refresh': currentRefreshToken,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode != 200) {
        accessToken = null;
        refreshToken = null;
        await _persistTokens();
        return false;
      }

      if (data is Map<String, dynamic>) {
        final newAccessToken = data['access']?.toString();
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          accessToken = newAccessToken;
        }

        final newRefreshToken = data['refresh']?.toString();
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          refreshToken = newRefreshToken;
        }

        await _persistTokens();
      }

      return accessToken != null && accessToken!.isNotEmpty;
    } catch (error) {
      accessToken = null;
      refreshToken = null;
      await _persistTokens();
      return false;
    }
  }

  // =========================================================
  // PROFILE
  // =========================================================

  static Future<Map<String, dynamic>> getProfile() async {
    _requireToken();

    var response = await http.get(
      Uri.parse('$baseUrl/profile/'),
      headers: _authHeaders,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.get(
          Uri.parse('$baseUrl/profile/'),
          headers: _authHeaders,
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    if (data is! Map) {
      throw const ApiException(
        'Invalid profile response.',
        500,
      );
    }

    final mapData = Map<String, dynamic>.from(data);

    final fullName = mapData['full_name']?.toString().trim();
    final firstName = mapData['first_name']?.toString().trim();
    final lastName = mapData['last_name']?.toString().trim();
    final username = mapData['username']?.toString().trim();
    final email = mapData['email']?.toString().trim();

    String resolved = '';
    if (fullName != null && fullName.isNotEmpty) {
      resolved = fullName;
    } else if (firstName != null && firstName.isNotEmpty) {
      resolved = (lastName != null && lastName.isNotEmpty) ? '$firstName $lastName' : firstName;
    } else if (username != null && username.isNotEmpty) {
      resolved = username;
    }

    if (resolved.isNotEmpty) {
      currentUserName = resolved;
    }
    if (email != null && email.isNotEmpty) {
      currentUserEmail = email;
    }
    await _persistUserData();

    return mapData;
  }

  // =========================================================
  // EMERGENCY SERVICES (WITH HAVERSINE DISTANCE)
  // =========================================================

  static Future<List<Map<String, dynamic>>> getEmergencyServices({
    double? latitude,
    double? longitude,
    String? category,
    double? radiusKm,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (radiusKm != null) {
      queryParams['radius'] = radiusKm.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('$baseUrl/emergency-services/')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri, headers: _jsonHeaders);
    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    if (data is List) {
      return data
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) {
        return results
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();
      }
    }

    throw const ApiException(
      'Invalid emergency services response.',
      500,
    );
  }

  // =========================================================
  // SINGLE EMERGENCY SERVICE
  // =========================================================

  static Future<Map<String, dynamic>> getEmergencyService(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/emergency-services/$id/'),
      headers: _jsonHeaders,
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    if (data is! Map) {
      throw const ApiException(
        'Invalid emergency service response.',
        500,
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // =========================================================
  // EMERGENCY CONTACTS
  // =========================================================

  static Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    _requireToken();

    var response = await http.get(
      Uri.parse('$baseUrl/emergency-contacts/'),
      headers: _authHeaders,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.get(
          Uri.parse('$baseUrl/emergency-contacts/'),
          headers: _authHeaders,
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    if (data is List) {
      return data
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    }

    return [];
  }

  static Future<Map<String, dynamic>> createEmergencyContact(
    Map<String, dynamic> contact,
  ) async {
    _requireToken();

    var response = await http.post(
      Uri.parse('$baseUrl/emergency-contacts/'),
      headers: _authHeaders,
      body: jsonEncode(contact),
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.post(
          Uri.parse('$baseUrl/emergency-contacts/'),
          headers: _authHeaders,
          body: jsonEncode(contact),
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> deleteEmergencyContact(int id) async {
    _requireToken();

    var response = await http.delete(
      Uri.parse('$baseUrl/emergency-contacts/$id/'),
      headers: _authHeaders,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.delete(
          Uri.parse('$baseUrl/emergency-contacts/$id/'),
          headers: _authHeaders,
        );
      }
    }

    if (response.statusCode != 204 && response.statusCode != 200) {
      final data = _decodeResponse(response);
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }
  }

  // =========================================================
  // GET HISTORY
  // =========================================================

  static Future<List<Map<String, dynamic>>> getHistory() async {
    _requireToken();

    var response = await http.get(
      Uri.parse('$baseUrl/history/'),
      headers: _authHeaders,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.get(
          Uri.parse('$baseUrl/history/'),
          headers: _authHeaders,
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    if (data is List) {
      return data
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) {
        return results
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();
      }
    }

    throw const ApiException(
      'Invalid history response.',
      500,
    );
  }

  // =========================================================
  // CREATE HISTORY
  // =========================================================

  static Future<Map<String, dynamic>> createHistory(
    Map<String, dynamic> history,
  ) async {
    _requireToken();

    var response = await http.post(
      Uri.parse('$baseUrl/history/'),
      headers: _authHeaders,
      body: jsonEncode(history),
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.post(
          Uri.parse('$baseUrl/history/'),
          headers: _authHeaders,
          body: jsonEncode(history),
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    if (data is! Map) {
      throw const ApiException(
        'Invalid history response.',
        500,
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // =========================================================
  // DELETE HISTORY
  // =========================================================

  static Future<void> deleteHistory(int id) async {
    _requireToken();

    var response = await http.delete(
      Uri.parse('$baseUrl/history/$id/'),
      headers: _authHeaders,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.delete(
          Uri.parse('$baseUrl/history/$id/'),
          headers: _authHeaders,
        );
      }
    }

    if (response.statusCode != 204 && response.statusCode != 200) {
      final data = _decodeResponse(response);
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }
  }

  // =========================================================
  // CLEAR ALL HISTORY
  // =========================================================

  static Future<void> clearHistory() async {
    _requireToken();

    var response = await http.delete(
      Uri.parse('$baseUrl/history/'),
      headers: _authHeaders,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.delete(
          Uri.parse('$baseUrl/history/'),
          headers: _authHeaders,
        );
      }
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = _decodeResponse(response);
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  static Future<void> logout() async {
    accessToken = null;
    refreshToken = null;
    currentUserName = null;
    currentUserEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }

  // =========================================================
  // AUTHENTICATION CHECK
  // =========================================================

  static bool get isAuthenticated {
    return accessToken != null && accessToken!.isNotEmpty;
  }

  // =========================================================
  // REQUIRE TOKEN
  // =========================================================

  static void _requireToken() {
    if (accessToken == null || accessToken!.isEmpty) {
      throw const ApiException(
        'Authentication required.',
        401,
      );
    }
  }

  // =========================================================
  // STORE TOKENS
  // =========================================================

  static Future<void> _storeTokensIfPresent(dynamic data) async {
    if (data is! Map<String, dynamic>) {
      return;
    }

    final access = data['access']?.toString();
    if (access != null && access.isNotEmpty) {
      accessToken = access;
    }

    final refresh = data['refresh']?.toString();
    if (refresh != null && refresh.isNotEmpty) {
      refreshToken = refresh;
    }

    await _persistTokens();
  }

  // =========================================================
  // DECODE RESPONSE
  // =========================================================

  static dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {
        'detail': response.body,
      };
    }
  }

  // =========================================================
  // EXTRACT ERROR MESSAGE
  // =========================================================

  static String _extractErrorMessage(dynamic data) {
    if (data == null) {
      return 'Something went wrong.';
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (data is List) {
      final messages = <String>[];
      for (final item in data) {
        if (item != null) {
          messages.add(item.toString());
        }
      }
      if (messages.isNotEmpty) {
        return messages.join(', ');
      }
    }

    if (data is Map) {
      final detail = data['detail'];
      if (detail != null) {
        return detail.toString();
      }

      final message = data['message'];
      if (message != null) {
        return message.toString();
      }

      final nonFieldErrors = data['non_field_errors'];
      if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
        return nonFieldErrors.map((item) => item.toString()).join(', ');
      }

      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          for (final item in value) {
            errors.add('$key: ${item.toString()}');
          }
        } else if (value != null) {
          errors.add('$key: ${value.toString()}');
        }
      });

      if (errors.isNotEmpty) {
        return errors.join('\n');
      }
    }

    return 'Something went wrong. Please try again.';
  }

  // =========================================================
  // EMERGENCY ALERTS
  // =========================================================

  static Future<Map<String, dynamic>> triggerEmergencyAlert({
    String alertType = 'sos',
    String? message,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    _requireToken();

    final body = <String, dynamic>{
      'alert_type': alertType,
    };

    if (message != null && message.isNotEmpty) {
      body['message'] = message;
    }
    if (latitude != null) {
      body['latitude'] = latitude;
    }
    if (longitude != null) {
      body['longitude'] = longitude;
    }
    if (address != null && address.isNotEmpty) {
      body['address'] = address;
    }

    var response = await http.post(
      Uri.parse('$baseUrl/emergency-alert/'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.post(
          Uri.parse('$baseUrl/emergency-alert/'),
          headers: _authHeaders,
          body: jsonEncode(body),
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<Map<String, dynamic>>> getEmergencyAlerts() async {
    _requireToken();

    var response = await http.get(
      Uri.parse('$baseUrl/emergency-alerts/'),
      headers: _authHeaders,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.get(
          Uri.parse('$baseUrl/emergency-alerts/'),
          headers: _authHeaders,
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    if (data is List) {
      return data
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    }

    return [];
  }

  static Future<Map<String, dynamic>> resolveEmergencyAlert(int alertId) async {
    _requireToken();

    var response = await http.post(
      Uri.parse('$baseUrl/emergency-alerts/$alertId/resolve/'),
      headers: _authHeaders,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.post(
          Uri.parse('$baseUrl/emergency-alerts/$alertId/resolve/'),
          headers: _authHeaders,
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    return Map<String, dynamic>.from(data as Map);
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
  }) async {
    _requireToken();

    final body = <String, dynamic>{};
    if (fullName != null && fullName.isNotEmpty) {
      body['full_name'] = fullName;
    }
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    var response = await http.patch(
      Uri.parse('$baseUrl/profile/'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.patch(
          Uri.parse('$baseUrl/profile/'),
          headers: _authHeaders,
          body: jsonEncode(body),
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    if (data is! Map) {
      throw const ApiException(
        'Invalid profile response.',
        500,
      );
    }

    final mapData = Map<String, dynamic>.from(data);

    // Update local cache
    final newFullName = mapData['full_name']?.toString().trim();
    final newFirstName = mapData['first_name']?.toString().trim();
    final newLastName = mapData['last_name']?.toString().trim();
    final newEmail = mapData['email']?.toString().trim();

    String resolved = '';
    if (newFullName != null && newFullName.isNotEmpty) {
      resolved = newFullName;
    } else if (newFirstName != null && newFirstName.isNotEmpty) {
      resolved = (newLastName != null && newLastName.isNotEmpty)
          ? '$newFirstName $newLastName'
          : newFirstName;
    }

    if (resolved.isNotEmpty) {
      currentUserName = resolved;
    }
    if (newEmail != null && newEmail.isNotEmpty) {
      currentUserEmail = newEmail;
    }
    await _persistUserData();

    return mapData;
  }

  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );
    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(_extractErrorMessage(data), response.statusCode);
    }
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> confirmPasswordReset({
    required String uid,
    required String token,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'uid': uid,
        'token': token,
        'password': password,
      }),
    );
    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(_extractErrorMessage(data), response.statusCode);
    }
  }

  // =========================================================
  // UPDATE EMERGENCY CONTACT
  // =========================================================

  static Future<Map<String, dynamic>> updateEmergencyContact(
    int id,
    Map<String, dynamic> contact,
  ) async {
    _requireToken();

    var response = await http.patch(
      Uri.parse('$baseUrl/emergency-contacts/$id/'),
      headers: _authHeaders,
      body: jsonEncode(contact),
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.patch(
          Uri.parse('$baseUrl/emergency-contacts/$id/'),
          headers: _authHeaders,
          body: jsonEncode(contact),
        );
      }
    }

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(data),
        response.statusCode,
      );
    }

    return Map<String, dynamic>.from(data as Map);
  }
}


// =========================================================
// API EXCEPTION
// =========================================================

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(
    this.message,
    this.statusCode,
  );

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}


  // =========================================================
  // COMBINED EMERGENCY SERVICES (Database + OpenStreetMap)
  // =========================================================

  /// Get emergency services combining database + nearby live results
  static Future<List<Map<String, dynamic>>> getCombinedEmergencyServices({
    String? category,
    double? userLat,
    double? userLon,
  }) async {
    try {
      // Get database services
      final dbServices = await getEmergencyServices(category: category);

      // Get nearby services from OpenStreetMap if we have user location
      List<Map<String, dynamic>> nearbyServices = [];
      if (category != null && userLat != null && userLon != null) {
        try {
          final locationService = await import('location_service.dart');
          final nearby = await locationService.LocationService.getNearbyServices(
            category: category,
            radiusMeters: 5000,
          );
          nearbyServices = nearby.map((s) => s.toJson()).toList();
        } catch (e) {
          print("OpenStreetMap fetch failed: $e");
        }
      }

      // Combine both lists
      final combined = <Map<String, dynamic>>[...dbServices];
      
      // Add nearby services that aren't duplicates
      for (final nearby in nearbyServices) {
        final isDuplicate = combined.any((db) {
          final dbLat = db['latitude'] as double?;
          final dbLon = db['longitude'] as double?;
          final nearbyLat = nearby['latitude'] as double?;
          final nearbyLon = nearby['longitude'] as double?;
          
          if (dbLat == null || dbLon == null || nearbyLat == null || nearbyLon == null) {
            return false;
          }
          
          // Consider duplicate if within 50 meters
          final distance = _calculateDistance(dbLat, dbLon, nearbyLat, nearbyLon);
          return distance < 0.05; // 50 meters
        });

        if (!isDuplicate) {
          combined.add(nearby);
        }
      }

      // Sort by distance if user location available
      if (userLat != null && userLon != null) {
        combined.sort((a, b) {
          final distA = _calculateDistance(
            userLat,
            userLon,
            a['latitude'] ?? 0.0,
            a['longitude'] ?? 0.0,
          );
          final distB = _calculateDistance(
            userLat,
            userLon,
            b['latitude'] ?? 0.0,
            b['longitude'] ?? 0.0,
          );
          return distA.compareTo(distB);
        });
      }

      return combined;
    } catch (e) {
      print("Error combining services: $e");
      // Fallback to database only
      return getEmergencyServices(category: category);
    }
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
