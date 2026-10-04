import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_launcher.dart';
import '../../services/api_service.dart';
import '../emergency/emergency_page.dart';
import '../explore/explore_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> recentHistory = [];
  bool historyLoading = false;

  // Live clock
  late Timer _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadRecentHistory();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadRecentHistory() async {
    if (!ApiService.isAuthenticated) return;
    setState(() => historyLoading = true);
    try {
      final items = await ApiService.getHistory();
      if (mounted) {
        setState(() {
          recentHistory = items.take(5).toList();
          historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => historyLoading = false);
    }
  }

  void _openExplore(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExplorePage()),
    ).then((_) => _loadRecentHistory());
  }

  void _openEmergency(BuildContext context, {String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmergencyPage(initialCategory: category)),
    ).then((_) => _loadRecentHistory());
  }

  // ── Greeting ──────────────────────────────────────────────
  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _timeString {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateString {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final d = _now;
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final mobile = constraints.maxWidth < 800;
      return RefreshIndicator(
        onRefresh: _loadRecentHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            mobile ? 18 : 32,
            mobile ? 20 : 28,
            mobile ? 18 : 32,
            mobile ? 32 : 40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(mobile),
                  SizedBox(height: mobile ? 20 : 28),
                  _buildSearchBar(context, mobile),
                  SizedBox(height: mobile ? 20 : 28),
                  _buildQuickDials(mobile),
                  SizedBox(height: mobile ? 22 : 30),
                  _buildMainCards(context, mobile),
                  SizedBox(height: mobile ? 24 : 32),
                  _buildQuickAccess(context, mobile),
                  SizedBox(height: mobile ? 24 : 32),
                  _buildRecentSection(context, mobile),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════════
  // HERO BANNER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeroBanner(bool mobile) {
    final name = ApiService.currentUserName?.trim();
    final hasName = name != null && name.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 20 : 26),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
        boxShadow: AppTheme.primaryGlow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting${hasName ? ', $name' : ''}!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: mobile ? 22 : 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stay safe. We\'ve got you covered.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: mobile ? 13 : 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _heroPill(Icons.access_time_rounded, _timeString),
                    const SizedBox(width: 10),
                    _heroPill(Icons.calendar_today_rounded, _dateString),
                  ],
                ),
              ],
            ),
          ),
          if (!mobile) ...[
            const SizedBox(width: 20),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SEARCH BAR
  // ══════════════════════════════════════════════════════════
  Widget _buildSearchBar(BuildContext context, bool mobile) {
    return GestureDetector(
      onTap: () => _openExplore(context),
      child: Container(
        height: mobile ? 52 : 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Search a destination or place…',
                style: TextStyle(fontSize: 13, color: AppTheme.textHint),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.near_me_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Explore',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // QUICK DIALS
  // ══════════════════════════════════════════════════════════
  Widget _buildQuickDials(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.phone_rounded, size: 16, color: AppTheme.danger),
            const SizedBox(width: 7),
            Text(
              'Emergency numbers',
              style: TextStyle(
                fontSize: mobile ? 15 : 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: AppConstants.quickDials.length,
            itemBuilder: (_, i) => _quickDialChip(AppConstants.quickDials[i]),
          ),
        ),
      ],
    );
  }

  Widget _quickDialChip(QuickDial dial) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: () => _showCallDialog(dial.label, dial.number),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: dial.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(dial.icon, size: 15, color: dial.color),
              ),
              const SizedBox(height: 5),
              Text(
                dial.number,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: dial.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCallDialog(String label, String number) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_rounded, color: AppTheme.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Text(
          'Call emergency number $number?',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              launchPhoneNumber(context, number, label: label);
            },
            icon: const Icon(Icons.call_rounded, size: 16),
            label: Text('Call $number'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // MAIN CARDS
  // ══════════════════════════════════════════════════════════
  Widget _buildMainCards(BuildContext context, bool mobile) {
    if (mobile) {
      return Column(
        children: [
          _buildEmergencyCard(context, mobile: true),
          const SizedBox(height: 14),
          _buildExploreCard(context, mobile: true),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildExploreCard(context, mobile: false)),
        const SizedBox(width: 18),
        Expanded(flex: 2, child: _buildEmergencyCard(context, mobile: false)),
      ],
    );
  }

  Widget _buildEmergencyCard(BuildContext context, {required bool mobile}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: InkWell(
        onTap: () => _openEmergency(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(mobile ? 18 : 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: mobile
              ? Row(
                  children: [
                    _emergencyIcon(mobile),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Need emergency help?',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          const Text('Hospitals, police, fire & more.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(height: 10),
                          _emergencyCTA(),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _emergencyIcon(mobile),
                    const SizedBox(height: 14),
                    const Text('Need emergency help?',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    const Text(
                        'Find nearby emergency services using your location.',
                        style: TextStyle(fontSize: 13, height: 1.4,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),
                    _emergencyCTA(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _emergencyIcon(bool mobile) {
    return Container(
      width: mobile ? 50 : 46,
      height: mobile ? 50 : 46,
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.emergency_rounded, color: AppTheme.danger, size: 26),
    );
  }

  Widget _emergencyCTA() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Find help',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          SizedBox(width: 5),
          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  Widget _buildExploreCard(BuildContext context, {required bool mobile}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: InkWell(
        onTap: () => _openExplore(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          width: double.infinity,
          height: mobile ? 150 : 220,
          padding: EdgeInsets.all(mobile ? 18 : 22),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: AppTheme.primaryGlow,
          ),
          child: Stack(
            children: [
              Positioned(
                right: mobile ? -20 : -22,
                bottom: mobile ? -40 : -32,
                child: Icon(Icons.map_rounded,
                    size: mobile ? 148 : 180,
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: mobile ? 42 : 46,
                    height: mobile ? 42 : 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.explore_rounded, color: Colors.white,
                        size: mobile ? 22 : 24),
                  ),
                  SizedBox(height: mobile ? 10 : 14),
                  Text('Explore anywhere',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: mobile ? 18 : 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Search places, view map and get directions.',
                      maxLines: 2,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: mobile ? 11.5 : 13,
                          height: 1.35)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // QUICK ACCESS GRID
  // ══════════════════════════════════════════════════════════
  Widget _buildQuickAccess(BuildContext context, bool mobile) {
    final items = [
      _QuickItem(Icons.local_hospital_outlined, 'Hospitals',
          'Emergency medical', () => _openEmergency(context, category: 'Hospital')),
      _QuickItem(Icons.local_pharmacy_outlined, 'Pharmacies',
          'Nearby medicines', () => _openEmergency(context, category: 'Pharmacy')),
      _QuickItem(Icons.local_police_outlined, 'Police',
          'Safety assistance', () => _openEmergency(context, category: 'Police')),
      _QuickItem(Icons.local_fire_department_outlined, 'Fire Stations',
          'Fire & rescue', () => _openEmergency(context, category: 'Fire Station')),
      _QuickItem(Icons.emergency_outlined, 'Ambulance',
          'Medical transport', () => _openEmergency(context, category: 'Ambulance')),
      _QuickItem(Icons.map_outlined, 'Explore Map',
          'Directions & search', () => _openExplore(context)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick access',
            style: TextStyle(
                fontSize: mobile ? 18 : 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 13),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: mobile ? 2 : 3,
            crossAxisSpacing: mobile ? 10 : 14,
            mainAxisSpacing: mobile ? 10 : 14,
            childAspectRatio: mobile ? 1.6 : 2.4,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _quickCard(items[i]),
        ),
      ],
    );
  }

  Widget _quickCard(_QuickItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 3),
                    Text(item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textHint),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // RECENT DESTINATIONS
  // ══════════════════════════════════════════════════════════
  Widget _buildRecentSection(BuildContext context, bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent destinations',
                  style: TextStyle(
                      fontSize: mobile ? 18 : 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
            ),
            TextButton(
              onPressed: () => _openExplore(context),
              child: const Text('Explore map',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (historyLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (recentHistory.isEmpty)
          _buildEmptyRecent(context)
        else
          Column(
            children: recentHistory
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _recentItem(
                        context,
                        item['search_type'] == 'emergency'
                            ? Icons.emergency_outlined
                            : Icons.location_on_outlined,
                        item['destination_name']?.toString() ??
                            item['query']?.toString() ??
                            'Recent search',
                        item['destination_address']?.toString() ??
                            (item['search_type'] == 'emergency'
                                ? 'Emergency service'
                                : 'Recent destination'),
                        isEmergency: item['search_type'] == 'emergency',
                        onTap: () => _openExplore(context),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyRecent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, color: AppTheme.primary, size: 26),
          ),
          const SizedBox(height: 12),
          const Text('No recent destinations',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 5),
          const Text('Destinations you navigate to will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openExplore(context),
            icon: const Icon(Icons.explore_rounded, size: 16),
            label: const Text('Start exploring'),
          ),
        ],
      ),
    );
  }

  Widget _recentItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    bool isEmergency = false,
    VoidCallback? onTap,
  }) {
    final colour = isEmergency ? AppTheme.danger : AppTheme.primary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: colour, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private helper model ──────────────────────────────────────
class _QuickItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickItem(this.icon, this.title, this.subtitle, this.onTap);
}