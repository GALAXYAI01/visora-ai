import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(auditResultProvider);
    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(auditResultProvider.notifier).state = _demoResult;
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: VisoraColors.primary)));
    }

    final highRisk = result.biasSeverity.toUpperCase() == 'HIGH';

    return Scaffold(
      body: VisoraPage(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          VisoraHeader(
            eyebrow: 'Audit results',
            title: 'Bias results evaluation',
            subtitle: 'Analysis complete across ${result.rowCount.toStringAsFixed(0)} records. ${highRisk ? "Critical demographic disparities require review before deployment." : "Evaluation indicates acceptable fairness levels."}',
            icon: Icons.bar_chart_rounded,
            onBack: () => context.canPop() ? context.pop() : context.go('/home'),
            trailing: SeverityBadge(label: result.biasSeverity),
          ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.04),
          const SizedBox(height: 24),
          InfoBanner(
            icon: highRisk ? Icons.warning_rounded : Icons.check_circle_rounded,
            title: highRisk ? 'High bias detected' : 'Acceptable bias levels',
            body: highRisk
                ? 'Model predictions deviate from parity thresholds across ${result.protectedAttr}. Apply remediation before production use.'
                : 'Model predictions are within the configured fairness thresholds.',
            color: highRisk ? VisoraColors.error : VisoraColors.success,
          ).animate().fadeIn(delay: 70.ms, duration: 340.ms).slideY(begin: 0.04),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 920 ? 3 : constraints.maxWidth >= 620 ? 2 : 1;
              final itemWidth = (constraints.maxWidth - (columns - 1) * 14) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _MetricCard(
                      label: 'Disparate impact',
                      value: result.disparateImpact,
                      threshold: 'Threshold greater than 0.80',
                      icon: Icons.show_chart_rounded,
                      isGood: result.disparateImpact >= 0.8,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _MetricCard(
                      label: 'Statistical parity',
                      value: result.statisticalParity,
                      threshold: 'Target close to 0.00',
                      icon: Icons.balance_rounded,
                      isGood: result.statisticalParity.abs() < 0.1,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _MetricCard(
                      label: 'Equal opportunity',
                      value: result.equalizedOdds,
                      threshold: 'Acceptable range',
                      icon: Icons.verified_rounded,
                      isGood: result.equalizedOdds >= 0.7,
                    ),
                  ),
                ],
              );
            },
          ).animate().fadeIn(delay: 130.ms, duration: 360.ms),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final rates = _ApprovalRates(result: result);
              final advice = _AdvicePanel(result: result);
              if (!wide) return Column(children: [rates, const SizedBox(height: 16), advice]);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: rates),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: advice),
                ],
              );
            },
          ).animate().fadeIn(delay: 190.ms, duration: 360.ms).slideY(begin: 0.03),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final impact = GradientButton(
                label: 'See Human Impact',
                icon: Icons.groups_rounded,
                onPressed: () => context.push('/human-cost'),
              );
              final remediate = GradientButton(
                label: 'Remediate Bias Now',
                icon: Icons.auto_fix_high_rounded,
                onPressed: () => context.go('/reports'),
                secondary: true,
              );
              if (!wide) return Column(children: [impact, const SizedBox(height: 12), remediate]);
              return Row(
                children: [
                  Expanded(child: impact),
                  const SizedBox(width: 12),
                  Expanded(child: remediate),
                ],
              );
            },
          ).animate().fadeIn(delay: 260.ms, duration: 320.ms),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String threshold;
  final double value;
  final IconData icon;
  final bool isGood;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.threshold,
    required this.icon,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGood ? VisoraColors.success : VisoraColors.error;
    return VisoraCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              SeverityBadge(label: isGood ? 'Passed' : 'Violation'),
            ],
          ),
          const SizedBox(height: 18),
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(value.toStringAsFixed(2), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.abs().clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(threshold, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ApprovalRates extends StatelessWidget {
  final AuditResult result;
  const _ApprovalRates({required this.result});

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Approval rate by ${_titleCase(result.protectedAttr)}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Outcome distribution across protected groups.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          ...result.approvalRates.entries.map((entry) {
            final value = entry.value.clamp(0.0, 1.0);
            final color = value >= 0.5 ? VisoraColors.primary : VisoraColors.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('${_titleCase(entry.key)} applicants', style: Theme.of(context).textTheme.titleSmall)),
                      Text('${(value * 100).round()}%', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AdvicePanel extends StatelessWidget {
  final AuditResult result;
  const _AdvicePanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final explanation = result.geminiExplanation.isNotEmpty
        ? result.geminiExplanation
        : "The current model penalizes the 'Tenure at Current Address' feature disproportionately for female applicants. We recommend applying adversarial debiasing techniques or adjusting class weights to mitigate this vector without compromising overall model accuracy.";
    return Column(
      children: [
        VisoraCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: VisoraColors.primaryContainer.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: VisoraColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Actionable advice', style: Theme.of(context).textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 16),
              Text(explanation, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InfoBanner(
          icon: Icons.gavel_rounded,
          title: result.legalThresholdViolated ? 'Legal threshold violated' : 'Thresholds acceptable',
          body: result.legalThresholdViolated
              ? 'The audit failed at least one configured fairness threshold and should be documented.'
              : 'No configured legal threshold was violated by this result.',
          color: result.legalThresholdViolated ? VisoraColors.warning : VisoraColors.success,
        ),
      ],
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

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
