import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/app_theme.dart';
import '../services/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  void _showProfile(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(
        userName: auth.userName ?? 'User',
        onLogout: () {
          Navigator.pop(context);
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth.userName ?? 'User';
    final displayName = name[0].toUpperCase() + name.substring(1);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      backgroundColor: VisoraColors.background,
      body: SafeArea(
        child: Stack(fit: StackFit.expand, children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Mobile Header ──
              Row(children: [
                Icon(Icons.security_update_good_rounded, color: VisoraColors.primary, size: 28),
                const SizedBox(width: 8),
                Text('Visora', style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
                const Spacer(),
                // Bell icon → notifications
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showNotifications(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: VisoraColors.surfaceLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: VisoraColors.outlineVariant),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
                      child: Stack(children: [
                        const Center(child: Icon(Icons.notifications_outlined, color: VisoraColors.onSurfaceVariant, size: 20)),
                        Positioned(top: 8, right: 8,
                          child: Container(width: 8, height: 8,
                            decoration: BoxDecoration(color: VisoraColors.error, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)))),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Profile avatar → profile sheet
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showProfile(context, ref),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF1A73E8)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: VisoraColors.primary.withValues(alpha: 0.3), blurRadius: 6)]),
                      child: Center(child: Text(
                        displayName[0].toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      )),
                    ),
                  ),
                ),
              ]).animate().fadeIn(duration: 300.ms).slideY(begin: -0.15),

              const SizedBox(height: 24),

              // ── Greeting ──
              Text('${_greeting()}, $displayName', style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w700, color: VisoraColors.onSurface, letterSpacing: -0.3))
                .animate().fadeIn(delay: 50.ms, duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 4),
              Text('$dateStr · 3 audits pending', style: GoogleFonts.inter(
                fontSize: 14, color: VisoraColors.onSurfaceVariant))
                .animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // ── System Overview Card ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(children: [
                Align(alignment: Alignment.centerLeft,
                  child: Text('System Overview', style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w600, color: VisoraColors.onSurface))),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _StatCol(label: 'TOTAL AUDITS', value: '12', color: VisoraColors.onSurface)),
                  Expanded(child: _StatCol(label: 'HIGH RISK', value: '3', color: VisoraColors.error)),
                  Expanded(child: _StatCol(label: 'AVG FAIRNESS', value: '84', color: VisoraColors.primary, suffix: '%')),
                ]),
                const SizedBox(height: 16),
                Divider(color: VisoraColors.surface, height: 1),
                const SizedBox(height: 16),
                Row(children: [
                  // Donut chart
                  SizedBox(width: 48, height: 48,
                    child: CustomPaint(painter: _DonutPainter(0.84))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Model Fairness Score', style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500, color: VisoraColors.onSurface)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.trending_up_rounded, color: VisoraColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text('+2.4% vs last month', style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500, color: VisoraColors.success)),
                    ]),
                  ])),
                  MouseRegion(cursor: SystemMouseCursors.click,
                    child: GestureDetector(onTap: () => context.go('/reports'),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('VIEW REPORT', style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: VisoraColors.primary, letterSpacing: 0.5)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: VisoraColors.primary, size: 18),
                      ]))),
                ]),
              ])).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.08),

              const SizedBox(height: 16),

              // ── AI Insight Card ──
              Container(
                decoration: BoxDecoration(
                  color: VisoraColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VisoraColors.outlineVariant),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(children: [
                  // Blue top accent
                  Container(height: 4,
                    decoration: BoxDecoration(
                      color: VisoraColors.primary,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)))),
                  Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.auto_awesome_rounded, color: VisoraColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('AI Insight', style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                    ]),
                    const SizedBox(height: 12),
                    RichText(text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant, height: 1.6),
                      children: [
                        const TextSpan(text: 'Neural mapping detected a '),
                        TextSpan(text: '4.2% gender skew', style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.error)),
                        const TextSpan(text: " in the latest candidate screening model (v2.4). Recommend adjusting weights for feature 'X-42'."),
                      ],
                    )),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Confidence Level', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: VisoraColors.onSurfaceVariant)),
                      Text('92%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: VisoraColors.primary)),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: 0.92,
                        backgroundColor: VisoraColors.surface,
                        valueColor: const AlwaysStoppedAnimation(VisoraColors.primary), minHeight: 6)),
                    const SizedBox(height: 16),
                    MouseRegion(cursor: SystemMouseCursors.click,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Analyze Model Weights', style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: VisoraColors.primary)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: VisoraColors.primary, size: 16),
                      ])),
                  ])),
                ]),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.08),

              const SizedBox(height: 32),

              // ── Recent Audits ──
              Row(children: [
                Text('Recent Audits', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                const Spacer(),
                MouseRegion(cursor: SystemMouseCursors.click,
                  child: GestureDetector(onTap: () => context.go('/reports'),
                    child: Text('View All', style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500, color: VisoraColors.primary)))),
              ]).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 12),

              _AuditCard(name: 'Credit_Scoring_v1.2.pkl', date: 'Today, 09:41 AM · Triggered by automated pipeline', severity: 'CRITICAL BIAS', icon: Icons.gavel_rounded, iconColor: VisoraColors.error, iconBg: VisoraColors.errorContainer)
                .animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: 0.08),
              const SizedBox(height: 12),
              _AuditCard(name: 'Facial_Rec_Beta_EU.onnx', date: 'Yesterday, 14:22 PM · Manual scan by J. Doe', severity: 'WARNING', icon: Icons.visibility_rounded, iconColor: VisoraColors.warning, iconBg: VisoraColors.warningBg)
                .animate().fadeIn(delay: 450.ms, duration: 400.ms).slideX(begin: 0.08),
              const SizedBox(height: 12),
              _AuditCard(name: 'NLP_Chatbot_Core.pt', date: 'Apr 18, 11:05 AM · Routine weekly check', severity: 'COMPLIANT', icon: Icons.check_circle_rounded, iconColor: VisoraColors.success, iconBg: VisoraColors.tertiaryContainer)
                .animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: 0.08),
            ]),
          ),

          // ── FAB ──
          Positioned(
            bottom: 88, right: 20,
            child: MouseRegion(cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.push('/upload'),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: VisoraColors.primary,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: [BoxShadow(color: VisoraColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('New Audit', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  ]),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
          ),
        ]),
      ),
    );
  }
}

// ── Stat Column ──
class _StatCol extends StatelessWidget {
  final String label, value; final Color color; final String? suffix;
  const _StatCol({required this.label, required this.value, required this.color, this.suffix});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 0.5)),
    const SizedBox(height: 6),
    RichText(text: TextSpan(children: [
      TextSpan(text: value, style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: color)),
      if (suffix != null) TextSpan(text: suffix, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w400, color: VisoraColors.onSurfaceVariant)),
    ])),
  ]);
}

// ── Audit Card ──
class _AuditCard extends StatelessWidget {
  final String name, date, severity;
  final IconData icon; final Color iconColor, iconBg;
  const _AuditCard({required this.name, required this.date, required this.severity, required this.icon, required this.iconColor, required this.iconBg});
  @override
  Widget build(BuildContext context) {
    final stripColor = severity == 'CRITICAL BIAS' ? VisoraColors.error : severity == 'WARNING' ? VisoraColors.warning : VisoraColors.success;
    return MouseRegion(cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: () => context.push('/results'),
        child: Container(
          decoration: BoxDecoration(
            color: VisoraColors.surfaceLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VisoraColors.outlineVariant),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Stack(children: [
            Positioned(left: 0, top: 0, bottom: 0,
              child: Container(width: 4,
                decoration: BoxDecoration(
                  color: stripColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))))),
            Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 20)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.onSurface), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(date, style: GoogleFonts.inter(fontSize: 12, color: VisoraColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                ])),
                const SizedBox(width: 8),
                SeverityBadge(label: severity),
              ])),
          ]),
        ),
      ),
    );
  }
}

// ── Donut Painter ──
class _DonutPainter extends CustomPainter {
  final double progress;
  _DonutPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    canvas.drawCircle(c, r, Paint()..color = VisoraColors.surfaceHigh..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -1.5708, progress * 6.2832, false,
      Paint()..color = VisoraColors.primary..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
    final tp = TextPainter(
      text: TextSpan(text: '${(progress * 100).round()}%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
      textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Notifications Bottom Sheet ──
class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: const BoxDecoration(
        color: VisoraColors.background,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 12, bottom: 4), width: 40, height: 4,
          decoration: BoxDecoration(color: VisoraColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(children: [
            const Icon(Icons.notifications_rounded, color: VisoraColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('Notifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.primary)),
            ),
          ]),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shrinkWrap: true,
            children: const [
              _NotifTile(
                icon: Icons.gavel_rounded, color: VisoraColors.error,
                title: 'Critical Bias Detected',
                subtitle: 'Credit_Scoring_v1.2.pkl — Disparate impact ratio 0.62 (threshold: 0.80)',
                time: '10 min ago', isUnread: true,
              ),
              _NotifTile(
                icon: Icons.check_circle_rounded, color: VisoraColors.success,
                title: 'Audit Passed',
                subtitle: 'NLP_Chatbot_Core.pt passed all fairness checks',
                time: '2 hours ago', isUnread: true,
              ),
              _NotifTile(
                icon: Icons.warning_rounded, color: VisoraColors.warning,
                title: 'Remediation Recommended',
                subtitle: 'Facial_Rec_Beta_EU.onnx — Age group imbalance in training data',
                time: 'Yesterday', isUnread: false,
              ),
              _NotifTile(
                icon: Icons.auto_awesome_rounded, color: VisoraColors.primary,
                title: 'AI Insight Available',
                subtitle: 'New gender skew detected in candidate screening model v2.4',
                time: '2 days ago', isUnread: false,
              ),
              _NotifTile(
                icon: Icons.update_rounded, color: VisoraColors.onSurfaceVariant,
                title: 'System Update',
                subtitle: 'Visora engine updated to v3.1 — improved Equalized Odds metric',
                time: '3 days ago', isUnread: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon; final Color color;
  final String title, subtitle, time;
  final bool isUnread;
  const _NotifTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.time, required this.isUnread});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? VisoraColors.primaryContainer.withValues(alpha: 0.3) : VisoraColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VisoraColors.outlineVariant),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: VisoraColors.onSurface))),
            if (isUnread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: VisoraColors.primary, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 3),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: VisoraColors.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 4),
          Text(time, style: GoogleFonts.inter(fontSize: 11, color: VisoraColors.onSurfaceVariant)),
        ])),
      ]),
    );
  }
}

// ── Profile Bottom Sheet ──
class _ProfileSheet extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;
  const _ProfileSheet({required this.userName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final initials = userName[0].toUpperCase();
    final displayName = userName[0].toUpperCase() + userName.substring(1);

    return Container(
      decoration: const BoxDecoration(
        color: VisoraColors.background,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 12, bottom: 16), width: 40, height: 4,
          decoration: BoxDecoration(color: VisoraColors.outlineVariant, borderRadius: BorderRadius.circular(2))),

        // Avatar + Name
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF1A73E8)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: VisoraColors.primary.withValues(alpha: 0.3), blurRadius: 12)]),
          child: Center(child: Text(initials, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
        const SizedBox(height: 12),
        Text(displayName, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
        const SizedBox(height: 4),
        Text('$userName@visora.ai', style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: VisoraColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Text('Admin', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.primary)),
        ),

        const SizedBox(height: 24),
        const Divider(height: 1),

        // Menu items
        _ProfileMenuItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () => Navigator.pop(context)),
        _ProfileMenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () => Navigator.pop(context)),
        _ProfileMenuItem(icon: Icons.shield_outlined, label: 'Security & Privacy', onTap: () => Navigator.pop(context)),
        _ProfileMenuItem(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () => Navigator.pop(context)),

        const Divider(height: 1),
        const SizedBox(height: 8),

        // Logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ]),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ProfileMenuItem({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Icon(icon, color: VisoraColors.onSurfaceVariant, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 15, color: VisoraColors.onSurface))),
          const Icon(Icons.chevron_right_rounded, color: VisoraColors.outlineVariant, size: 20),
        ]),
      ),
    );
  }
}
