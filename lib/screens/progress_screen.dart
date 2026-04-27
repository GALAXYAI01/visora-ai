import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with TickerProviderStateMixin {
  WebSocketChannel? _channel;
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _connectWs();
  }

  void _connectWs() {
    final auditId = ref.read(currentAuditIdProvider);
    if (auditId == null) return;
    final wsUrl = '${ApiService.wsUrl}/ws/audit/$auditId';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _channel!.stream.listen((message) {
      final event = jsonDecode(message as String) as Map<String, dynamic>;
      ref.read(progressProvider.notifier).update(event);
      if (event['type'] == 'complete') {
        final resultData = event['result'] as Map<String, dynamic>?;
        if (resultData != null) {
          final result = AuditResult.fromJson(resultData);
          ref.read(auditResultProvider.notifier).state = result;
        }
        Future.delayed(500.ms, () {
          if (mounted) context.go('/results');
        });
      }
    }, onError: (_) {
      ref.read(progressProvider.notifier).update({'type': 'error', 'message': 'Connection lost'});
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final pct = (progress.pct / 100).clamp(0.0, 1.0);

    return Scaffold(
      body: Stack(
        children: [
          VisoraPage(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
            maxWidth: 1040,
            children: [
              VisoraHeader(
                eyebrow: 'Audit pipeline',
                title: 'Analyzing dataset',
                subtitle: 'Five evaluators are checking data integrity, fairness metrics, counterfactuals, explainability, and Gemini summary.',
                icon: Icons.sync_rounded,
              ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.04),
              const SizedBox(height: 26),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 850;
                  final progressCard = _ProgressCard(progress: progress, pct: pct);
                  final timeline = _PipelineTimeline(progress: progress, spinController: _spinController);
                  if (!wide) {
                    return Column(children: [progressCard, const SizedBox(height: 16), timeline]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: progressCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: timeline),
                    ],
                  );
                },
              ).animate().fadeIn(delay: 120.ms, duration: 360.ms).slideY(begin: 0.04),
              const SizedBox(height: 16),
              if (progress.error != null)
                InfoBanner(
                  icon: Icons.wifi_off_rounded,
                  title: 'Pipeline connection issue',
                  body: progress.error!,
                  color: VisoraColors.error,
                ).animate().fadeIn().shakeX(hz: 3, amount: 3),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 4,
              value: pct,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: const AlwaysStoppedAnimation(VisoraColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ProgressState progress;
  final double pct;

  const _ProgressCard({required this.progress, required this.pct});

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      prominent: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: _CircularProgressPainter(pct, Theme.of(context).dividerColor),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${progress.pct}%', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('complete', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            progress.isDone ? 'Audit complete' : '${progress.completedAgents.length} of 5 agents complete',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            progress.isDone ? 'Preparing results view' : '~${((1 - pct) * 60).round()} seconds remaining',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          const InfoBanner(
            icon: Icons.memory_rounded,
            title: 'Multi-agent review',
            body: 'Each stage reports back independently so a stalled backend can surface quickly.',
            color: VisoraColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PipelineTimeline extends StatelessWidget {
  final ProgressState progress;
  final AnimationController spinController;

  const _PipelineTimeline({required this.progress, required this.spinController});

  @override
  Widget build(BuildContext context) {
    final agents = [
      ('Data Integrity', 'Data Integrity Check', Icons.fact_check_rounded),
      ('Fairness Evaluator', 'Fairness Metric Calculation', Icons.balance_rounded),
      ('Counterfactual Test', 'Counterfactual Fairness Test', Icons.compare_arrows_rounded),
      ('SHAP Explainer', 'SHAP Explanation', Icons.account_tree_rounded),
      ('Gemini Analysis', 'Gemini Summary', Icons.auto_awesome_rounded),
    ];

    return VisoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evaluation timeline', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Live status from the audit websocket.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          ...agents.asMap().entries.map((entry) {
            final index = entry.key;
            final agent = entry.value;
            final completed = progress.completedAgents.contains(agent.$2);
            final current = progress.currentAgent == agent.$2;
            return _AgentTimelineItem(
              name: agent.$1,
              keyName: agent.$2,
              icon: agent.$3,
              completed: completed,
              current: current,
              isLast: index == agents.length - 1,
              spinController: spinController,
            ).animate().fadeIn(delay: (index * 70).ms, duration: 260.ms).slideX(begin: 0.03);
          }),
        ],
      ),
    );
  }
}

class _AgentTimelineItem extends StatelessWidget {
  final String name;
  final String keyName;
  final IconData icon;
  final bool completed;
  final bool current;
  final bool isLast;
  final AnimationController spinController;

  const _AgentTimelineItem({
    required this.name,
    required this.keyName,
    required this.icon,
    required this.completed,
    required this.current,
    required this.isLast,
    required this.spinController,
  });

  @override
  Widget build(BuildContext context) {
    final color = completed ? VisoraColors.success : current ? VisoraColors.primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: completed || current ? 0.14 : 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: completed || current ? 0.28 : 0.12)),
                ),
                child: Center(
                  child: completed
                      ? Icon(Icons.check_rounded, size: 20, color: color)
                      : current
                          ? RotationTransition(turns: spinController, child: Icon(Icons.sync_rounded, size: 20, color: color))
                          : Icon(icon, size: 19, color: color),
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: Theme.of(context).dividerColor)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: current ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35) : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: current ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.24) : Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: current ? Theme.of(context).colorScheme.primary : null)),
                          const SizedBox(height: 3),
                          Text(keyName, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    SeverityBadge(label: completed ? 'Verified' : current ? 'Processing' : 'Queued'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;

  _CircularProgressPainter(this.progress, this.trackColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final active = Paint()
      ..shader = VisoraColors.primaryGradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.trackColor != trackColor;
  }
}
