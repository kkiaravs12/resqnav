import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/api_service.dart';

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ── State ─────────────────────────────────────────────────
  bool _notificationsEnabled   = true;
  bool _locationEnabled        = true;
  bool _emergencyAlertsEnabled = true;

  bool _profileLoading = true;
  bool _logoutLoading  = false;

  String _name    = 'ResQNav User';
  String _email   = '';
  String _initial = 'R';

  String? _profileError;

  List<Map<String, dynamic>> _contacts     = [];
  bool _contactsLoading = false;
  // ignore: unused_field
  bool _contactsLoaded  = false;

  // Activity stats
  int    _totalSearches = 0;
  int    _destCount     = 0;
  int    _emergCount    = 0;
  double _totalKm       = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ══════════════════════════════════════════════════════════
  // DATA
  // ══════════════════════════════════════════════════════════

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() { _profileLoading = true; _profileError = null; });

    try {
      final data = await ApiService.getProfile();

      final fullName  = data['full_name']?.toString().trim();
      final firstName = data['first_name']?.toString().trim();
      final lastName  = data['last_name']?.toString().trim();
      final username  = data['username']?.toString().trim();
      final email     = data['email']?.toString().trim();

      String name = '';
      if (fullName != null && fullName.isNotEmpty) {
        name = fullName;
      } else if (firstName != null && firstName.isNotEmpty) {
        name = (lastName != null && lastName.isNotEmpty)
            ? '$firstName $lastName' : firstName;
      } else if (username != null && username.isNotEmpty) {
        name = username;
      } else if (email != null && email.isNotEmpty) {
        name = email;
      }
      if (name.isEmpty) name = 'ResQNav User';

      if (!mounted) return;
      setState(() {
        _name    = name;
        _email   = email ?? '';
        _initial = name.substring(0, 1).toUpperCase();
        _profileLoading = false;
      });

      _loadContacts();
      _loadStats();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _profileLoading = false; _profileError = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _profileLoading = false; _profileError = 'Unable to load profile.'; });
    }
  }

  Future<void> _loadStats() async {
    try {
      final history = await ApiService.getHistory();
      if (!mounted) return;
      final dest  = history.where((e) => e['search_type'] == 'destination').length;
      final emerg = history.where((e) => e['search_type'] == 'emergency').length;
      final km    = history.fold<double>(
          0, (s, e) => s + ((e['distance_meters'] as num?)?.toDouble() ?? 0)) / 1000;

      setState(() {
        _totalSearches = history.length;
        _destCount     = dest;
        _emergCount    = emerg;
        _totalKm       = km;
      });
    } catch (_) {}
  }

  Future<void> _loadContacts() async {
    if (_contactsLoading) return;
    setState(() => _contactsLoading = true);
    try {
      final data = await ApiService.getEmergencyContacts();
      if (!mounted) return;
      setState(() { _contacts = data; _contactsLoading = false; _contactsLoaded = true; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _contactsLoading = false; _contactsLoaded = true; });
    }
  }

  Future<void> _logout() async {
    if (_logoutLoading) return;
    setState(() => _logoutLoading = true);
    try {
      await ApiService.logout();
    } catch (_) {}
    if (!mounted) return;
    widget.onLogout();
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
    return LayoutBuilder(builder: (context, constraints) {
      final mobile = constraints.maxWidth < 800;
      return SingleChildScrollView(
        padding: EdgeInsets.all(mobile ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: mobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ),
      );
    });
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 20),
        _buildProfileCard(),
        const SizedBox(height: 16),
        _buildActivityStats(),
        const SizedBox(height: 16),
        _buildContactsCard(),
        const SizedBox(height: 16),
        _buildPreferencesCard(),
        const SizedBox(height: 16),
        _buildAboutCard(),
        const SizedBox(height: 16),
        _buildLogoutButton(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              flex: 5,
              child: Column(children: [
                _buildProfileCard(),
                const SizedBox(height: 18),
                _buildActivityStats(),
                const SizedBox(height: 18),
                _buildContactsCard(),
              ]),
            ),
            const SizedBox(width: 20),
            // Right column
            Expanded(
              flex: 4,
              child: Column(children: [
                _buildPreferencesCard(),
                const SizedBox(height: 18),
                _buildAboutCard(),
                const SizedBox(height: 18),
                _buildLogoutButton(),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  // ── Page header ───────────────────────────────────────────
  Widget _buildPageHeader() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Profile',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      SizedBox(height: 4),
      Text('Manage your account and preferences.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    ],
  );

  // ── Profile card ─────────────────────────────────────────
  Widget _buildProfileCard() {
    return _card(
      child: _profileLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()))
          : Column(children: [
              Row(children: [
                // Avatar
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_initial,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                            color: AppTheme.primary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_email.isNotEmpty ? _email : 'No email set',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                )),
                TextButton.icon(
                  onPressed: _showEditProfile,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit'),
                ),
              ]),
              if (_profileError != null) ...[
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.danger),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_profileError!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.danger))),
                  TextButton(onPressed: _loadProfile, child: const Text('Retry')),
                ]),
              ],
            ]),
    );
  }

  // ── Activity stats ────────────────────────────────────────
  Widget _buildActivityStats() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Your activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _miniStat('$_totalSearches', 'Total searches',
                Icons.history_rounded, AppTheme.primary)),
            const SizedBox(width: 10),
            Expanded(child: _miniStat('$_destCount', 'Destinations',
                Icons.navigation_rounded, AppTheme.info)),
            const SizedBox(width: 10),
            Expanded(child: _miniStat('$_emergCount', 'Emergency',
                Icons.emergency_rounded, AppTheme.danger)),
          ]),
          const SizedBox(height: 10),
          _miniStat('${_totalKm.toStringAsFixed(1)} km', 'Total distance navigated',
              Icons.route_rounded, AppTheme.success, fullWidth: true),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, IconData icon, Color colour,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colour.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: colour),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colour)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        )),
      ]),
    );
  }

  // ── Emergency contacts ───────────────────────────────────
  Widget _buildContactsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.danger, size: 19),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Emergency contacts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary))),
            TextButton.icon(
              onPressed: () => _showContactDialog(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add'),
            ),
          ]),
          const SizedBox(height: 4),
          if (_contactsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Icon(Icons.person_add_outlined, size: 17,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(width: 9),
                const Text('No emergency contacts yet.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            )
          else
            Column(
              children: _contacts.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 1),
                    _contactTile(c),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _contactTile(Map<String, dynamic> c) {
    final isPrimary = c['is_primary'] == true;
    final name = c['name']?.toString() ?? '—';
    final phone = c['phone']?.toString() ?? '';
    final rel = c['relationship']?.toString() ?? 'Family';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: (isPrimary ? AppTheme.danger : AppTheme.primary).withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isPrimary ? Icons.star_rounded : Icons.person_outline_rounded,
          size: 20,
          color: isPrimary ? AppTheme.danger : AppTheme.primary,
        ),
      ),
      title: Row(children: [
        Expanded(child: Text(name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary))),
        if (isPrimary) _badge('Primary', AppTheme.danger),
      ]),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text('$rel · $phone',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _iconBtn(Icons.edit_outlined, AppTheme.textSecondary, () => _showContactDialog(existing: c)),
        _iconBtn(Icons.delete_outline_rounded, AppTheme.danger, () => _deleteContact(c)),
      ]),
    );
  }

  // ── Preferences ──────────────────────────────────────────
  Widget _buildPreferencesCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.settings_rounded, 'Preferences'),
          const SizedBox(height: 4),
          _switchTile(
            Icons.dark_mode_rounded, 'Dark Mode',
            'Use dark theme for the app.',
            themeProvider.isDarkMode,
            (v) => themeProvider.toggleTheme(),
          ),
          const Divider(height: 1),
          _switchTile(
            Icons.notifications_rounded, 'Notifications',
            'Receive route updates and alerts.',
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
          ),
          const Divider(height: 1),
          _switchTile(
            Icons.location_on_rounded, 'Location access',
            'Allow ResQNav to use your location.',
            _locationEnabled,
            (v) => setState(() => _locationEnabled = v),
          ),
          const Divider(height: 1),
          _switchTile(
            Icons.warning_amber_rounded, 'Emergency alerts',
            'Show emergency service information.',
            _emergencyAlertsEnabled,
            (v) => setState(() => _emergencyAlertsEnabled = v),
          ),
        ],
      ),
    );
  }

  // ── About ─────────────────────────────────────────────────
  Widget _buildAboutCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTitle(Icons.info_outline_rounded, 'About ResQNav'),
        const SizedBox(height: 6),
        _actionTile(Icons.description_outlined, 'About the project',
            'Unified navigation & emergency service locator.', _showAboutDialog),
        const Divider(height: 1),
        _actionTile(Icons.verified_rounded, 'Version',
            '${AppConstants.appName} v${AppConstants.appVersion}', null),
        const Divider(height: 1),
        _actionTile(Icons.help_outline_rounded, 'Help & support',
            'Contact the development team.', () => _snack('support@resqnav.app')),
      ],
    ),
  );

  // ── Logout ────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logoutLoading ? null : _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.danger,
          side: const BorderSide(color: AppTheme.danger),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: _logoutLoading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.danger))
            : const Icon(Icons.logout_rounded),
        label: Text(_logoutLoading ? 'Logging out…' : 'Sign out'),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════════════════════════

  Future<void> _showEditProfile() async {
    final nameCtrl  = TextEditingController(text: _name == 'ResQNav User' ? '' : _name);
    final emailCtrl = TextEditingController(text: _email);
    final formKey   = GlobalKey<FormState>();
    bool saving     = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
        title: const Text('Edit profile'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'Enter a valid name';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: saving ? null : () async {
              if (!formKey.currentState!.validate()) return;
              setS(() => saving = true);
              try {
                final data = await ApiService.updateProfile(
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                );
                final newName = data['full_name']?.toString().trim() ?? nameCtrl.text.trim();
                final newEmail = data['email']?.toString().trim() ?? emailCtrl.text.trim();
                if (mounted) {
                  setState(() {
                  _name    = newName.isNotEmpty ? newName : nameCtrl.text.trim();
                  _email   = newEmail;
                  _initial = _name.substring(0, 1).toUpperCase();
                });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _snack('Profile updated.');
              } on ApiException catch (e) {
                setS(() => saving = false);
                _snack(e.message);
              } catch (_) {
                setS(() => saving = false);
                _snack('Unable to update profile.');
              }
            },
            child: saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
        ],
      )),
    );
  }

  Future<void> _showContactDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl  = TextEditingController(text: existing?['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone']?.toString() ?? '');
    final relCtrl   = TextEditingController(
        text: existing?['relationship']?.toString() ?? 'Family');
    bool isPrimary  = existing?['is_primary'] == true;
    final formKey   = GlobalKey<FormState>();
    bool saving     = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
        title: Text(existing == null ? 'Add contact' : 'Edit contact'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: relCtrl,
              decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.group_outlined)),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Primary contact',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: isPrimary,
              onChanged: (v) => setS(() => isPrimary = v),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: saving ? null : () async {
              if (!formKey.currentState!.validate()) return;
              setS(() => saving = true);
              final payload = {
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'relationship': relCtrl.text.trim().isEmpty ? 'Family' : relCtrl.text.trim(),
                'is_primary': isPrimary,
              };
              try {
                if (existing != null) {
                  await ApiService.updateEmergencyContact(existing['id'] as int, payload);
                } else {
                  await ApiService.createEmergencyContact(payload);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadContacts();
              } catch (_) {
                setS(() => saving = false);
                _snack('Unable to save contact.');
              }
            },
            child: saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      )),
    );
  }

  Future<void> _deleteContact(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
        title: const Text('Delete contact?'),
        content: Text('Remove ${c['name']} from your contacts?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteEmergencyContact(c['id'] as int);
      setState(() => _contacts.removeWhere((e) => e['id'] == c['id']));
      _snack('Contact deleted.');
    } catch (_) {
      _snack('Unable to delete contact.');
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
        title: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.navigation_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('ResQNav'),
        ]),
        content: const Text(
          'ResQNav is a Smart Emergency & Navigation App built as a final-year '
          'project.\n\n'
          '• Search any destination and get turn-by-turn directions\n'
          '• Locate nearby hospitals, police, fire stations, pharmacies & ambulances\n'
          '• Manage emergency contacts\n'
          '• View full navigation history\n\n'
          'Built with Flutter (Web) + Django REST Framework.',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SHARED BUILDERS
  // ══════════════════════════════════════════════════════════

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      border: Border.all(color: AppTheme.border),
      boxShadow: AppTheme.cardShadow,
    ),
    child: child,
  );

  Widget _cardTitle(IconData icon, String label) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppTheme.primary, size: 19),
    ),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary)),
  ]);

  Widget _switchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          )),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primary),
        ]),
      );

  Widget _actionTile(IconData icon, String title, String subtitle, VoidCallback? onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            )),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textHint),
          ]),
        ),
      );

  Widget _badge(String label, Color colour) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: colour.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colour)),
  );

  Widget _iconBtn(IconData icon, Color colour, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Icon(icon, size: 18, color: colour),
    ),
  );
}
