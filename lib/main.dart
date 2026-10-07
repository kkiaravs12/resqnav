import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/auth_page.dart';
import 'features/emergency/emergency_page.dart';
import 'features/explore/explore_page.dart';
import 'features/history/history_page.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_page.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ApiService.initializeAuth();
    if (ApiService.isAuthenticated) {
      try {
        await ApiService.getProfile();
      } catch (e) {
        // Profile fetch error handled silently
      }
    }
  } catch (e) {
    // Auth initialization error handled silently
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ResQNavApp(),
    ),
  );
}

class ResQNavApp extends StatefulWidget {
  const ResQNavApp({super.key});

  @override
  State<ResQNavApp> createState() => _ResQNavAppState();
}

class _ResQNavAppState extends State<ResQNavApp> {
  bool _authenticated = ApiService.isAuthenticated;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: _authenticated
              ? MainShell(
                  onLogout: () => setState(() => _authenticated = false),
                )
              : AuthPage(
                  onAuthenticated: () => setState(() => _authenticated = true),
                ),
        );
      },
    );
  }
}

// ============================================================
// MAIN SHELL
// ============================================================

class MainShell extends StatefulWidget {
  final VoidCallback onLogout;

  const MainShell({super.key, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _titles = ['Home', 'Explore', 'Emergency', 'History', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final mobile = constraints.maxWidth < 800;
      return mobile ? _buildMobile() : _buildDesktop();
    });
  }

  // ══════════════════════════════════════════════════════════
  // MOBILE
  // ══════════════════════════════════════════════════════════

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _mobileTopBar(),
            Expanded(child: _page()),
          ],
        ),
      ),
      bottomNavigationBar: _mobileNavBar(),
      // ── Global SOS FAB ──────────────────────────────────
      floatingActionButton: _selectedIndex != 2
          ? _SOSButton(
              onTap: () => _handleSOSTrigger(context),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _mobileTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: AppTheme.primaryGlow,
            ),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ),
          IconButton(
            onPressed: _showNotifications,
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimary),
          ),
          CircleAvatar(
            radius: 17,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
            child: Text(ApiService.displayInitial,
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _mobileNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
              _navItem(Icons.search_outlined, Icons.search_rounded, 'Explore', 1),
              _navItem(Icons.emergency_outlined, Icons.emergency_rounded, 'SOS', 2,
                  isEmergency: true),
              _navItem(Icons.history_outlined, Icons.history_rounded, 'History', 3),
              _navItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index, {
    bool isEmergency = false,
  }) {
    final sel = _selectedIndex == index;
    final colour =
        isEmergency ? AppTheme.danger : (sel ? AppTheme.primary : AppTheme.textSecondary);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppTheme.animNormal,
          padding: const EdgeInsets.symmetric(vertical: 7),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: sel ? colour.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sel ? activeIcon : icon, size: 22, color: colour),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: colour)),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // DESKTOP
  // ══════════════════════════════════════════════════════════

  Widget _buildDesktop() {
    return Scaffold(
      body: Row(
        children: [
          _desktopSidebar(),
          Expanded(
            child: Column(
              children: [
                _desktopTopBar(),
                Expanded(child: _page()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopSidebar() {
    return Container(
      width: 248,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 26),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.primaryGlow,
                  ),
                  child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 11),
                const Text('ResQNav',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sideItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                _sideItem(Icons.search_outlined, Icons.search_rounded, 'Explore', 1),
                _sideItem(Icons.emergency_outlined, Icons.emergency_rounded, 'Emergency', 2,
                    isEmergency: true),
                _sideItem(Icons.history_outlined, Icons.history_rounded, 'History', 3),
                _sideItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 4),
              ],
            ),
          ),

          // ── SOS panel ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: _SOSButton(
              fullWidth: true,
              onTap: () => _handleSOSTrigger(context),
            ),
          ),

          // Location pill
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Location services',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                ),
                Icon(Icons.check_circle, color: AppTheme.success, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(
    IconData icon,
    IconData activeIcon,
    String title,
    int index, {
    bool isEmergency = false,
  }) {
    final sel = _selectedIndex == index;
    final colour =
        isEmergency ? AppTheme.danger : (sel ? AppTheme.primary : AppTheme.textSecondary);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: AppTheme.animNormal,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? colour.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(sel ? activeIcon : icon, color: colour, size: 20),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: colour)),
          ],
        ),
      ),
    );
  }

  Widget _desktopTopBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: Colors.white,
      child: Row(
        children: [
          Text(_titles[_selectedIndex],
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const Spacer(),
          IconButton(
            onPressed: _showNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          // Profile button - click to go to profile page
          InkWell(
            onTap: () {
              setState(() => _selectedIndex = 4); // Navigate to Profile page
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                    child: Text(ApiService.displayInitial,
                        style: const TextStyle(
                            color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  Text(ApiService.displayName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE SWITCHER
  // ══════════════════════════════════════════════════════════

  Widget _page() {
    switch (_selectedIndex) {
      case 0: return const HomePage();
      case 1: return const ExplorePage();
      case 2: return const EmergencyPage();
      case 3: return const HistoryPage();
      case 4: return ProfilePage(onLogout: widget.onLogout);
      default: return const SizedBox();
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NotificationsSheet(),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SOS EMERGENCY ALERT
  // ══════════════════════════════════════════════════════════

  Future<void> _handleSOSTrigger(BuildContext context) async {
    // Show SOS confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SOSConfirmationDialog(),
    );

    if (confirmed == true) {
      if (!mounted) return;
      await _triggerEmergencyAlert(this.context);
    }
  }

  Future<void> _triggerEmergencyAlert(BuildContext context) async {
    try {
      // Get current location
      Position? position;
      String locationText = '';
      
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions denied');
        }

        // Get current position
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );

        final pos = position!;

        // Try to get address from coordinates
        try {
          final placemarks = await placemarkFromCoordinates(
            pos.latitude,
            pos.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final addressParts = [
              place.street,
              place.subLocality,
              place.locality,
              place.administrativeArea,
              place.postalCode,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
            
            locationText = addressParts.isNotEmpty ? addressParts : '';
          }
        } catch (e) {
          // Geocoding failed, use coordinates only
        }

        // Prepare location message
        final lat = pos.latitude.toStringAsFixed(6);
        final lon = pos.longitude.toStringAsFixed(6);
        final googleMapsUrl = 'https://www.google.com/maps?q=$lat,$lon';
        
        final message = '''
🆘 EMERGENCY SOS ALERT 🆘

I need immediate help! This is an emergency alert from ResQNav app.

📍 My Current Location:
${locationText.isNotEmpty ? '$locationText\n' : ''}Coordinates: $lat, $lon

🗺️ View on Google Maps:
$googleMapsUrl

⚠️ Please respond immediately or call emergency services!

Time: ${DateTime.now().toString().substring(0, 19)}
        '''.trim();

        // Share location to any contact
        await Share.share(
          message,
          subject: '🆘 EMERGENCY SOS ALERT',
        );

        // Check context is still mounted after async operation
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency location shared successfully!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 3),
          ),
        );
        
      } catch (e) {
        // Location error
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to get location: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share emergency location: ${e.toString()}'),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

// ============================================================
// GLOBAL SOS BUTTON
// ============================================================

class _SOSButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool fullWidth;

  const _SOSButton({required this.onTap, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    if (fullWidth) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: AppTheme.dangerGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.dangerGlow,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sos_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOS Emergency',
                        style: TextStyle(color: Colors.white, fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    Text('Alert your contacts',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Compact FAB version
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: AppTheme.danger,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.sos_rounded, size: 22),
      label: const Text('SOS',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
    );
  }
}

// ============================================================
// SOS CONFIRMATION DIALOG
// ============================================================

class _SOSConfirmationDialog extends StatefulWidget {
  @override
  State<_SOSConfirmationDialog> createState() => _SOSConfirmationDialogState();
}

class _SOSConfirmationDialogState extends State<_SOSConfirmationDialog> {
  int _countdown = 5;
  bool _canCancel = true;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
          if (_countdown == 0) _canCancel = false;
        });
        _startCountdown();
      } else if (mounted && _countdown == 0) {
        // Auto-confirm
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.danger,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sos_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Emergency SOS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will share your current location with emergency contacts via any app (WhatsApp, SMS, Email, etc.).',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.danger.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Auto-confirming in',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.danger.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.danger,
                  ),
                ),
                Text(
                  _countdown == 1 ? 'second' : 'seconds',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.danger.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_canCancel) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
          icon: const Icon(Icons.sos_rounded, size: 18),
          label: const Text('Send Alert'),
        ),
      ],
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final alerts = await ApiService.getEmergencyAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'SOS and emergency notifications from this account.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 40, color: AppTheme.primary.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    const Text(
                      'You are all caught up.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SOS alerts you send will appear here.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final alert = _alerts[i];
                    final status = alert['status']?.toString() ?? 'active';
                    final type = alert['alert_type']?.toString() ?? 'sos';
                    final message = alert['message']?.toString() ?? 'Emergency alert';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.danger.withValues(alpha: 0.12),
                            child: const Icon(Icons.sos_rounded,
                                color: AppTheme.danger, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: status == 'active'
                                  ? AppTheme.danger
                                  : AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
