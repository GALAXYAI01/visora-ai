import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/providers.dart';
import '../services/api_service.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(auditResultProvider);
    if (result == null) {
      // Seed demo data for sample audit display
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(auditResultProvider.notifier).state = _demoResult;
      });
      return Scaffold(
        backgroundColor: VisoraColors.background,
        body: const Center(child: CircularProgressIndicator(color: VisoraColors.primary)));
    }
    return Scaffold(
      backgroundColor: VisoraColors.background,
      body: SafeArea(
        child: Stack(fit: StackFit.expand, children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header ──
              Row(children: [
                Icon(Icons.bar_chart_rounded, color: VisoraColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('Visora', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: VisoraColors.primary)),
                const Spacer(),
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: VisoraColors.surfaceHigh, shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: VisoraColors.onSurfaceVariant, size: 20)),
              ]).animate().fadeIn(duration: 200.ms),

              const SizedBox(height: 16),
              MouseRegion(cursor: SystemMouseCursors.click,
                child: GestureDetector(onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.arrow_back_rounded, color: VisoraColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text('BACK TO SCANNER', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600, color: VisoraColors.primary, letterSpacing: 0.5)),
                  ]))).animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 12),
              Text('Bias Results Evaluation', style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.w700, color: VisoraColors.onSurface, letterSpacing: -0.4))
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 8),
              Text('Analysis complete across ${result.rowCount.toStringAsFixed(0)} recent records. ${result.biasSeverity == "HIGH" ? "Critical demographic disparities require immediate attention." : "Evaluation indicates acceptable fairness levels."}',
                style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant, height: 1.6))
                .animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // ── Alert Banner ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: result.biasSeverity == 'HIGH' ? VisoraColors.errorContainer : VisoraColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(result.biasSeverity == 'HIGH' ? Icons.warning_rounded : Icons.check_circle_rounded,
                    color: result.biasSeverity == 'HIGH' ? VisoraColors.error : VisoraColors.success, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(result.biasSeverity == 'HIGH' ? 'HIGH BIAS DETECTED' : 'ACCEPTABLE BIAS LEVELS',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                        color: result.biasSeverity == 'HIGH' ? VisoraColors.error : VisoraColors.success)),
                    const SizedBox(height: 4),
                    Text(result.biasSeverity == 'HIGH'
                      ? 'Model predictions show severe deviation from acceptable parity thresholds across ${result.protectedAttr} attributes. Immediate remediation recommended before deployment.'
                      : 'Model predictions are within acceptable fairness thresholds.',
                      style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.onSurface.withValues(alpha: 0.8), height: 1.5)),
                  ])),
                ]),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.06),

              const SizedBox(height: 20),

              // ── Metric Cards ──
              _MetricCard(label: 'DISPARATE IMPACT', value: result.disparateImpact, threshold: 'Threshold: >0.80',
                icon: Icons.show_chart_rounded, isGood: result.disparateImpact >= 0.8)
                .animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.06),
              const SizedBox(height: 12),
              _MetricCard(label: 'STATISTICAL PARITY', value: result.statisticalParity, threshold: 'Target: 0.00',
                icon: Icons.balance_rounded, isGood: result.statisticalParity.abs() < 0.1)
                .animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.06),
              const SizedBox(height: 12),
              _MetricCard(label: 'EQUAL OPPORTUNITY', value: result.equalizedOdds, threshold: 'Acceptable Range',
                icon: Icons.verified_rounded, isGood: result.equalizedOdds >= 0.7)
                .animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.06),

              const SizedBox(height: 20),

              // ── Approval Rates ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Approval Rate by ${result.protectedAttr[0].toUpperCase()}${result.protectedAttr.substring(1)}',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
                const SizedBox(height: 20),
                ...result.approvalRates.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${e.key[0].toUpperCase()}${e.key.substring(1)} Applicants', style: GoogleFonts.inter(
                        fontSize: 14, color: VisoraColors.onSurface)),
                      Text('${(e.value * 100).round()}%', style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: e.value,
                        backgroundColor: VisoraColors.surface,
                        valueColor: AlwaysStoppedAnimation(e.value > 0.5 ? VisoraColors.primary : VisoraColors.error),
                        minHeight: 8)),
                  ]))),
              ])).animate().fadeIn(delay: 450.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // ── Actionable Advice ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: VisoraColors.primaryContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome_rounded, color: VisoraColors.primary, size: 16)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: VisoraColors.surfaceHigh, borderRadius: BorderRadius.circular(9999)),
                    child: Text('ACTIONABLE ADVICE', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1))),
                ]),
                const SizedBox(height: 16),
                Text(result.geminiExplanation.isNotEmpty ? result.geminiExplanation
                  : "The current model penalizes the 'Tenure at Current Address' feature disproportionately for female applicants. We recommend applying adversarial debiasing techniques or adjusting class weights to mitigate this specific vector without compromising overall model accuracy.",
                  style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant, height: 1.6)),
              ])).animate().fadeIn(delay: 500.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // ── CTAs ──
              MouseRegion(cursor: SystemMouseCursors.click,
                child: GestureDetector(onTap: () => context.push('/human-cost'),
                  child: Container(width: double.infinity, height: 52,
                    decoration: BoxDecoration(color: VisoraColors.error, borderRadius: BorderRadius.circular(9999)),
                    child: Center(child: Text('SEE HUMAN IMPACT', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)))))),
              const SizedBox(height: 12),
              MouseRegion(cursor: SystemMouseCursors.click,
                child: GestureDetector(onTap: () {},
                  child: Container(width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: VisoraColors.error, width: 2)),
                    child: Center(child: Text('REMEDIATE BIAS NOW', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.error, letterSpacing: 0.5)))))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, threshold;
  final double value;
  final IconData icon;
  final bool isGood;
  const _MetricCard({required this.label, required this.value, required this.threshold, required this.icon, required this.isGood});

  @override
  Widget build(BuildContext context) {
    return VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1)),
        Icon(icon, color: isGood ? VisoraColors.success : VisoraColors.error, size: 20),
      ]),
      const SizedBox(height: 12),
      Text(value.toStringAsFixed(2), style: GoogleFonts.inter(
        fontSize: 36, fontWeight: FontWeight.w700, color: isGood ? VisoraColors.success : VisoraColors.error)),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value.abs().clamp(0.0, 1.0),
          backgroundColor: VisoraColors.surface,
          valueColor: AlwaysStoppedAnimation(isGood ? VisoraColors.success : VisoraColors.error), minHeight: 6)),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight,
        child: Text(threshold, style: GoogleFonts.inter(fontSize: 12, color: VisoraColors.onSurfaceVariant))),
    ]));
  }
}

// Demo result for sample audits
final _demoResult = AuditResult(
  auditId: 'demo-001',
  rowCount: 10000,
  featureCount: 24,
  protectedAttr: 'gender',
  targetCol: 'income',
  protectedValues: ['Male', 'Female'],
  disparateImpact: 0.55,
  statisticalParity: -0.33,
  equalizedOdds: 0.82,
  approvalRates: {'Male': 0.74, 'Female': 0.41},
  biasSeverity: 'HIGH',
  legalThresholdViolated: true,
  shapTopFeatures: [],
  geminiExplanation: "The current model penalizes the 'Tenure at Current Address' feature disproportionately for female applicants. We recommend applying adversarial debiasing techniques or adjusting class weights to mitigate this specific vector without compromising overall model accuracy.",
  remediationApplied: 'adversarial_debiasing',
  metricsAfter: {'disparate_impact': 0.81, 'statistical_parity': -0.04},
  accuracyBefore: 0.87,
  accuracyAfter: 0.85,
  pdfPath: '/reports/demo-001.pdf',
);
