import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';

final _scanResultProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final _scanLoadingProvider = StateProvider<bool>((ref) => false);

class TextScannerScreen extends ConsumerStatefulWidget {
  const TextScannerScreen({super.key});
  @override
  ConsumerState<TextScannerScreen> createState() => _TextScannerScreenState();
}

class _TextScannerScreenState extends ConsumerState<TextScannerScreen> {
  final _ctrl = TextEditingController(
    text: 'We are looking for a robust, dedicated individual to join our fast-paced team. '
         'The ideal candidate should be a young, energetic self-starter who can handle the physical demands of the role.');

  Future<void> _scan() async {
    if (_ctrl.text.trim().isEmpty) return;
    ref.read(_scanLoadingProvider.notifier).state = true;
    ref.read(_scanResultProvider.notifier).state = null;

    final result = await GeminiService.scanTextForBias(_ctrl.text.trim());
    ref.read(_scanResultProvider.notifier).state = result;
    ref.read(_scanLoadingProvider.notifier).state = false;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(_scanResultProvider);
    final loading = ref.watch(_scanLoadingProvider);

    return Scaffold(
      backgroundColor: VisoraColors.background,
      body: SafeArea(
        child: Stack(fit: StackFit.expand, children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header ──
              Row(children: [
                Icon(Icons.radar_rounded, color: VisoraColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('AI Bias Scanner', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: VisoraColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, color: VisoraColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text('Gemini AI', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.primary)),
                  ]),
                ),
              ]).animate().fadeIn(duration: 200.ms),

              Divider(height: 32, color: VisoraColors.surface),

              // ── Title ──
              Text('Text Bias Scanner', style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.w700, color: VisoraColors.onSurface, letterSpacing: -0.4))
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 8),
              Text('Analyze any text — job listings, policies, model outputs — for hidden bias using Gemini AI.',
                style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant, height: 1.6))
                .animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // ── Source Text ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Source Text', style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: VisoraColors.outline),
                    borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 6,
                    style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurface, height: 1.6),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      hintText: 'Paste your text here — job descriptions, loan policies, HR rules, model decisions...',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant),
                      filled: false)),
                ),
              ])).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.06),

              const SizedBox(height: 16),

              // ── Quick Examples ──
              Text('QUICK EXAMPLES', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1)),
              const SizedBox(height: 8),
              SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _ExampleChip(label: '📋 Job Listing', onTap: () {
                    _ctrl.text = 'We need a young, energetic team player who can work long hours in a physically demanding role. Cultural fit is essential.';
                  }),
                  const SizedBox(width: 8),
                  _ExampleChip(label: '🏦 Loan Policy', onTap: () {
                    _ctrl.text = 'Applicants from certain zip codes may face additional verification. Single mothers and recent immigrants require co-signers regardless of credit score.';
                  }),
                  const SizedBox(width: 8),
                  _ExampleChip(label: '👔 HR Policy', onTap: () {
                    _ctrl.text = 'Employees returning from maternity leave will be reassigned to junior roles. Part-time workers are not eligible for leadership positions.';
                  }),
                  const SizedBox(width: 8),
                  _ExampleChip(label: '🤖 AI Output', onTap: () {
                    _ctrl.text = 'Based on historical data, the model recommends denying the application. Risk factors: neighborhood, marital status, native language.';
                  }),
                ])).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 24),

              // ── Scan Button ──
              loading
                ? Center(child: Column(children: [
                    const SizedBox(height: 8),
                    const CircularProgressIndicator(color: VisoraColors.primary),
                    const SizedBox(height: 12),
                    Text('Analyzing with Gemini AI...', style: GoogleFonts.inter(
                      fontSize: 13, color: VisoraColors.onSurfaceVariant)),
                  ]))
                : SizedBox(width: double.infinity, height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _scan,
                      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      label: Text('Scan for Bias with AI', style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VisoraColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0))),

              // ── Results ──
              if (result != null) ...[
                const SizedBox(height: 24),
                if (result.containsKey('error'))
                  Container(padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: VisoraColors.errorContainer, borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.error_outline, color: VisoraColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(result['error'].toString(),
                        style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.error, height: 1.5))),
                    ]))
                else ...[
                  // ── Overall Risk Badge ──
                  _buildRiskBadge(result).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

                  const SizedBox(height: 16),

                  // ── Bias Score ──
                  _buildScoreCard(result).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  // ── Flagged Phrases ──
                  if (result['flags'] != null && (result['flags'] as List).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildFlagsCard(result).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  ],

                  // ── Legal Risks ──
                  if (result['legal_risks'] != null && (result['legal_risks'] as List).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildLegalCard(result).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  ],

                  // ── Improved Text ──
                  if (result['improved_text'] != null) ...[
                    const SizedBox(height: 16),
                    _buildImprovedTextCard(result).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  ],
                ],
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildRiskBadge(Map<String, dynamic> result) {
    final risk = (result['overall_risk'] ?? 'UNKNOWN').toString().toUpperCase();
    final color = risk == 'HIGH' ? VisoraColors.error
        : risk == 'MODERATE' ? const Color(0xFFF9AB00)
        : VisoraColors.success;
    final icon = risk == 'HIGH' ? Icons.dangerous_rounded
        : risk == 'MODERATE' ? Icons.warning_amber_rounded
        : Icons.verified_rounded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$risk RISK', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(result['summary']?.toString() ?? '',
            style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.onSurface, height: 1.5)),
        ])),
      ]),
    );
  }

  Widget _buildScoreCard(Map<String, dynamic> result) {
    final score = (result['bias_score'] ?? 0);
    final scoreNum = score is int ? score.toDouble() : (score as num).toDouble();
    return VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BIAS SCORE', style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1)),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${scoreNum.toInt()}', style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w700,
          color: scoreNum > 60 ? VisoraColors.error : scoreNum > 30 ? const Color(0xFFF9AB00) : VisoraColors.success)),
        Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Text('/100', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: VisoraColors.onSurfaceVariant))),
      ]),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: scoreNum / 100,
          backgroundColor: VisoraColors.surface,
          valueColor: AlwaysStoppedAnimation(
            scoreNum > 60 ? VisoraColors.error : scoreNum > 30 ? const Color(0xFFF9AB00) : VisoraColors.success),
          minHeight: 8)),
    ]));
  }

  Widget _buildFlagsCard(Map<String, dynamic> result) {
    final flags = result['flags'] as List;
    return VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.flag_rounded, color: VisoraColors.error, size: 18),
        const SizedBox(width: 8),
        Text('Flagged Phrases (${flags.length})', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
      ]),
      const SizedBox(height: 16),
      ...flags.map((flag) {
        final f = flag as Map<String, dynamic>;
        final severity = f['severity']?.toString() ?? 'LOW';
        final sevColor = severity == 'HIGH' ? VisoraColors.error
            : severity == 'MODERATE' ? const Color(0xFFF9AB00)
            : VisoraColors.success;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sevColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sevColor.withValues(alpha: 0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(severity, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: sevColor))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: VisoraColors.primaryContainer, borderRadius: BorderRadius.circular(6)),
                child: Text(f['type']?.toString().toUpperCase() ?? '', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600, color: VisoraColors.primary))),
            ]),
            const SizedBox(height: 10),
            Text('"${f['phrase'] ?? ''}"', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.onSurface, fontStyle: FontStyle.italic)),
            const SizedBox(height: 6),
            Text(f['explanation']?.toString() ?? '', style: GoogleFonts.inter(
              fontSize: 13, color: VisoraColors.onSurfaceVariant, height: 1.5)),
            if (f['suggestion'] != null) ...[
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lightbulb_outline, color: VisoraColors.success, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text('Suggestion: ${f['suggestion']}', style: GoogleFonts.inter(
                  fontSize: 12, color: VisoraColors.success, fontWeight: FontWeight.w500, height: 1.4))),
              ]),
            ],
          ]),
        );
      }),
    ]));
  }

  Widget _buildLegalCard(Map<String, dynamic> result) {
    final risks = (result['legal_risks'] as List).map((e) => e.toString()).toList();
    return VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.gavel_rounded, color: const Color(0xFFF9AB00), size: 18),
        const SizedBox(width: 8),
        Text('Legal & Regulatory Risks', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
      ]),
      const SizedBox(height: 12),
      ...risks.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_amber_rounded, color: const Color(0xFFF9AB00), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(r, style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.onSurface, height: 1.4))),
        ]),
      )),
    ]));
  }

  Widget _buildImprovedTextCard(Map<String, dynamic> result) {
    return VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.auto_fix_high_rounded, color: VisoraColors.success, size: 18),
        const SizedBox(width: 8),
        Text('AI-Suggested Improvement', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
      ]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VisoraColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(8)),
        child: Text(result['improved_text'].toString(),
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0D652D), height: 1.6)),
      ),
    ]));
  }
}

class _ExampleChip extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _ExampleChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: VisoraColors.surfaceLowest,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: VisoraColors.outline)),
          child: Text(label, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500, color: VisoraColors.onSurfaceVariant)))));
  }
}
