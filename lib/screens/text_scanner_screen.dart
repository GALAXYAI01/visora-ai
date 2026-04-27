import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

final _scanResultProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final _scanLoadingProvider = StateProvider<bool>((ref) => false);

class TextScannerScreen extends ConsumerStatefulWidget {
  const TextScannerScreen({super.key});

  @override
  ConsumerState<TextScannerScreen> createState() => _TextScannerScreenState();
}

class _TextScannerScreenState extends ConsumerState<TextScannerScreen> {
  final _controller = TextEditingController(
    text: 'We are looking for a robust, dedicated individual to join our fast-paced team. '
        'The ideal candidate should be a young, energetic self-starter who can handle the physical demands of the role.',
  );

  Future<void> _scan() async {
    if (_controller.text.trim().isEmpty) return;
    ref.read(_scanLoadingProvider.notifier).state = true;
    ref.read(_scanResultProvider.notifier).state = null;
    final result = await GeminiService.scanTextForBias(_controller.text.trim());
    ref.read(_scanResultProvider.notifier).state = result;
    ref.read(_scanLoadingProvider.notifier).state = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(_scanResultProvider);
    final loading = ref.watch(_scanLoadingProvider);

    return Scaffold(
      body: VisoraPage(
        children: [
          const VisoraHeader(
            eyebrow: 'Gemini review',
            title: 'Text bias scanner',
            subtitle: 'Analyze job listings, policies, model outputs, and internal copy for hidden bias and regulatory risk.',
            icon: Icons.document_scanner_rounded,
            trailing: SeverityBadge(label: 'Gemini AI'),
          ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.04),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 920;
              final editor = _SourceTextPanel(controller: _controller, loading: loading, onScan: _scan);
              final examples = _ExamplesPanel(onSelect: (value) => _controller.text = value);
              if (!wide) return Column(children: [editor, const SizedBox(height: 16), examples]);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: editor),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: examples),
                ],
              );
            },
          ).animate().fadeIn(delay: 110.ms, duration: 360.ms).slideY(begin: 0.04),
          if (loading) ...[
            const SizedBox(height: 18),
            const _LoadingReview().animate().fadeIn(duration: 240.ms),
          ],
          if (result != null) ...[
            const SizedBox(height: 22),
            _ScanResult(result: result).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04),
          ],
        ],
      ),
    );
  }
}

class _SourceTextPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onScan;

  const _SourceTextPanel({
    required this.controller,
    required this.loading,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      prominent: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Source text', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Paste the exact text you want reviewed.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: 9,
            maxLines: 14,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              hintText: 'Paste job descriptions, loan policies, HR rules, or model outputs...',
            ),
          ),
          const SizedBox(height: 18),
          loading
              ? const Center(child: CircularProgressIndicator(color: VisoraColors.primary))
              : GradientButton(
                  label: 'Scan for Bias',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: onScan,
                ),
        ],
      ),
    );
  }
}

class _ExamplesPanel extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const _ExamplesPanel({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final examples = [
      (
        title: 'Job listing',
        body: 'We need a young, energetic team player who can work long hours in a physically demanding role. Cultural fit is essential.'
      ),
      (
        title: 'Loan policy',
        body: 'Applicants from certain zip codes may face additional verification. Single mothers and recent immigrants require co-signers regardless of credit score.'
      ),
      (
        title: 'HR policy',
        body: 'Employees returning from maternity leave will be reassigned to junior roles. Part-time workers are not eligible for leadership positions.'
      ),
      (
        title: 'AI output',
        body: 'Based on historical data, the model recommends denying the application. Risk factors: neighborhood, marital status, native language.'
      ),
    ];

    return VisoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick examples', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Use these samples to preview the scanner.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ...examples.map((example) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: VisoraCard(
                onTap: () => onSelect(example.body),
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.article_outlined, color: Theme.of(context).colorScheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(example.title, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 3),
                          Text(example.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const InfoBanner(
            icon: Icons.privacy_tip_outlined,
            title: 'Review scope',
            body: 'Gemini flags wording risk and suggests safer alternatives. Final compliance review remains a human decision.',
            color: VisoraColors.primary,
          ),
        ],
      ),
    );
  }
}

class _LoadingReview extends StatelessWidget {
  const _LoadingReview();

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: VisoraColors.primary, strokeWidth: 3)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analyzing with Gemini AI', style: Theme.of(context).textTheme.titleSmall),
                Text('Checking language, severity, legal signals, and safer rewrites.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanResult extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ScanResult({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.containsKey('error')) {
      return InfoBanner(
        icon: Icons.error_outline_rounded,
        title: 'Scanner error',
        body: result['error'].toString(),
        color: VisoraColors.error,
      );
    }

    final risk = (result['overall_risk'] ?? 'UNKNOWN').toString().toUpperCase();
    final scoreRaw = result['bias_score'] ?? 0;
    final score = scoreRaw is num ? scoreRaw.toDouble() : 0.0;
    final riskColor = risk == 'HIGH'
        ? VisoraColors.error
        : risk == 'MODERATE'
            ? VisoraColors.warning
            : VisoraColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoBanner(
          icon: risk == 'HIGH'
              ? Icons.dangerous_rounded
              : risk == 'MODERATE'
                  ? Icons.warning_amber_rounded
                  : Icons.verified_rounded,
          title: '$risk risk',
          body: result['summary']?.toString() ?? 'No summary returned.',
          color: riskColor,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final scoreCard = _ScoreCard(score: score, color: riskColor);
            final legal = _LegalCard(result: result);
            if (!wide) return Column(children: [scoreCard, const SizedBox(height: 16), legal]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: scoreCard),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: legal),
              ],
            );
          },
        ),
        if (result['flags'] != null && (result['flags'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          _FlagsCard(flags: result['flags'] as List),
        ],
        if (result['improved_text'] != null) ...[
          const SizedBox(height: 16),
          _ImprovedTextCard(text: result['improved_text'].toString()),
        ],
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final double score;
  final Color color;

  const _ScoreCard({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bias score', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score.toInt().toString(), style: Theme.of(context).textTheme.displaySmall?.copyWith(color: color)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('/100', style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _LegalCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final risks = result['legal_risks'] is List ? (result['legal_risks'] as List).map((item) => item.toString()).toList() : <String>[];
    return VisoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legal and regulatory signals', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (risks.isEmpty)
            Text('No legal risk notes returned.', style: Theme.of(context).textTheme.bodyMedium)
          else
            ...risks.map(
              (risk) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: VisoraColors.warning, size: 18),
                    const SizedBox(width: 9),
                    Expanded(child: Text(risk, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlagsCard extends StatelessWidget {
  final List flags;
  const _FlagsCard({required this.flags});

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Flagged phrases (${flags.length})', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...flags.map((flag) {
            final item = flag as Map<String, dynamic>;
            final severity = item['severity']?.toString().toUpperCase() ?? 'LOW';
            final color = severity == 'HIGH'
                ? VisoraColors.error
                : severity == 'MODERATE'
                    ? VisoraColors.warning
                    : VisoraColors.success;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SeverityBadge(label: severity),
                      SeverityBadge(label: item['type']?.toString().toUpperCase() ?? 'BIAS'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('"${item['phrase'] ?? ''}"', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(item['explanation']?.toString() ?? '', style: Theme.of(context).textTheme.bodyMedium),
                  if (item['suggestion'] != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: VisoraColors.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Suggestion: ${item['suggestion']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: VisoraColors.success))),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ImprovedTextCard extends StatelessWidget {
  final String text;
  const _ImprovedTextCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI-suggested improvement', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VisoraColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VisoraColors.success.withValues(alpha: 0.16)),
            ),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF0D652D))),
          ),
        ],
      ),
    );
  }
}
