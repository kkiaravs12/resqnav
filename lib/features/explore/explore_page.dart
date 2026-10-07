import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../navigation/navigation_page.dart';

// Conditional import for web JS interop
import 'explore_page_mobile.dart'
    if (dart.library.js_interop) 'explore_page_web.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  // ── Map ──────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  static const LatLng _defaultLocation = LatLng(19.0760, 72.8777);
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // ── Location loading ──────────────────────────────────────────────────────
  bool _locationLoading = false;

  // ── Search ───────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  bool _isSearching = false;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

  // ── Destination & route ───────────────────────────────────────────────────
  bool _placeSelected = false;
  String _destName = '';
  String _destAddress = '';
  double _destLat = 0;
  double _destLng = 0;

  String _travelMode = 'car';
  bool _routeLoading = false;
  double _routeDistanceMeters = 0;
  double _routeDurationMs = 0;
  LatLng? _routeOrigin;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search / Nominatim
  // ─────────────────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    setState(() => _showSuggestions = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _fetchSuggestions(query.trim()));
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final loc = _currentLocation;
      String extra = '';
      if (loc != null) {
        const d = 2.0;
        extra = '&viewbox=${loc.longitude - d},${loc.latitude + d},'
            '${loc.longitude + d},${loc.latitude - d}&bounded=0';
      }

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&addressdetails=1&limit=6$extra',
      );

      final res = await http.get(uri, headers: {
        'User-Agent': 'ResQNav/1.0',
        'Accept-Language': 'en',
      });

      if (!mounted) return;

      final list = res.statusCode == 200
          ? (jsonDecode(res.body) as List<dynamic>)
          : <dynamic>[];

      _suggestions = list.map<Map<String, dynamic>>((item) {
        final addr = (item['address'] as Map<String, dynamic>? ?? {});
        final name = (addr['amenity'] ??
            addr['shop'] ??
            addr['tourism'] ??
            addr['building'] ??
            addr['leisure'] ??
            addr['road'] ??
            item['name'] ??
            (item['display_name'] as String).split(',').first) as String;

        final parts = <String>[];
        if (addr['road'] != null && addr['road'] != name) parts.add(addr['road'] as String);
        if (addr['suburb'] != null) parts.add(addr['suburb'] as String);
        final city = addr['city'] ?? addr['town'] ?? addr['village'];
        if (city != null) parts.add(city as String);
        if (addr['state'] != null) parts.add(addr['state'] as String);
        if (addr['country'] != null) parts.add(addr['country'] as String);

        return {
          'name': name,
          'address': parts.isNotEmpty ? parts.join(', ') : item['display_name'] as String,
          'lat': double.parse(item['lat'].toString()),
          'lon': double.parse(item['lon'].toString()),
        };
      }).toList();

      setState(() => _isSearching = false);
    } catch (e) {
      debugPrint('ResQNav autocomplete: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSuggestion(Map<String, dynamic> s) {
    _searchController.text = s['name'] as String;
    _searchFocus.unfocus();
    setState(() => _showSuggestions = false);
    _onPlaceSelected(
      s['name'] as String,
      s['address'] as String,
      s['lat'] as double,
      s['lon'] as double,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Location
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadCurrentLocation() async {
    if (_locationLoading) return;
    setState(() => _locationLoading = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setDefault();
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _setDefault();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentLocation = loc);
      _updateMyMarker(loc);
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: loc, zoom: 15),
      ));
    } catch (e) {
      debugPrint('ResQNav location: $e');
      _setDefault();
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  void _setDefault() {
    if (!mounted) return;
    setState(() => _currentLocation = _defaultLocation);
    _updateMyMarker(_defaultLocation);
  }

  void _updateMyMarker(LatLng loc) {
    setState(() {
      _markers.removeWhere((m) => m.markerId == const MarkerId('me'));
      _markers.add(Marker(
        markerId: const MarkerId('me'),
        position: loc,
        infoWindow: const InfoWindow(title: 'Your location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Place selected
  // ─────────────────────────────────────────────────────────────────────────

  void _onPlaceSelected(String name, String address, double lat, double lng) {
    final loc = LatLng(lat, lng);
    setState(() {
      _destName = name;
      _destAddress = address;
      _destLat = lat;
      _destLng = lng;
      _placeSelected = true;
      _routeDistanceMeters = 0;
      _routeDurationMs = 0;
      _routeOrigin = null;
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId == const MarkerId('dest'));
      _markers.add(Marker(
        markerId: const MarkerId('dest'),
        position: loc,
        infoWindow: InfoWindow(title: name, snippet: address),
      ));
    });
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: loc, zoom: 15),
    ));
  }

  void _clearDestination() {
    setState(() {
      _placeSelected = false;
      _destName = '';
      _destAddress = '';
      _destLat = 0;
      _destLng = 0;
      _routeDistanceMeters = 0;
      _routeDurationMs = 0;
      _routeOrigin = null;
      _routeLoading = false;
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId == const MarkerId('dest'));
    });
    _searchController.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Route / Directions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _getDirections() async {
    if (!_placeSelected || _routeLoading) return;

    setState(() {
      _routeLoading = true;
      _polylines.clear();
      _routeDistanceMeters = 0;
      _routeDurationMs = 0;
    });

    try {
      if (_currentLocation == null) await _loadCurrentLocation();
      final origin = _currentLocation;
      if (origin == null) {
        _showSnack('Could not get your location');
        setState(() => _routeLoading = false);
        return;
      }
      _routeOrigin = origin;

      if (kIsWeb) {
        computeResQNavRoute(
          origin, _destLat, _destLng, _travelMode,
          (String pathJson, double dist, double dur) {
            if (!mounted) return;
            try {
              final pts = (jsonDecode(pathJson) as List).map<LatLng>((p) =>
                LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble())).toList();
              setState(() {
                _routeLoading = false;
                _routeDistanceMeters = dist;
                _routeDurationMs = dur;
                _polylines
                  ..clear()
                  ..add(Polyline(
                    polylineId: const PolylineId('route'),
                    points: pts,
                    width: 7,
                    color: AppTheme.primary,
                    geodesic: true,
                  ));
              });
              _fitRoute(pts);
            } catch (e) {
              setState(() => _routeLoading = false);
              _showSnack('Could not load route');
            }
          },
        );
      } else {
        await _computeOsrmRoute(origin);
      }
    } catch (e) {
      debugPrint('ResQNav directions: $e');
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  Future<void> _computeOsrmRoute(LatLng origin) async {
    final mode = _travelMode == 'walk' ? 'foot' : 'driving';
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$mode/'
      '${origin.longitude},${origin.latitude};$_destLng,$_destLat'
      '?overview=full&geometries=geojson',
    );

    try {
      final res = await http.get(url, headers: {'User-Agent': 'ResQNav/1.0'});
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final route = (data['routes'] as List).first as Map<String, dynamic>;
        final dist = (route['distance'] as num).toDouble();
        final dur = (route['duration'] as num).toDouble() * 1000;
        final coords = ((route['geometry'] as Map)['coordinates'] as List)
            .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        setState(() {
          _routeLoading = false;
          _routeDistanceMeters = dist;
          _routeDurationMs = dur;
          _polylines
            ..clear()
            ..add(Polyline(
              polylineId: const PolylineId('route'),
              points: coords,
              width: 7,
              color: AppTheme.primary,
              geodesic: true,
            ));
        });
        _fitRoute(coords);
      } else {
        setState(() => _routeLoading = false);
        _showSnack('Route not available');
      }
    } catch (e) {
      debugPrint('ResQNav OSRM: $e');
      if (mounted) setState(() => _routeLoading = false);
      _showSnack('Route not available');
    }
  }

  void _fitRoute(List<LatLng> pts) {
    if (pts.isEmpty || _mapController == null) return;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      88,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────────────────────────

  void _startNavigation() {
    if (!_placeSelected || _routeOrigin == null || _routeDistanceMeters <= 0) return;
    _saveHistory();
    Navigator.push(context, MaterialPageRoute(builder: (_) => NavigationPage(
      destinationName: _destName,
      destinationAddress: _destAddress,
      currentLocation: _routeOrigin!,
      destinationLocation: LatLng(_destLat, _destLng),
      routePoints: _polylines.isNotEmpty ? _polylines.first.points : [],
      distanceMeters: _routeDistanceMeters,
      durationMilliseconds: _routeDurationMs,
      travelMode: _travelMode,
    )));
  }

  Future<void> _openInGoogleMaps() async {
    final mode = _travelMode == 'walk' ? 'walking' : 'driving';
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$_destLat,$_destLng'
      '&travelmode=$mode',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveHistory() async {
    try {
      await ApiService.createHistory({
        'search_type': 'destination',
        'query': _destName,
        'destination_name': _destName,
        'destination_address': _destAddress,
        'latitude': double.parse(_destLat.toStringAsFixed(6)),
        'longitude': double.parse(_destLng.toStringAsFixed(6)),
        'distance_meters': _routeDistanceMeters,
        'duration_seconds': _routeDurationMs / 1000,
      });
    } catch (e) {
      debugPrint('ResQNav history: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utils
  // ─────────────────────────────────────────────────────────────────────────

  String _fmtDist(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  String _fmtDur(double ms) {
    final mins = (ms / 60000).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60, m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────
          Positioned.fill(child: _buildMap()),

          // ── Search bar + suggestions sheet (top) ─────────────────────
          if (!_placeSelected)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _buildSearchSection(),
            ),

          // ── My-location FAB ─────────────────────────────────────────
          if (!_placeSelected)
            Positioned(
              right: 14,
              bottom: 24,
              child: _buildMyLocationFab(),
            ),

          // ── Destination sheet (bottom) ───────────────────────────────
          if (_placeSelected)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _buildDestinationSheet(),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Map widget
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMap() {
    if (kIsWeb) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Map view available on mobile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Use search to find services',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return GoogleMap(
      initialCameraPosition: const CameraPosition(target: _defaultLocation, zoom: 13),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onMapCreated: (ctrl) {
        _mapController = ctrl;
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search section (matches the screenshot)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final hintColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textHint;
    
    return SafeArea(
      bottom: false,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Explore + notification + profile
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkPrimary : AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Explore',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                ),
                IconButton(
                  icon: Icon(Icons.notifications_outlined, size: 24, color: hintColor),
                  onPressed: null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('K', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search bar
            TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: hintColor, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions = [];
                            _showSuggestions = false;
                          });
                        },
                        child: Icon(Icons.close, color: hintColor, size: 20),
                      )
                    : null,
                hintText: 'Search for a place...',
                hintStyle: TextStyle(color: hintColor, fontSize: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppTheme.darkPrimary : AppTheme.primary, width: 2),
                ),
                filled: true,
                fillColor: bgColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: TextStyle(color: textColor, fontSize: 15),
              onChanged: _onSearchChanged,
              onSubmitted: (_) {
                if (_suggestions.isNotEmpty) _selectSuggestion(_suggestions.first);
              },
            ),

            // Suggestions list (card style)
            if (_showSuggestions && (_isSearching || _suggestions.isNotEmpty))
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: borderColor),
                        itemBuilder: (_, i) {
                          final s = _suggestions[i];
                          return _SuggestionTile(
                            name: s['name'] as String,
                            address: s['address'] as String,
                            onTap: () => _selectSuggestion(s),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLocationFab() {
    return Material(
      elevation: 6,
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _locationLoading ? null : _loadCurrentLocation,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46, height: 46,
          child: _locationLoading
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location_rounded, color: AppTheme.primary, size: 22),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Destination sheet (bottom)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDestinationSheet() {
    final hasRoute = _routeDistanceMeters > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black12, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Place name + close
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_destName,
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (_destAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(_destAddress,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: _clearDestination,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Travel mode selector
          Row(
            children: [
              _travelModeTab('car', Icons.directions_car_rounded, 'Drive'),
              const SizedBox(width: 8),
              _travelModeTab('walk', Icons.directions_walk_rounded, 'Walk'),
            ],
          ),

          const SizedBox(height: 16),

          // Route info (when loaded)
          if (hasRoute) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fmtDur(_routeDurationMs),
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        Text(_fmtDist(_routeDistanceMeters),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Text('Best route',
                    style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // CTA Buttons
          Row(
            children: [
              // Directions button
              Expanded(
                flex: hasRoute ? 1 : 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _routeLoading ? null : _getDirections,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _routeLoading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            hasRoute ? 'Recalc' : 'Directions',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),

              if (hasRoute) ...[
                const SizedBox(width: 10),
                // Start button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _startNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Start',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _travelModeTab(String mode, IconData icon, String label) {
    final selected = _travelMode == mode;
    return GestureDetector(
      onTap: () {
        if (_travelMode == mode) return;
        setState(() {
          _travelMode = mode;
          _routeDistanceMeters = 0;
          _routeDurationMs = 0;
          _routeOrigin = null;
          _polylines.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestion tile
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final String name;
  final String address;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.name,
    required this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 20, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
