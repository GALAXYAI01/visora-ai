import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showNotifications(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => const Align(
        alignment: Alignment.topCenter,
        child: _NotificationsDropdown(),
      ),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.userName?.trim().isNotEmpty == true ? auth.userName!.trim() : 'User';
    final displayName = user[0].toUpperCase() + user.substring(1);
    final date = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      body: VisoraPage(
        children: [
          VisoraHeader(
            eyebrow: 'Visora console',
            title: '${_greeting()}, $displayName',
            subtitle: '$date | 3 audits need review | System confidence 92%',
            icon: Icons.verified_user_rounded,
            trailing: IconButton.outlined(
              tooltip: 'Notifications',
              onPressed: () => _showNotifications(context),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  Positioned(
                    right: -1,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: VisoraColors.googleRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.04),
          const SizedBox(height: 24),
          _HeroPanel(onNewAudit: () => context.push('/upload'), onScan: () => context.go('/scanner'))
              .animate()
              .fadeIn(delay: 80.ms, duration: 360.ms)
              .slideY(begin: 0.04),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 920 ? 4 : constraints.maxWidth >= 620 ? 2 : 1;
              final itemWidth = (constraints.maxWidth - (columns - 1) * 14) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: const MetricTile(
                      label: 'Total audits',
                      value: '12',
                      helper: '4 active this week',
                      icon: Icons.dataset_rounded,
                      color: VisoraColors.primary,
                      progress: 0.72,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const MetricTile(
                      label: 'High risk',
                      value: '3',
                      helper: 'Needs owner approval',
                      icon: Icons.warning_rounded,
                      color: VisoraColors.error,
                      progress: 0.25,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const MetricTile(
                      label: 'Avg fairness',
                      value: '84%',
                      helper: '+2.4% from last month',
                      icon: Icons.trending_up_rounded,
                      color: VisoraColors.success,
                      progress: 0.84,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const MetricTile(
                      label: 'Reports ready',
                      value: '7',
                      helper: 'PDF exports available',
                      icon: Icons.picture_as_pdf_rounded,
                      color: VisoraColors.googleYellow,
                      progress: 0.58,
                    ),
                  ),
                ],
              );
            },
          ).animate().fadeIn(delay: 140.ms, duration: 340.ms),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final recent = _RecentAudits(onViewAll: () => context.go('/reports'));
              final actions = _WorkflowPanel(onUpload: () => context.push('/upload'));
              if (!wide) {
                return Column(children: [recent, const SizedBox(height: 16), actions]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: recent),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: actions),
                ],
              );
            },
          ).animate().fadeIn(delay: 220.ms, duration: 380.ms),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final VoidCallback onNewAudit;
  final VoidCallback onScan;

  const _HeroPanel({required this.onNewAudit, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      prominent: true,
      padding: const EdgeInsets.all(0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 780;
          final buttonWidth = wide ? null : math.max(0.0, constraints.maxWidth - 40);
          final textPanel = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SeverityBadge(label: 'Live governance'),
              const SizedBox(height: 18),
              Text(
                'Audit AI decisions before they reach people.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Upload datasets, inspect text policies, simulate protected attributes, and generate compliance-ready reports from one workspace.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: wide ? 168 : buttonWidth,
                    child: GradientButton(
                      label: 'New Audit',
                      icon: Icons.add_rounded,
                      onPressed: onNewAudit,
                    ),
                  ),
                  SizedBox(
                    width: wide ? 172 : buttonWidth,
                    child: GradientButton(
                      label: 'Scan Text',
                      icon: Icons.document_scanner_rounded,
                      onPressed: onScan,
                      secondary: true,
                    ),
                  ),
                ],
              ),
            ],
          );
          return Padding(
            padding: EdgeInsets.all(wide ? 28 : 20),
            child: Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wide) Expanded(flex: 3, child: textPanel) else textPanel,
                if (wide) const SizedBox(width: 28) else const SizedBox(height: 24),
                SizedBox(
                  width: wide ? 310 : double.infinity,
                  height: 220,
                  child: const _FairnessCanvas(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FairnessCanvas extends StatefulWidget {
  const _FairnessCanvas();

  @override
  State<_FairnessCanvas> createState() => _FairnessCanvasState();
}

class _FairnessCanvasState extends State<_FairnessCanvas> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _FairnessPainter(_controller.value, Theme.of(context).brightness == Brightness.dark),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                'Fairness score 84%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: VisoraColors.success,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FairnessPainter extends CustomPainter {
  final double t;
  final bool dark;

  _FairnessPainter(this.t, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [const Color(0xFF1A1D21), const Color(0xFF203A5E)]
            : [const Color(0xFFE8F0FE), const Color(0xFFFFFFFF)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      bg,
    );

    final linePaint = Paint()
      ..color = (dark ? Colors.white : VisoraColors.primary).withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (int i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), linePaint);
    }
    for (int i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 18), Offset(x, size.height - 18), linePaint);
    }

    final bars = [0.78, 0.42, 0.64, 0.86, 0.71, 0.53];
    final colors = [
      VisoraColors.googleBlue,
      VisoraColors.googleRed,
      VisoraColors.googleYellow,
      VisoraColors.googleGreen,
      VisoraColors.primary,
      VisoraColors.success,
    ];
    final width = (size.width - 72) / bars.length;
    for (int i = 0; i < bars.length; i++) {
      final animated = bars[i] * (0.92 + math.sin((t * math.pi * 2) + i) * 0.045);
      final h = animated * (size.height - 72);
      final rect = Rect.fromLTWH(32 + i * width, size.height - 34 - h, width * 0.52, h);
      final paint = Paint()..color = colors[i].withValues(alpha: 0.78);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), paint);
    }

    final arcPaint = Paint()
      ..color = VisoraColors.primary.withValues(alpha: 0.58)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width - 60, 58);
    canvas.drawArc(Rect.fromCircle(center: center, radius: 32), -math.pi / 2, 1.65 * math.pi, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _FairnessPainter oldDelegate) => oldDelegate.t != t || oldDelegate.dark != dark;
}

class _RecentAudits extends StatelessWidget {
  final VoidCallback onViewAll;
  const _RecentAudits({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Recent audits', actionLabel: 'View reports', onAction: onViewAll),
        const SizedBox(height: 12),
        _AuditRow(
          name: 'Credit scoring v1.2',
          detail: 'Today, 09:41 | Automated pipeline',
          severity: 'Critical bias',
          icon: Icons.account_balance_rounded,
          color: VisoraColors.error,
        ),
        const SizedBox(height: 10),
        _AuditRow(
          name: 'Facial recognition beta',
          detail: 'Yesterday, 14:22 | Manual scan',
          severity: 'Warning',
          icon: Icons.visibility_rounded,
          color: VisoraColors.warning,
        ),
        const SizedBox(height: 10),
        _AuditRow(
          name: 'NLP chatbot core',
          detail: 'Apr 18, 11:05 | Weekly check',
          severity: 'Compliant',
          icon: Icons.chat_bubble_outline_rounded,
          color: VisoraColors.success,
        ),
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  final String name;
  final String detail;
  final String severity;
  final IconData icon;
  final Color color;

  const _AuditRow({
    required this.name,
    required this.detail,
    required this.severity,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      onTap: () => context.push('/results'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SeverityBadge(label: severity),
        ],
      ),
    );
  }
}

class _WorkflowPanel extends StatelessWidget {
  final VoidCallback onUpload;
  const _WorkflowPanel({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Governance flow'),
        const SizedBox(height: 12),
        VisoraCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _FlowStep(
                icon: Icons.upload_file_rounded,
                color: VisoraColors.googleBlue,
                title: 'Ingest',
                body: 'CSV datasets and policy text',
                active: true,
              ),
              const _FlowConnector(),
              _FlowStep(
                icon: Icons.analytics_rounded,
                color: VisoraColors.googleYellow,
                title: 'Evaluate',
                body: 'Fairness metrics and Gemini review',
                active: true,
              ),
              const _FlowConnector(),
              _FlowStep(
                icon: Icons.auto_fix_high_rounded,
                color: VisoraColors.googleGreen,
                title: 'Remediate',
                body: 'Generate reports and deploy fixes',
                active: false,
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Start Dataset Audit',
                icon: Icons.play_arrow_rounded,
                onPressed: onUpload,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool active;

  const _FlowStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, top: 6, bottom: 6),
      child: Container(width: 2, height: 22, color: Theme.of(context).dividerColor),
    );
  }
}

class _NotificationsDropdown extends StatelessWidget {
  const _NotificationsDropdown();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.warning_amber_rounded,
        color: VisoraColors.error,
        title: 'High-risk bias detected',
        subtitle: 'Hiring dataset flagged. Gender ratio 0.62',
        time: '2 min'
      ),
      (
        icon: Icons.check_circle_outline_rounded,
        color: VisoraColors.success,
        title: 'Audit complete',
        subtitle: 'Loan approval model passed thresholds',
        time: '1 hr'
      ),
      (
        icon: Icons.auto_fix_high_rounded,
        color: VisoraColors.primary,
        title: 'Remediation draft ready',
        subtitle: 'Recommended class weights generated',
        time: '3 hrs'
      ),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        constraints: const BoxConstraints(maxWidth: 460),
        child: VisoraCard(
          prominent: true,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  children: [
                    Icon(Icons.notifications_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Notifications', style: Theme.of(context).textTheme.titleMedium)),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                  ],
                ),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, color: item.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 3),
                            Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(item.time, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
