import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_provider.dart';
import '../services/settings_provider.dart';

/// Open the profile drawer from any screen
void showProfileDrawer(BuildContext context, WidgetRef ref) {
  final auth = ref.read(authProvider);
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Profile',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim, anim2) => Align(
      alignment: Alignment.centerRight,
      child: ProfileDrawer(
        userName: auth.userName ?? 'User',
        onLogout: () {
          Navigator.pop(ctx);
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        },
      ),
    ),
    transitionBuilder: (ctx, anim, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

// ── Profile Side Drawer ──
class ProfileDrawer extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;
  const ProfileDrawer({super.key, required this.userName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final initials = userName[0].toUpperCase();
    final displayName = userName[0].toUpperCase() + userName.substring(1);
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final border = Theme.of(context).dividerColor;

    return Material(
      color: bg,
      child: SafeArea(
        child: SizedBox(
          width: math.min(MediaQuery.of(context).size.width * 0.86, 380),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 12, 20),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF1A73E8)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: VisoraColors.primary.withValues(alpha: 0.3), blurRadius: 12)]),
                  child: Center(child: Text(initials, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text('$userName@visora.ai', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                    child: Text('Admin', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: cs.primary)),
                  ),
                ])),
                IconButton(icon: Icon(Icons.close, color: cs.onSurface.withValues(alpha: 0.5), size: 22), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            Divider(height: 1, color: border),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
              _DrawerItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
                  builder: (_) => _EditProfileSheet(userName: userName));
              }),
              _DrawerItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
                  builder: (_) => const _SettingsSheet());
              }),
              _DrawerItem(icon: Icons.shield_outlined, label: 'Security & Privacy', onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
                  builder: (_) => const _SecuritySheet());
              }),
              _DrawerItem(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
                  builder: (_) => const _HelpSheet());
              }),
            ])),
            Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                  label: Text('Sign Out', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VisoraColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.onSurface.withValues(alpha: 0.6), size: 22),
      title: Text(label, style: GoogleFonts.inter(fontSize: 15, color: cs.onSurface)),
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.4), size: 20),
      onTap: onTap,
    );
  }
}

// ── Edit Profile (with real password change) ──
class _EditProfileSheet extends ConsumerStatefulWidget {
  final String userName;
  const _EditProfileSheet({required this.userName});
  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  String _status = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.userName);
    _emailCtrl = TextEditingController(text: '${widget.userName}@visora.ai');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _oldPwCtrl.dispose(); _newPwCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(color: bg,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          Row(children: [
            Icon(Icons.person_outline_rounded, color: cs.primary),
            const SizedBox(width: 10),
            Text('Edit Profile', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
          ]),
          const SizedBox(height: 20),
          _field('Display Name', _nameCtrl, Icons.badge_outlined),
          const SizedBox(height: 14),
          _field('Email', _emailCtrl, Icons.email_outlined),
          const SizedBox(height: 20),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          Text('Change Password', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 12),
          _field('Current Password', _oldPwCtrl, Icons.lock_outline, obscure: true),
          const SizedBox(height: 14),
          _field('New Password', _newPwCtrl, Icons.lock_reset_rounded, obscure: true),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_status, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
              color: _status.contains('Success') ? const Color(0xFF34A853) : cs.error)),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Save display name
                if (_nameCtrl.text.trim().isNotEmpty) {
                  ref.read(authProvider.notifier).updateUserName(_nameCtrl.text.trim());
                }
                // Change password if fields filled
                if (_oldPwCtrl.text.isNotEmpty && _newPwCtrl.text.isNotEmpty) {
                  if (_newPwCtrl.text.length < 4) {
                    setState(() => _status = 'New password must be at least 4 characters');
                    return;
                  }
                  final ok = await ref.read(authProvider.notifier).changePassword(_oldPwCtrl.text, _newPwCtrl.text);
                  if (ok) {
                    setState(() => _status = '✓ Success! Password changed.');
                    _oldPwCtrl.clear(); _newPwCtrl.clear();
                    Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context); });
                  } else {
                    setState(() => _status = 'Current password is incorrect');
                  }
                  return;
                }
                setState(() => _status = '✓ Success! Profile updated.');
                Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context); });
              },
              icon: Icon(_status.contains('Success') ? Icons.check_circle : Icons.save_rounded, color: Colors.white, size: 18),
              label: Text(_status.contains('Success') ? 'Saved!' : 'Save Changes',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _status.contains('Success') ? const Color(0xFF34A853) : cs.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl, obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)),
    );
  }
}

// ── Settings (wired to settingsProvider, no language) ──
class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(color: bg,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          Row(children: [
            Icon(Icons.settings_outlined, color: cs.primary),
            const SizedBox(width: 10),
            Text('Settings', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
          ]),
          const SizedBox(height: 20),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text('Push Notifications', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
            subtitle: Text('Receive bias alerts', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
            value: s.notifications, onChanged: (v) => n.setNotifications(v),
            activeColor: cs.primary,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_fix_high),
            title: Text('Auto-Scan Uploads', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
            subtitle: Text('Automatically scan new datasets', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
            value: s.autoScan, onChanged: (v) => n.setAutoScan(v),
            activeColor: cs.primary,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.analytics_outlined),
            title: Text('Usage Analytics', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
            subtitle: Text('Share anonymous usage data', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
            value: s.analytics, onChanged: (v) => n.setAnalytics(v),
            activeColor: cs.primary,
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('App Version', style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface)),
            trailing: Text('v1.0.0', style: GoogleFonts.inter(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ── Security (no biometric) ──
class _SecuritySheet extends StatefulWidget {
  const _SecuritySheet();
  @override
  State<_SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends State<_SecuritySheet> {
  bool _twoFactor = true;
  bool _encryptExports = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      decoration: BoxDecoration(color: bg,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          Row(children: [
            Icon(Icons.shield_outlined, color: cs.primary),
            const SizedBox(width: 10),
            Text('Security & Privacy', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF34A853).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF34A853).withValues(alpha: 0.3))),
            child: Row(children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF34A853), size: 32),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AES-256 Encryption Active', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF34A853))),
                const SizedBox(height: 2),
                Text('All data is encrypted end-to-end', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          SwitchListTile(secondary: const Icon(Icons.security),
            title: Text('Two-Factor Auth', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
            subtitle: Text('2FA via authenticator app', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
            value: _twoFactor, onChanged: (v) => setState(() => _twoFactor = v), activeColor: cs.primary),
          SwitchListTile(secondary: const Icon(Icons.enhanced_encryption_outlined),
            title: Text('Encrypt Exports', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
            subtitle: Text('Encrypt all PDF & CSV exports', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
            value: _encryptExports, onChanged: (v) => setState(() => _encryptExports = v), activeColor: cs.primary),
          const Divider(),
          _infoRow('Session', 'Active — expires in 23h'),
          _infoRow('Last Login', 'Today at ${TimeOfDay.now().format(context)}'),
          _infoRow('Encryption', 'AES-256-GCM'),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface)),
      ]),
    );
  }
}

// ── Help & Support ──
class _HelpSheet extends StatelessWidget {
  const _HelpSheet();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      decoration: BoxDecoration(color: bg,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          Row(children: [
            Icon(Icons.help_outline_rounded, color: cs.primary),
            const SizedBox(width: 10),
            Text('Help & Support', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
          ]),
          const SizedBox(height: 20),
          _faq(context, 'How do I run a bias audit?', 'Navigate to the Home tab and click "New Audit." Upload a CSV dataset, and Visora will analyze it for disparate impact, statistical parity, and other fairness metrics.'),
          _faq(context, 'What file formats are supported?', 'Visora supports CSV files for dataset audits. For text scanning, paste any text into the Scanner tab.'),
          _faq(context, 'How is my data protected?', 'All data is encrypted with AES-256-GCM both at rest and in transit. Session tokens are hashed.'),
          _faq(context, 'Can I export audit reports?', 'Yes! After any audit completes, click "Download Report" to get a compliance-ready PDF.'),
          _faq(context, 'What fairness metrics does Visora use?', 'Disparate Impact Ratio, Statistical Parity, Equalized Odds, Equal Opportunity, and Calibration.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.email_outlined, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Contact Support', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                Text('support@visora.ai', style: GoogleFonts.inter(fontSize: 12, color: cs.primary)),
              ])),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Visora AI v1.0.0', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _faq(BuildContext context, String q, String a) {
    final cs = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(q, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [Text(a, style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: cs.onSurface.withValues(alpha: 0.7)))],
    );
  }
}
