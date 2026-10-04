import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NavigationPage — Google Maps style turn-by-turn navigation
// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Map ──────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;

  // ── Navigation state ─────────────────────────────────────────────────────
  bool _navStarted = false;
  Timer? _ticker;
  late double _remainingMs;
  double _elapsedMs = 0;

  // Simulated user position — walks along routePoints
  int _currentSegment = 0;
  LatLng? _simulatedPosition;

  // ── UI toggle ─────────────────────────────────────────────────────────────
  bool _bottomExpanded = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _remainingMs = widget.durationMilliseconds;
    _simulatedPosition = widget.currentLocation;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation control
  // ─────────────────────────────────────────────────────────────────────────

  void _startNavigation() {
    setState(() => _navStarted = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingMs > 1000) {
          _remainingMs -= 1000;
          _elapsedMs += 1000;
          _advanceSimulatedPosition();
        } else {
          _remainingMs = 0;
          _ticker?.cancel();
        }
      });
    });
  }

  void _stopNavigation() {
    _ticker?.cancel();
    setState(() {
      _navStarted = false;
      _remainingMs = widget.durationMilliseconds;
      _elapsedMs = 0;
      _currentSegment = 0;
      _simulatedPosition = widget.currentLocation;
    });
    _fitRoute();
  }

  /// Advance the blue dot along the polyline proportionally to time elapsed.
  void _advanceSimulatedPosition() {
    if (widget.routePoints.length < 2) return;
    final progress = (_elapsedMs / widget.durationMilliseconds).clamp(0.0, 1.0);
    final totalSegs = widget.routePoints.length - 1;
    final targetSeg = (progress * totalSegs).floor().clamp(0, totalSegs - 1);

    if (targetSeg != _currentSegment) {
      _currentSegment = targetSeg;
      final pos = widget.routePoints[_currentSegment];
      _simulatedPosition = pos;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 17, tilt: 45)),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Map helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _fitRoute() {
    if (_mapController == null || widget.routePoints.isEmpty) return;
    double minLat = widget.routePoints.first.latitude;
    double maxLat = minLat;
    double minLng = widget.routePoints.first.longitude;
    double maxLng = minLng;
    for (final p in widget.routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      90,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Turn-by-turn instruction
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a fake turn instruction based on where we are in the route.
  _TurnInstruction _currentInstruction() {
    final progress = widget.durationMilliseconds > 0
        ? (_elapsedMs / widget.durationMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final remaining = _fmtDist(_remainingMs / widget.durationMilliseconds * widget.distanceMeters);

    if (!_navStarted) {
      return _TurnInstruction(
        icon: Icons.navigation_rounded,
        color: AppTheme.primary,
        primary: 'Head towards ${widget.destinationName}',
        distance: _fmtDist(widget.distanceMeters),
      );
    }

    if (_remainingMs <= 0) {
      return _TurnInstruction(
        icon: Icons.flag_rounded,
        color: AppTheme.success,
        primary: 'You have arrived!',
        distance: '',
      );
    }

    // Cycle through plausible instructions based on progress
    if (progress < 0.15) {
      return _TurnInstruction(
        icon: Icons.straight_rounded,
        color: AppTheme.primary,
        primary: 'Continue straight',
        distance: remaining,
      );
    } else if (progress < 0.30) {
      return _TurnInstruction(
        icon: Icons.turn_right_rounded,
        color: AppTheme.primary,
        primary: 'Turn right',
        distance: remaining,
      );
    } else if (progress < 0.50) {
      return _TurnInstruction(
        icon: Icons.straight_rounded,
        color: AppTheme.primary,
        primary: 'Continue straight',
        distance: remaining,
      );
    } else if (progress < 0.65) {
      return _TurnInstruction(
        icon: Icons.turn_left_rounded,
        color: AppTheme.primary,
        primary: 'Turn left',
        distance: remaining,
      );
    } else if (progress < 0.85) {
      return _TurnInstruction(
        icon: Icons.straight_rounded,
        color: AppTheme.primary,
        primary: 'Continue straight',
        distance: remaining,
      );
    } else {
      return _TurnInstruction(
        icon: Icons.flag_rounded,
        color: AppTheme.success,
        primary: 'Destination ahead',
        distance: remaining,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Formatting
  // ─────────────────────────────────────────────────────────────────────────

  String _fmtDist(double m) {
    if (m <= 0) return '';
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  String _fmtDur(double ms) {
    if (ms <= 0) return '0 min';
    final mins = (ms / 60000).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60, m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get _etaClock {
    final arrival = DateTime.now().add(Duration(milliseconds: _remainingMs.toInt()));
    return '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
  }

  double get _progress =>
      widget.durationMilliseconds > 0
          ? (_elapsedMs / widget.durationMilliseconds).clamp(0.0, 1.0)
          : 0.0;

  bool get _arrived => _remainingMs <= 0 && _navStarted;

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final instruction = _currentInstruction();

    final markers = <Marker>{
      // Destination pin
      Marker(
        markerId: const MarkerId('dest'),
        position: widget.destinationLocation,
        infoWindow: InfoWindow(title: widget.destinationName),
      ),
      // Simulated user position
      if (_simulatedPosition != null)
        Marker(
          markerId: const MarkerId('user'),
          position: _simulatedPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You'),
          zIndexInt: 2,
        ),
    };

    final polylines = <Polyline>{
      if (widget.routePoints.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.routePoints,
          width: 8,
          color: AppTheme.primary,
          geodesic: true,
        ),
      // Travelled portion greyed out
      if (_navStarted && _currentSegment > 0)
        Polyline(
          polylineId: const PolylineId('done'),
          points: widget.routePoints.sublist(0, _currentSegment + 1),
          width: 8,
          color: Colors.grey.shade400,
          geodesic: true,
        ),
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.currentLocation,
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
              },
            ),
          ),

          // ── Top instruction banner ───────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildInstructionBanner(instruction, topPad),
          ),

          // ── Recenter FAB ─────────────────────────────────────────────
          Positioned(
            right: 14,
            bottom: bottomPad + (_navStarted ? 200 : 160) + 16,
            child: _buildFab(
              icon: Icons.navigation_outlined,
              tooltip: 'Re-center',
              onTap: () {
                final pos = _simulatedPosition ?? widget.currentLocation;
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: pos, zoom: _navStarted ? 17 : 14, tilt: _navStarted ? 45 : 0),
                  ),
                );
              },
            ),
          ),

          // ── Bottom panel ─────────────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildBottomPanel(bottomPad),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Instruction banner (Google Maps style — dark blue top bar)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInstructionBanner(_TurnInstruction ins, double topPad) {
    return Container(
      color: _arrived ? AppTheme.success : AppTheme.navy,
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),

          // Turn arrow icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(ins.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),

          // Instruction text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ins.distance.isNotEmpty)
                  Text(
                    ins.distance,
                    style: const TextStyle(
                      fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                Text(
                  ins.primary,
                  style: const TextStyle(
                    fontSize: 19, color: Colors.white, fontWeight: FontWeight.w800,
                    height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom panel
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomPanel(double bottomPad) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black26, offset: Offset(0, -2))],
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle + expand toggle
          GestureDetector(
            onTap: () => setState(() => _bottomExpanded = !_bottomExpanded),
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ETA row
          _buildEtaRow(),

          // Progress bar (only during navigation)
          if (_navStarted) ...[
            const SizedBox(height: 12),
            _buildProgressBar(),
          ],

          const SizedBox(height: 14),

          // Expanded details
          if (_bottomExpanded) ...[
            _buildStatsRow(),
            const SizedBox(height: 14),
          ],

          // Arrived banner
          if (_arrived) ...[
            _buildArrivedBanner(),
            const SizedBox(height: 14),
          ],

          // CTA button
          _buildCtaButton(),
        ],
      ),
    );
  }

  Widget _buildEtaRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big ETA time or distance
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _fmtDur(_navStarted ? _remainingMs : widget.durationMilliseconds),
                    style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary,
                      height: 1),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _fmtDist(_navStarted
                        ? (1 - _progress) * widget.distanceMeters
                        : widget.distanceMeters),
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.flag_outlined, size: 13, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.destinationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ETA clock badge
        if (_navStarted && !_arrived)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(_etaClock,
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                const Text('arrival',
                  style: TextStyle(fontSize: 9, color: AppTheme.textHint,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ],
            ),
          ),

        // Mode icon badge (when not navigating)
        if (!_navStarted)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.travelMode == 'walk'
                  ? Icons.directions_walk_rounded
                  : Icons.directions_car_rounded,
              color: AppTheme.primary, size: 24),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 5,
            backgroundColor: AppTheme.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              _fmtDist(_progress * widget.distanceMeters),
              style: const TextStyle(fontSize: 10, color: AppTheme.textHint,
                fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 10, color: AppTheme.primary,
                fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statBox(Icons.route_rounded, _fmtDist(widget.distanceMeters), 'Total dist.'),
        const SizedBox(width: 10),
        _statBox(Icons.access_time_rounded, _fmtDur(widget.durationMilliseconds), 'Total time'),
        const SizedBox(width: 10),
        _statBox(
          widget.travelMode == 'walk' ? Icons.directions_walk_rounded : Icons.directions_car_rounded,
          widget.travelMode == 'walk' ? 'Walk' : 'Drive',
          'Mode'),
      ],
    );
  }

  Widget _statBox(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 13, color: AppTheme.primary),
              const SizedBox(width: 4),
              Flexible(child: Text(value,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
          SizedBox(width: 8),
          Text('You have arrived at your destination!',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.success)),
        ],
      ),
    );
  }

  Widget _buildCtaButton() {
    if (_arrived) {
      return SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      );
    }

    if (_navStarted) {
      return Row(
        children: [
          // Stop
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _stopNavigation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.stop_rounded, size: 20),
                label: const Text('Stop', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Overview
          SizedBox(
            height: 50, width: 50,
            child: OutlinedButton(
              onPressed: _fitRoute,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Icon(Icons.fit_screen_rounded, size: 20, color: AppTheme.textSecondary),
            ),
          ),
        ],
      );
    }

    // Not started yet
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton.icon(
        onPressed: _startNavigation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: const Text('Start Navigation',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  Widget _buildFab({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 6,
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46, height: 46,
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _TurnInstruction {
  final IconData icon;
  final Color color;
  final String primary;
  final String distance;

  const _TurnInstruction({
    required this.icon,
    required this.color,
    required this.primary,
    required this.distance,
  });
}
