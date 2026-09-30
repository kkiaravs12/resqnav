import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_theme.dart';

class NavigationPage extends StatefulWidget {
  final String destinationName;
  final String destinationAddress;
  final LatLng currentLocation;
  final LatLng destinationLocation;
  final List<LatLng> routePoints;
  final double distanceMeters;
  final double durationMilliseconds;
  final String travelMode;

  const NavigationPage({
    super.key,
    required this.destinationName,
    required this.destinationAddress,
    required this.currentLocation,
    required this.destinationLocation,
    required this.routePoints,
    required this.distanceMeters,
    required this.durationMilliseconds,
    required this.travelMode,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;

  bool _navigationStarted = false;

  // ETA countdown
  Timer? _etaTimer;
  late double _remainingMs;
  late double _elapsedMs;

  // Simulated progress (0.0 → 1.0)
  double get _progress =>
      _remainingMs <= 0 ? 1.0 : (_elapsedMs / widget.durationMilliseconds).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _remainingMs = widget.durationMilliseconds;
    _elapsedMs   = 0;
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startNavigation() {
    setState(() => _navigationStarted = true);

    // Tick every second, simulating progress
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingMs > 0) {
          _remainingMs = (_remainingMs - 1000).clamp(0, double.infinity);
          _elapsedMs   += 1000;
        } else {
          _etaTimer?.cancel();
        }
      });
    });
  }

  void _stopNavigation() {
    _etaTimer?.cancel();
    setState(() {
      _navigationStarted = false;
      _remainingMs = widget.durationMilliseconds;
      _elapsedMs   = 0;
    });
  }

  void _fitRoute() {
    if (_mapController == null || widget.routePoints.isEmpty) return;

    double minLat = widget.routePoints.first.latitude;
    double maxLat = widget.routePoints.first.latitude;
    double minLng = widget.routePoints.first.longitude;
    double maxLng = widget.routePoints.first.longitude;

    for (final p in widget.routePoints) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        96,
      ),
    );
  }

  // ── Formatting ────────────────────────────────────────────

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(double ms) {
    final mins = (ms / 60000).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // ETA clock
  String get _etaTime {
    final arrival = DateTime.now().add(Duration(milliseconds: _remainingMs.toInt()));
    final h = arrival.hour.toString().padLeft(2, '0');
    final m = arrival.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('nav_origin'),
        position: widget.currentLocation,
        infoWindow: const InfoWindow(title: 'Your location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('nav_destination'),
        position: widget.destinationLocation,
        infoWindow: InfoWindow(title: widget.destinationName),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('nav_route'),
        points: widget.routePoints,
        width: 7,
        color: AppTheme.primary,
        geodesic: true,
        patterns: const [],
      ),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map ──
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.currentLocation,
                zoom: 13,
              ),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
              },
            ),
          ),

          // ── Top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _circleButton(
                      Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _destinationChip()),
                    const SizedBox(width: 10),
                    _circleButton(
                      Icons.fit_screen_rounded,
                      onTap: _fitRoute,
                      tooltip: 'Fit route',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom card ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _buildBottomCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, {VoidCallback? onTap, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        elevation: 6,
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: AppTheme.textPrimary, size: 21),
          ),
        ),
      ),
    );
  }

  Widget _destinationChip() {
    return Material(
      elevation: 6,
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.destinationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  Text(
                    widget.destinationAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard() {
    return Material(
      elevation: 14,
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode + headline
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.travelMode == 'walk'
                        ? Icons.directions_walk_rounded
                        : Icons.directions_car_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _navigationStarted ? 'Navigation in progress' : 'Route ready',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      Text(
                        _navigationStarted
                            ? 'Arrive by $_etaTime'
                            : 'Tap Start to begin navigating',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _statBox(
                  Icons.route_rounded,
                  _formatDistance(widget.distanceMeters),
                  'Distance',
                ),
                const SizedBox(width: 10),
                _statBox(
                  Icons.access_time_rounded,
                  _formatDuration(_navigationStarted ? _remainingMs : widget.durationMilliseconds),
                  _navigationStarted ? 'ETA remaining' : 'Est. time',
                ),
                if (_navigationStarted) ...[
                  const SizedBox(width: 10),
                  _statBox(
                    Icons.schedule_rounded,
                    _etaTime,
                    'Arrival',
                  ),
                ],
              ],
            ),

            // Progress bar (visible during navigation)
            if (_navigationStarted) ...[
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Progress',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                      const Spacer(),
                      Text('${(_progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: AppTheme.surfaceAlt,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // CTA button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _navigationStarted
                  ? OutlinedButton.icon(
                      onPressed: _stopNavigation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger),
                      ),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop navigation'),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startNavigation,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Navigation'),
                    ),
            ),

            if (_navigationStarted && _progress >= 1.0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                    SizedBox(width: 8),
                    Text('You have arrived at your destination!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppTheme.success)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statBox(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.primary),
                const SizedBox(width: 5),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
