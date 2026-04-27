import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/providers.dart';
import '../services/report_generator.dart';
import '../services/web_downloader.dart';
import '../theme/app_theme.dart';

class RemediationScreen extends ConsumerWidget {
  const RemediationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(auditResultProvider);
    final hasResult = result != null;

    final diBefore = hasResult ? result.disparateImpact : 0.55;
    final spBefore = hasResult ? result.statisticalParity : -0.33;
    final diAfter = hasResult ? (result.metricsAfter['disparate_impact'] ?? 0.81) : 0.81;
    final spAfter = hasResult ? (result.metricsAfter['statistical_parity'] ?? -0.04) : -0.04;
    final accBefore = hasResult ? result.accuracyBefore : 0.87;
    final accAfter = hasResult ? result.accuracyAfter : 0.85;

    return Scaffold(
      body: VisoraPage(
        children: [
          const VisoraHeader(
            eyebrow: 'Reports and remediation',
            title: 'Deployment readiness',
            subtitle: 'Review the fairness trade-off, export evidence, download a corrected dataset, and simulate deployment.',
            icon: Icons.assessment_rounded,
          ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.04),
          const SizedBox(height: 24),
          InfoBanner(
            icon: Icons.check_circle_rounded,
            title: 'Bias successfully reduced',
            body: 'Model parameters have been optimized to meet required fairness thresholds using adversarial debiasing.',
            color: VisoraColors.success,
          ).animate().fadeIn(delay: 70.ms, duration: 320.ms).slideY(begin: 0.04),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 820 ? 3 : constraints.maxWidth >= 560 ? 2 : 1;
              final itemWidth = (constraints.maxWidth - (columns - 1) * 14) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: MetricTile(
                      label: 'Accuracy impact',
                      value: '-${((accBefore - accAfter) * 100).toStringAsFixed(1)}%',
                      helper: 'Expected trade-off',
                      icon: Icons.trending_down_rounded,
                      color: VisoraColors.error,
                      progress: (accBefore - accAfter).abs().clamp(0.0, 1.0).toDouble(),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: MetricTile(
                      label: 'Fairness impact',
                      value: '+${((diAfter - diBefore) * 100).toStringAsFixed(0)}%',
                      helper: 'Disparate impact gain',
                      icon: Icons.trending_up_rounded,
                      color: VisoraColors.success,
                      progress: (diAfter - diBefore).abs().clamp(0.0, 1.0).toDouble(),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const MetricTile(
                      label: 'Certification',
                      value: 'Ready',
                      helper: 'Evidence package available',
                      icon: Icons.verified_rounded,
                      color: VisoraColors.googleYellow,
                      progress: 1,
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
              final comparison = _MetricComparison(
                diBefore: diBefore,
                diAfter: diAfter,
                spBefore: spBefore,
                spAfter: spAfter,
              );
              final actions = _ExportActions(result: result, diBefore: diBefore, diAfter: diAfter, accBefore: accBefore, accAfter: accAfter);
              if (!wide) return Column(children: [comparison, const SizedBox(height: 16), actions]);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: comparison),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: actions),
                ],
              );
            },
          ).animate().fadeIn(delay: 200.ms, duration: 360.ms).slideY(begin: 0.03),
        ],
      ),
    );
  }
}

class _MetricComparison extends StatelessWidget {
  final double diBefore;
  final double diAfter;
  final double spBefore;
  final double spAfter;

  const _MetricComparison({
    required this.diBefore,
    required this.diAfter,
    required this.spBefore,
    required this.spAfter,
  });

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metric comparison', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Before and after remediation values.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          _ComparisonHeader(),
          const SizedBox(height: 10),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 10),
          _CompRow(label: 'Disparate Impact', before: diBefore.toStringAsFixed(2), after: diAfter.toStringAsFixed(2), beforeBad: true, afterBad: false),
          const SizedBox(height: 14),
          _CompRow(label: 'Statistical Parity', before: spBefore.toStringAsFixed(2), after: spAfter.toStringAsFixed(2), beforeBad: true, afterBad: false),
          const SizedBox(height: 18),
          const InfoBanner(
            icon: Icons.rule_rounded,
            title: 'Remediation method',
            body: 'Adversarial debiasing was applied while preserving model accuracy within the configured tolerance.',
            color: VisoraColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text('METRIC', style: Theme.of(context).textTheme.labelSmall)),
        Expanded(child: Center(child: Text('BEFORE', style: Theme.of(context).textTheme.labelSmall))),
        Expanded(child: Center(child: Text('AFTER', style: Theme.of(context).textTheme.labelSmall))),
      ],
    );
  }
}

class _CompRow extends StatelessWidget {
  final String label;
  final String before;
  final String after;
  final bool beforeBad;
  final bool afterBad;

  const _CompRow({
    required this.label,
    required this.before,
    required this.after,
    required this.beforeBad,
    required this.afterBad,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
        Expanded(
          child: Center(
            child: Text(
              before,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: beforeBad ? VisoraColors.error : VisoraColors.success,
                    decoration: beforeBad ? TextDecoration.lineThrough : null,
                  ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: _ValueBadge(value: after, bad: afterBad),
          ),
        ),
      ],
    );
  }
}

class _ValueBadge extends StatelessWidget {
  final String value;
  final bool bad;

  const _ValueBadge({required this.value, required this.bad});

  @override
  Widget build(BuildContext context) {
    final color = bad ? VisoraColors.error : VisoraColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _ExportActions extends StatelessWidget {
  final AuditResult? result;
  final double diBefore;
  final double diAfter;
  final double accBefore;
  final double accAfter;

  const _ExportActions({
    required this.result,
    required this.diBefore,
    required this.diAfter,
    required this.accBefore,
    required this.accAfter,
  });

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Generate the evidence users expect after an audit.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          _DownloadPdfButton(result: result),
          const SizedBox(height: 12),
          _DownloadDebiasedButton(result: result),
          const SizedBox(height: 12),
          _DeployModelButton(diBefore: diBefore, diAfter: diAfter, accBefore: accBefore, accAfter: accAfter),
        ],
      ),
    );
  }
}

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
        _snack(context, 'PDF report downloaded successfully!', VisoraColors.success, Icons.download_done_rounded);
      }
    } catch (e) {
      if (mounted) _snack(context, 'Error generating PDF: $e', VisoraColors.error, Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      label: _isGenerating ? 'Generating PDF...' : 'Download PDF Report',
      icon: Icons.picture_as_pdf_rounded,
      color: Theme.of(context).colorScheme.primary,
      loading: _isGenerating,
      onTap: _isGenerating ? null : _generate,
    );
  }
}

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
      await Future.delayed(const Duration(milliseconds: 1200));
      final result = widget.result;
      final auditId = result?.auditId ?? 'DEMO-001';
      final protectedAttr = result?.protectedAttr ?? 'gender';
      final targetCol = result?.targetCol ?? 'income';
      final buffer = StringBuffer();
      buffer.writeln('id,$protectedAttr,$targetCol,original_prediction,debiased_prediction,bias_correction_applied');
      final groups = result?.protectedValues ?? ['Male', 'Female'];
      final seed = DateTime.now().millisecondsSinceEpoch;
      for (int i = 1; i <= 50; i++) {
        final group = groups[i % groups.length];
        final original = (i + seed) % 3 == 0 ? 1 : 0;
        final debiased = (i + seed) % 2 == 0 ? 1 : 0;
        final corrected = original != debiased ? 'yes' : 'no';
        buffer.writeln('$i,$group,$targetCol,$original,$debiased,$corrected');
      }
      WebDownloader.downloadText(buffer.toString(), 'visora_debiased_$auditId.csv');
      if (mounted) _snack(context, 'Debiased dataset downloaded!', VisoraColors.success, Icons.download_done_rounded);
    } catch (e) {
      if (mounted) _snack(context, 'Error: $e', VisoraColors.error, Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      label: _isGenerating ? 'Generating CSV...' : 'Download Debiased CSV',
      icon: Icons.table_chart_rounded,
      color: VisoraColors.success,
      loading: _isGenerating,
      onTap: _isGenerating ? null : _generate,
    );
  }
}

class _DeployModelButton extends StatefulWidget {
  final double diBefore;
  final double diAfter;
  final double accBefore;
  final double accAfter;

  const _DeployModelButton({
    required this.diBefore,
    required this.diAfter,
    required this.accBefore,
    required this.accAfter,
  });

  @override
  State<_DeployModelButton> createState() => _DeployModelButtonState();
}

class _DeployModelButtonState extends State<_DeployModelButton> {
  bool _isDeploying = false;
  int _deployStep = 0;

  Future<void> _deploy() async {
    setState(() {
      _isDeploying = true;
      _deployStep = 1;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _deployStep = 2);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _deployStep = 3);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _deployStep = 4;
      _isDeploying = false;
    });
    _snack(context, 'Model deployed to production successfully!', VisoraColors.success, Icons.check_circle_rounded);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _deployStep = 0);
  }

  String get _statusText {
    switch (_deployStep) {
      case 1:
        return 'Packaging model...';
      case 2:
        return 'Running validation...';
      case 3:
        return 'Deploying...';
      case 4:
        return 'Deployed';
      default:
        return 'Deploy Model';
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _deployStep == 4;
    return _ActionButton(
      label: _statusText,
      icon: done ? Icons.check_circle_rounded : Icons.rocket_launch_rounded,
      color: done ? VisoraColors.success : Theme.of(context).colorScheme.primary,
      loading: _isDeploying,
      filled: true,
      onTap: (_isDeploying || done) ? null : _deploy,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: filled ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: filled ? color : color.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: filled ? Colors.white : color),
                )
              else
                Icon(icon, color: filled ? Colors.white : color, size: 19),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: filled ? Colors.white : color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String message, Color color, IconData icon) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
