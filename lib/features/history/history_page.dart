import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../navigation/navigation_page.dart';

@JS('computeResQNavRoute')
external void computeResQNavRoute(
  JSNumber originLat,
  JSNumber originLng,
  JSNumber destinationLat,
  JSNumber destinationLng,
  JSString travelMode,
  JSFunction callback,
);

// ============================================================
// HISTORY PAGE
// ============================================================

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryItem> _allHistory   = [];
  String _searchQuery    = '';
  String _filterType     = 'All'; // All | Navigation | Emergency

  bool _loading    = true;
  bool _clearing   = false;
  bool _navigating = false;

  String? _errorMessage;

  // ── derived ──────────────────────────────────────────────
  List<HistoryItem> get _filtered {
    var list = _allHistory;

    if (_filterType != 'All') {
      list = list.where((e) => e.type == _filterType).toList();
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) =>
          e.title.toLowerCase().contains(q) ||
          e.subtitle.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  // ── stats ─────────────────────────────────────────────────
  int get _destCount  => _allHistory.where((e) => e.type == 'Navigation').length;
  int get _emergCount => _allHistory.where((e) => e.type == 'Emergency').length;
  double get _totalKm  =>
      _allHistory.fold<double>(0, (s, e) => s + e.distanceMeters) / 1000;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ══════════════════════════════════════════════════════════
  // DATA
  // ══════════════════════════════════════════════════════════

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() { _loading = true; _errorMessage = null; });

    try {
      final data = await ApiService.getHistory();
      if (!mounted) return;
      setState(() {
        _allHistory = data.map(HistoryItem.fromJson).toList();
        _loading    = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _errorMessage = e.message; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _errorMessage = 'Unable to load your history.'; });
    }
  }

  Future<void> _deleteItem(HistoryItem item) async {
    try {
      await ApiService.deleteHistory(item.id);
      if (!mounted) return;
      setState(() => _allHistory.removeWhere((e) => e.id == item.id));
      _snack('Entry deleted.');
    } catch (_) {
      _snack('Unable to delete this entry.');
    }
  }

  Future<void> _clearAll() async {
    if (_allHistory.isEmpty || _clearing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
        title: const Text('Clear all history?'),
        content: const Text(
            'This will permanently remove all your saved search history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _clearing = true);
    try {
      await ApiService.clearHistory();
      if (!mounted) return;
      setState(() => _allHistory.clear());
      _snack('History cleared.');
    } catch (_) {
      await _loadHistory();
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _viewAgain(HistoryItem item) async {
    if (_navigating || !item.hasDestination) return;
    setState(() => _navigating = true);

    try {
      final origin = await _getLocation();
      if (origin == null || !mounted) {
        setState(() => _navigating = false);
        return;
      }

      computeResQNavRoute(
        origin.latitude.toJS,
        origin.longitude.toJS,
        item.latitude.toJS,
        item.longitude.toJS,
        'car'.toJS,
        ((String pathJson, double dist, double dur) {
          if (!mounted) return;
          try {
            final pts = (jsonDecode(pathJson) as List)
                .map((p) => LatLng((p['lat'] as num).toDouble(),
                    (p['lng'] as num).toDouble()))
                .toList();

            if (pts.isEmpty) throw Exception('No route.');

            setState(() => _navigating = false);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NavigationPage(
                  destinationName: item.title,
                  destinationAddress: item.subtitle,
                  currentLocation: origin,
                  destinationLocation: LatLng(item.latitude, item.longitude),
                  routePoints: pts,
                  distanceMeters: dist,
                  durationMilliseconds: dur,
                  travelMode: 'car',
                ),
              ),
            );
          } catch (_) {
            if (mounted) setState(() => _navigating = false);
            _snack('Unable to build directions.');
          }
        }).toJS,
      );
    } catch (_) {
      if (mounted) setState(() => _navigating = false);
      _snack('Unable to open this destination.');
    }
  }

  Future<LatLng?> _getLocation() async {
    try {
      final svcOk = await Geolocator.isLocationServiceEnabled();
      if (!svcOk) { _snack('Location services are disabled.'); return null; }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('Location permission denied.'); return null;
      }

      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      _snack('Unable to get your location.');
      return null;
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final mobile = constraints.maxWidth < 700;
      return RefreshIndicator(
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(mobile ? 16 : 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(mobile),
                  const SizedBox(height: 20),
                  _buildStats(mobile),
                  const SizedBox(height: 20),
                  _buildSearchAndFilter(mobile),
                  const SizedBox(height: 16),
                  _buildContent(mobile),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(bool mobile) {
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _iconBox(Icons.history_rounded, AppTheme.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('History',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                Text('Recent destinations & emergency searches.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _allHistory.isEmpty || _clearing ? null : _clearAll,
              icon: _clearing
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline_rounded, size: 17),
              label: Text(_clearing ? 'Clearing…' : 'Clear history'),
            ),
          ),
        ],
      );
    }

    return Row(children: [
      _iconBox(Icons.history_rounded, AppTheme.primary),
      const SizedBox(width: 14),
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('History',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          Text('Your recent destinations and emergency searches.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ]),
      ),
      OutlinedButton.icon(
        onPressed: _allHistory.isEmpty || _clearing ? null : _clearAll,
        icon: _clearing
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.delete_outline_rounded, size: 17),
        label: Text(_clearing ? 'Clearing…' : 'Clear history'),
      ),
    ]);
  }

  Widget _iconBox(IconData icon, Color colour) => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      color: colour.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: colour, size: 24),
  );

  // ── Stats ─────────────────────────────────────────────────
  Widget _buildStats(bool mobile) {
    final cards = [
      _StatData(Icons.navigation_rounded, '$_destCount', 'Destinations', AppTheme.primary),
      _StatData(Icons.emergency_rounded, '$_emergCount', 'Emergency', AppTheme.danger),
      _StatData(Icons.route_rounded, '${_totalKm.toStringAsFixed(1)} km',
          'Total distance', AppTheme.success),
    ];

    if (mobile) {
      return Column(children: [
        Row(children: [
          Expanded(child: _statCard(cards[0])),
          const SizedBox(width: 10),
          Expanded(child: _statCard(cards[1])),
        ]),
        const SizedBox(height: 10),
        _statCard(cards[2], fullWidth: true),
      ]);
    }

    return Row(children: [
      for (var i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(width: 14),
        Expanded(child: _statCard(cards[i])),
      ],
    ]);
  }

  Widget _statCard(_StatData d, {bool fullWidth = false}) => Container(
    width: fullWidth ? double.infinity : null,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: d.colour.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(d.icon, color: d.colour, size: 21),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          Text(d.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      )),
    ]),
  );

  // ── Search + Filter ───────────────────────────────────────
  Widget _buildSearchAndFilter(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search history…',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () => setState(() => _searchQuery = ''),
                    icon: const Icon(Icons.close_rounded, size: 18))
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        // Filter chips
        Wrap(
          spacing: 8,
          children: ['All', 'Navigation', 'Emergency'].map((type) {
            final sel = _filterType == type;
            return FilterChip(
              label: Text(type),
              selected: sel,
              onSelected: (_) => setState(() => _filterType = type),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primary.withValues(alpha: 0.10),
              checkmarkColor: AppTheme.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? AppTheme.primary : AppTheme.textSecondary,
              ),
              side: BorderSide(
                color: sel ? AppTheme.primary : AppTheme.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Content ───────────────────────────────────────────────
  Widget _buildContent(bool mobile) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_allHistory.isEmpty) {
      return _buildEmpty();
    }

    final items = _filtered;

    if (items.isEmpty) {
      return _buildNoMatch();
    }

    return Column(children: [
      // Result count
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Text('${items.length} ${items.length == 1 ? 'entry' : 'entries'}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
      ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCard(item, mobile),
          )),
    ]);
  }

  // ── Card ─────────────────────────────────────────────────
  Widget _buildCard(HistoryItem item, bool mobile) {
    final isEmergency = item.type == 'Emergency';
    final iconColour  = isEmergency ? AppTheme.danger : AppTheme.primary;

    return Container(
      padding: EdgeInsets.all(mobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge + 2),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: iconColour.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: iconColour, size: 23),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      _typeBadge(item.type, isEmergency),
                    ]),
                    const SizedBox(height: 4),
                    Text(item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _metaChip(Icons.route_rounded, item.distanceText),
                        _metaChip(Icons.access_time_rounded, item.timeText),
                        _metaChip(Icons.calendar_today_rounded, item.date),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (item.hasDestination)
                TextButton.icon(
                  onPressed: _navigating ? null : () => _viewAgain(item),
                  icon: _navigating
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.navigation_rounded, size: 15),
                  label: Text(_navigating ? 'Opening…' : 'Navigate again'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: _navigating ? null : () => _deleteItem(item),
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded, size: 20,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type, bool emergency) {
    final colour = emergency ? AppTheme.danger : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(type,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colour)),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.primary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
      ],
    );
  }

  // ── States ────────────────────────────────────────────────
  Widget _buildEmpty() => _stateBox(
    icon: Icons.history_toggle_off_rounded,
    title: 'No history yet',
    subtitle: 'Your destinations and emergency searches will appear here.',
  );

  Widget _buildNoMatch() => _stateBox(
    icon: Icons.search_off_rounded,
    title: 'No results found',
    subtitle: 'Try a different search term or filter.',
  );

  Widget _buildError() => _stateBox(
    icon: Icons.wifi_off_rounded,
    title: 'Failed to load history',
    subtitle: _errorMessage ?? 'Something went wrong.',
    actionLabel: 'Retry',
    onAction: _loadHistory,
  );

  Widget _stateBox({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      );
}

// ============================================================
// HISTORY ITEM MODEL
// ============================================================

class HistoryItem {
  final int id;
  final String searchType;
  final String query;
  final String destinationName;
  final String destinationAddress;
  final String category;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double durationSeconds;
  final DateTime createdAt;

  const HistoryItem({
    required this.id,
    required this.searchType,
    required this.query,
    required this.destinationName,
    required this.destinationAddress,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id:                 (json['id'] as num?)?.toInt()     ?? 0,
      searchType:          json['search_type']?.toString()  ?? 'destination',
      query:               json['query']?.toString()        ?? '',
      destinationName:     json['destination_name']?.toString() ?? '',
      destinationAddress:  json['destination_address']?.toString() ?? '',
      category:            json['category']?.toString()    ?? '',
      latitude:  (json['latitude']  as num?)?.toDouble()   ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble()   ?? 0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get type => searchType == 'emergency' ? 'Emergency' : 'Navigation';

  String get title {
    if (destinationName.isNotEmpty) return destinationName;
    if (query.isNotEmpty) return query;
    return 'Unknown destination';
  }

  String get subtitle {
    if (destinationAddress.isNotEmpty) return destinationAddress;
    if (type == 'Emergency') return 'Emergency service';
    return 'Recent search';
  }

  bool get hasDestination => latitude != 0 && longitude != 0;

  IconData get icon {
    switch (searchType) {
      case 'emergency':
        switch (category.toLowerCase()) {
          case 'hospital':   return Icons.local_hospital_rounded;
          case 'police':     return Icons.local_police_rounded;
          case 'fire station': return Icons.local_fire_department_rounded;
          case 'pharmacy':   return Icons.local_pharmacy_rounded;
          default:           return Icons.emergency_rounded;
        }
      default:
        return Icons.location_on_rounded;
    }
  }

  String get distanceText {
    if (distanceMeters <= 0) return '—';
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get timeText {
    final mins = (durationSeconds / 60).round();
    if (mins <= 0) return '—';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get date {
    final d = createdAt.toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

// ── Stat helper ───────────────────────────────────────────────
class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color colour;
  const _StatData(this.icon, this.value, this.label, this.colour);
}
