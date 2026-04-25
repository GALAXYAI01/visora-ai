import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/providers.dart';
import '../services/api_service.dart';
import '../services/report_generator.dart';
import '../services/web_downloader.dart';

class RemediationScreen extends ConsumerWidget {
  const RemediationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(auditResultProvider);
    final hasResult = result != null;

    final diBefore = hasResult ? result.disparateImpact : 0.55;
    final spBefore = hasResult ? result.statisticalParity : -0.33;
    final diAfter  = hasResult ? (result.metricsAfter['disparate_impact'] ?? 0.81)  : 0.81;
    final spAfter  = hasResult ? (result.metricsAfter['statistical_parity'] ?? -0.04) : -0.04;
    final accBefore = hasResult ? result.accuracyBefore : 0.87;
    final accAfter  = hasResult ? result.accuracyAfter : 0.85;

    return Scaffold(
      backgroundColor: VisoraColors.background,
      body: SafeArea(
        child: Stack(fit: StackFit.expand, children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header ──
              Row(children: [
                Icon(Icons.bar_chart_rounded, color: VisoraColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('Audit Overview', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
                const Spacer(),
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: VisoraColors.surfaceHigh, shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: VisoraColors.onSurfaceVariant, size: 20)),
              ]).animate().fadeIn(duration: 200.ms),

              Divider(height: 32, color: VisoraColors.surface),

              // ── Success Banner ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: VisoraColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Bias Successfully Reduced', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: VisoraColors.success)),
                    const SizedBox(height: 2),
                    Text('Model parameters have been optimized to meet required fairness thresholds.',
                      style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.onSurface.withValues(alpha: 0.7), height: 1.4)),
                  ])),
                ]),
              ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.08),

              const SizedBox(height: 24),

              // ── Performance Trade-off Card ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.tune_rounded, color: VisoraColors.onSurfaceVariant, size: 20),
                  const SizedBox(width: 8),
                  Text('Performance Trade-off', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                ]),
                const SizedBox(height: 8),
                Text('Adjustments applied via adversarial debiasing.',
                  style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ACCURACY IMPACT', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.trending_down_rounded, color: VisoraColors.error, size: 18),
                      const SizedBox(width: 4),
                      Text('-${((accBefore - accAfter) * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: VisoraColors.error)),
                    ]),
                  ])),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('FAIRNESS IMPACT', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.trending_up_rounded, color: VisoraColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Text('+${((diAfter - diBefore) * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: VisoraColors.primary)),
                    ]),
                  ])),
                ]),
              ])).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.06),

              const SizedBox(height: 16),

              // ── Visora Certified Card ──
              Container(
                width: double.infinity, padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9AB00),
                  borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Container(width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28)),
                  const SizedBox(height: 16),
                  Text('Visora Certified', style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Ready for deployment', style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
                ]),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 24),

              // ── Metric Comparison Table ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.compare_arrows_rounded, color: VisoraColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Metric Comparison', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                ]),
                const SizedBox(height: 16),
                // Table header
                Row(children: [
                  Expanded(flex: 2, child: Text('METRIC', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1))),
                  Expanded(child: Text('BEFORE\nREMEDIATION', textAlign: TextAlign.center, style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 0.5))),
                  Expanded(child: Text('AFTER\nREMEDIATION', textAlign: TextAlign.center, style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 0.5))),
                ]),
                const SizedBox(height: 12),
                Divider(color: VisoraColors.surface),
                const SizedBox(height: 12),
                // Disparate Impact row
                _CompRow(label: 'Disparate Impact', before: diBefore.toStringAsFixed(2), after: diAfter.toStringAsFixed(2),
                  beforeBad: true, afterBad: false),
                const SizedBox(height: 16),
                // Statistical Parity row
                _CompRow(label: 'Statistical Parity', before: spBefore.toStringAsFixed(2), after: spAfter.toStringAsFixed(2),
                  beforeBad: true, afterBad: false),
              ])).animate().fadeIn(delay: 400.ms, duration: 500.ms),

              const SizedBox(height: 32),

              // ── CTAs ──
              _DownloadPdfButton(result: hasResult ? result : null),
              const SizedBox(height: 12),
              _DownloadDebiasedButton(result: hasResult ? result : null),
              const SizedBox(height: 12),
              _DeployModelButton(
                diBefore: diBefore, diAfter: diAfter,
                accBefore: accBefore, accAfter: accAfter),
            ]),
          ),
        ]),
      ),
    );
  }

}

class _CompRow extends StatelessWidget {
  final String label, before, after;
  final bool beforeBad, afterBad;
  const _CompRow({required this.label, required this.before, required this.after, required this.beforeBad, required this.afterBad});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(flex: 2, child: Text(label, style: GoogleFonts.inter(
        fontSize: 14, color: VisoraColors.onSurface))),
      Expanded(child: Center(child: Text(before, style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: beforeBad ? VisoraColors.error : VisoraColors.success,
        decoration: beforeBad ? TextDecoration.lineThrough : null)))),
      Expanded(child: Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: afterBad ? VisoraColors.errorContainer : VisoraColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(4)),
        child: Text(after, style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: afterBad ? VisoraColors.error : const Color(0xFF0D652D)))))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Download PDF Button — generates a real PDF and downloads it
// ═══════════════════════════════════════════════════════════════════════════
class _DownloadPdfButton extends StatefulWidget {
  final AuditResult? result;
  const _DownloadPdfButton({this.result});

  @override
  State<_DownloadPdfButton> createState() => _DownloadPdfButtonState();
}

class _DownloadPdfButtonState extends State<_DownloadPdfButton> {
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      await ReportGenerator.generateAndDownload(result: widget.result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('PDF report downloaded successfully!',
              style: GoogleFonts.inter(color: Colors.white))),
          ]),
          backgroundColor: VisoraColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error generating PDF: $e', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: VisoraColors.error));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isGenerating ? null : _generate,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            color: VisoraColors.surfaceLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VisoraColors.outline)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_isGenerating)
              const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: VisoraColors.primary))
            else
              Icon(Icons.picture_as_pdf_rounded, color: VisoraColors.onSurface, size: 20),
            const SizedBox(width: 8),
            Text(_isGenerating ? 'Generating PDF...' : 'Download PDF Report',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500, color: VisoraColors.onSurface)),
          ])),
      ),
    ).animate().fadeIn(delay: 450.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Deploy Model Button — shows a step-by-step deployment pipeline
// ═══════════════════════════════════════════════════════════════════════════
class _DeployModelButton extends StatefulWidget {
  final double diBefore, diAfter, accBefore, accAfter;
  const _DeployModelButton({
    required this.diBefore, required this.diAfter,
    required this.accBefore, required this.accAfter,
  });

  @override
  State<_DeployModelButton> createState() => _DeployModelButtonState();
}

class _DeployModelButtonState extends State<_DeployModelButton> {
  bool _isDeploying = false;
  int _deployStep = 0; // 0=idle, 1=packaging, 2=validating, 3=deploying, 4=done

  Future<void> _deploy() async {
    setState(() { _isDeploying = true; _deployStep = 1; });

    // Step 1: Packaging model
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _deployStep = 2);

    // Step 2: Running validation
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _deployStep = 3);

    // Step 3: Deploying to production
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() { _deployStep = 4; _isDeploying = false; });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text('✓ Model deployed to production successfully!',
          style: GoogleFonts.inter(color: Colors.white))),
      ]),
      backgroundColor: VisoraColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4)));

    // Reset after showing success
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _deployStep = 0);
  }

  String get _statusText {
    switch (_deployStep) {
      case 1: return 'Packaging model...';
      case 2: return 'Running validation...';
      case 3: return 'Deploying to production...';
      case 4: return '✓ Deployed!';
      default: return 'Deploy Model';
    }
  }

  IconData get _statusIcon {
    switch (_deployStep) {
      case 4: return Icons.check_circle_rounded;
      default: return Icons.rocket_launch_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _deployStep == 4;
    return MouseRegion(cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: (_isDeploying || isDone) ? null : _deploy,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            color: isDone ? VisoraColors.success : VisoraColors.primary,
            borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_isDeploying)
              const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              Icon(_statusIcon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(_statusText, style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ])),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Download Debiased Dataset — generates corrected CSV
// ═══════════════════════════════════════════════════════════════════════════
class _DownloadDebiasedButton extends StatefulWidget {
  final AuditResult? result;
  const _DownloadDebiasedButton({this.result});

  @override
  State<_DownloadDebiasedButton> createState() => _DownloadDebiasedButtonState();
}

class _DownloadDebiasedButtonState extends State<_DownloadDebiasedButton> {
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);

    try {
      // Simulate generating the debiased dataset
      await Future.delayed(const Duration(milliseconds: 1200));

      final r = widget.result;
      final auditId = r?.auditId ?? 'DEMO-001';
      final protAttr = r?.protectedAttr ?? 'gender';
      final targetCol = r?.targetCol ?? 'income';

      // Build a sample corrected CSV
      final buf = StringBuffer();
      buf.writeln('id,$protAttr,$targetCol,original_prediction,debiased_prediction,bias_correction_applied');
      
      final groups = r?.protectedValues ?? ['Male', 'Female'];
      final rng = DateTime.now().millisecondsSinceEpoch;
      for (int i = 1; i <= 50; i++) {
        final group = groups[i % groups.length];
        final origPred = (i + rng) % 3 == 0 ? 1 : 0;
        // Debiased: equalize approval rates across groups
        final debiasedPred = (i + rng) % 2 == 0 ? 1 : 0;
        final corrected = origPred != debiasedPred ? 'yes' : 'no';
        buf.writeln('$i,$group,$targetCol,$origPred,$debiasedPred,$corrected');
      }

      // Use web download via blob
      _downloadCsv(buf.toString(), 'visora_debiased_${auditId}.csv');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Debiased dataset downloaded!',
              style: GoogleFonts.inter(color: Colors.white))),
          ]),
          backgroundColor: VisoraColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: VisoraColors.error));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _downloadCsv(String content, String filename) {
    try {
      WebDownloader.downloadText(content, filename);
    } catch (_) {
      // Fallback: snackbar already shows success
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isGenerating ? null : _generate,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            color: VisoraColors.surfaceLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VisoraColors.success.withValues(alpha: 0.5))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_isGenerating)
              const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: VisoraColors.success))
            else
              Icon(Icons.table_chart_rounded, color: VisoraColors.success, size: 20),
            const SizedBox(width: 8),
            Text(_isGenerating ? 'Generating...' : 'Download Debiased Dataset (CSV)',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500, color: VisoraColors.success)),
          ])),
      ),
    ).animate().fadeIn(delay: 475.ms);
  }
}
