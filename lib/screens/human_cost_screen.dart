import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

class HumanCostScreen extends ConsumerWidget {
  const HumanCostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(auditResultProvider);
    final riskLabel = result?.biasSeverity.toUpperCase() == 'HIGH' ? 'Critical' : 'Elevated';

    return Scaffold(
      body: VisoraPage(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          VisoraHeader(
            eyebrow: 'Human impact',
            title: 'The real cost of biased AI',
            subtitle: 'Translate fairness gaps into monthly unfair decisions, liability exposure, and compliance risk.',
            icon: Icons.groups_rounded,
            onBack: () => context.canPop() ? context.pop() : context.go('/home'),
            trailing: SeverityBadge(label: riskLabel),
          ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.04),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 620 ? 2 : 1;
              final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: width,
                    child: const MetricTile(
                      label: 'Legal risk',
                      value: '95/100',
                      helper: 'Immediate intervention',
                      icon: Icons.gavel_rounded,
                      color: VisoraColors.error,
                      progress: 0.95,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: const MetricTile(
                      label: 'Impact scale',
                      value: '2,847',
                      helper: 'Unfair decisions per month',
                      icon: Icons.groups_rounded,
                      color: VisoraColors.warning,
                      progress: 0.72,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: const MetricTile(
                      label: 'Liability',
                      value: '\$4.27B',
                      helper: 'Projected exposure',
                      icon: Icons.account_balance_rounded,
                      color: VisoraColors.error,
                      progress: 0.84,
                    ),
                  ),
                ],
              );
            },
          ).animate().fadeIn(delay: 100.ms, duration: 340.ms),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final disparity = const _DisparityPanel();
              final compliance = const _CompliancePanel();
              if (!wide) return Column(children: [disparity, const SizedBox(height: 16), compliance]);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: disparity),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: compliance),
                ],
              );
            },
          ).animate().fadeIn(delay: 180.ms, duration: 360.ms).slideY(begin: 0.03),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Back to Results',
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ).animate().fadeIn(delay: 260.ms),
        ],
      ),
    );
  }
}

class _DisparityPanel extends StatelessWidget {
  const _DisparityPanel();

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      prominent: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demographic disparity analysis', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('A/B test showing a protected-attribute proxy changing the outcome.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          const _CandidateCard(
            name: 'Priya Sharma',
            subtitle: 'Original candidate profile',
            verdict: 'Rejected',
            score: '42',
            color: VisoraColors.error,
            icon: Icons.person_outline_rounded,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                const SizedBox(width: 12),
                Icon(Icons.swap_vert_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text('Name swapped only', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
              ],
            ),
          ),
          const _CandidateCard(
            name: 'Peter Sharma',
            subtitle: 'Modified shadow profile',
            verdict: 'Hired',
            score: '81',
            color: VisoraColors.success,
            icon: Icons.person_rounded,
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String verdict;
  final String score;
  final Color color;
  final IconData icon;

  const _CandidateCard({
    required this.name,
    required this.subtitle,
    required this.verdict,
    required this.score,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SeverityBadge(label: verdict),
              const SizedBox(height: 6),
              Text('Score $score', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompliancePanel extends StatelessWidget {
  const _CompliancePanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VisoraCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Regulatory status', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Current audit posture by framework.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              const _RegItem(icon: Icons.gavel_rounded, title: 'EU AI Act', status: 'Violation'),
              const SizedBox(height: 10),
              const _RegItem(icon: Icons.security_rounded, title: 'GDPR', status: 'Violation'),
              const SizedBox(height: 10),
              const _RegItem(icon: Icons.business_center_rounded, title: 'EEOC', status: 'Violation'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          icon: Icons.priority_high_rounded,
          title: 'Escalation recommended',
          body: 'Bias exposure is high enough to require remediation evidence before approval.',
          color: VisoraColors.error,
        ),
      ],
    );
  }
}

class _RegItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;

  const _RegItem({
    required this.icon,
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: VisoraColors.errorContainer, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: VisoraColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
          SeverityBadge(label: status),
        ],
      ),
    );
  }
}
