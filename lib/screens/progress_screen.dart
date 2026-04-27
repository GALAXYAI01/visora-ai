import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/providers.dart';
import '../services/api_service.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with TickerProviderStateMixin {
  WebSocketChannel? _channel;
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _connectWs();
  }

  void _connectWs() {
    final auditId = ref.read(currentAuditIdProvider);
    if (auditId == null) return;
    final wsUrl = '${ApiService.wsUrl}/ws/audit/$auditId';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _channel!.stream.listen((msg) {
      final event = jsonDecode(msg as String) as Map<String, dynamic>;
      ref.read(progressProvider.notifier).update(event);
      if (event['type'] == 'complete') {
        final resultData = event['result'] as Map<String, dynamic>?;
        if (resultData != null) {
          final result = AuditResult.fromJson(resultData);
          ref.read(auditResultProvider.notifier).state = result;
        }
        Future.delayed(500.ms, () { if (mounted) context.go('/results'); });
      }
    }, onError: (_) {
      ref.read(progressProvider.notifier).update({'type': 'error', 'message': 'Connection lost'});
    });
  }

  @override
  void dispose() { _channel?.sink.close(); _spinCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final pct = progress.pct / 100.0;
    final agents = [
      {'name': 'Data Integrity', 'key': 'Data Integrity Check'},
      {'name': 'Fairness Evaluator', 'key': 'Fairness Metric Calculation'},
      {'name': 'Counterfactual Test', 'key': 'Counterfactual Fairness Test'},
      {'name': 'SHAP Explainer', 'key': 'SHAP Explanation'},
      {'name': 'Gemini Analysis', 'key': 'Gemini Summary'},
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(fit: StackFit.expand, children: [
          // Top progress bar
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 4, color: VisoraColors.surfaceHigh,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft, widthFactor: pct,
                child: Container(color: VisoraColors.primary)))),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Text('Analyzing Dataset', style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w700, color: VisoraColors.onSurface, letterSpacing: -0.3))
                .animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.dataset_rounded, color: VisoraColors.primary, size: 18),
                const SizedBox(width: 6),
                Text('Running 5-agent pipeline', style: GoogleFonts.inter(
                  fontSize: 14, color: VisoraColors.onSurfaceVariant)),
              ]).animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 40),

              // Circular progress
              Center(child: VisoraCard(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  SizedBox(width: 192, height: 192,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(pct),
                      child: Center(child: Text('${progress.pct}%',
                        style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, color: VisoraColors.primary))))),
                  const SizedBox(height: 16),
                  Text('${progress.completedAgents.length} OF 5 AGENTS COMPLETE',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                      color: VisoraColors.onSurfaceVariant, letterSpacing: 1)),
                ]),
              )).animate().fadeIn(delay: 100.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 32),

              // Agent Timeline
              ...agents.asMap().entries.map((entry) {
                final i = entry.key;
                final agent = entry.value;
                final completed = progress.completedAgents.contains(agent['key']);
                final isCurrent = progress.currentAgent == agent['key'];
                return _AgentTimelineItem(
                  name: agent['name']!,
                  status: completed ? 'complete' : isCurrent ? 'active' : 'pending',
                  isLast: i == agents.length - 1,
                  spinCtrl: _spinCtrl,
                ).animate().fadeIn(delay: (200 + i * 80).ms, duration: 300.ms).slideX(begin: 0.05);
              }),

              const SizedBox(height: 32),

              // ETA Card
              VisoraCard(
                padding: const EdgeInsets.all(16),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.schedule_rounded, color: VisoraColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(progress.isDone ? 'Complete!' : '~${((1 - pct) * 60).round()} seconds remaining',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: VisoraColors.onSurface)),
                ]),
              ).animate().fadeIn(delay: 600.ms),

              if (progress.error != null) ...[
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: VisoraColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                  child: Text(progress.error!, style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.error))),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _AgentTimelineItem extends StatelessWidget {
  final String name, status;
  final bool isLast;
  final AnimationController spinCtrl;
  const _AgentTimelineItem({required this.name, required this.status, required this.isLast, required this.spinCtrl});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Timeline dot + line
        SizedBox(width: 30,
          child: Column(children: [
            Container(width: 30, height: 30,
              decoration: BoxDecoration(
                color: status == 'complete' ? VisoraColors.success.withValues(alpha: 0.1)
                     : status == 'active' ? VisoraColors.primary.withValues(alpha: 0.1)
                     : VisoraColors.surfaceLowest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: status == 'complete' ? VisoraColors.success.withValues(alpha: 0.3)
                       : status == 'active' ? VisoraColors.primary
                       : VisoraColors.outline)),
              child: status == 'complete'
                ? Icon(Icons.check_circle_rounded, size: 16, color: VisoraColors.success)
                : status == 'active'
                  ? RotationTransition(turns: spinCtrl,
                      child: Icon(Icons.sync_rounded, size: 16, color: VisoraColors.primary))
                  : Icon(Icons.hourglass_empty_rounded, size: 16, color: VisoraColors.outline)),
            if (!isLast) Expanded(child: Container(width: 1, color: VisoraColors.outline.withValues(alpha: 0.5))),
          ])),
        const SizedBox(width: 16),
        // Card
        Expanded(child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VisoraColors.surfaceLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: status == 'active' ? VisoraColors.primary.withValues(alpha: 0.3) : VisoraColors.outlineVariant.withValues(alpha: 0.5),
                width: status == 'active' ? 2 : 1),
              boxShadow: status == 'active' ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
              ] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: status == 'active' ? VisoraColors.primary : status == 'complete' ? VisoraColors.onSurface : VisoraColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(
                status == 'complete' ? 'VERIFIED' : status == 'active' ? 'PROCESSING MODELS' : 'QUEUED',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1,
                  color: status == 'complete' ? VisoraColors.success : status == 'active' ? VisoraColors.onSurfaceVariant : VisoraColors.outline)),
            ]),
          ),
        )),
      ]),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  _CircularProgressPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    canvas.drawCircle(c, r, Paint()..color = VisoraColors.surfaceHigh..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, progress * 2 * math.pi, false,
      Paint()..color = VisoraColors.primary..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
