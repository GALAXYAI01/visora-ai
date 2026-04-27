import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/providers.dart';

class HumanCostScreen extends ConsumerWidget {
  const HumanCostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final result = ref.watch(auditResultProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(fit: StackFit.expand, children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header ──
              Row(children: [
                MouseRegion(cursor: SystemMouseCursors.click,
                  child: GestureDetector(onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                    child: const Icon(Icons.arrow_back_rounded, color: VisoraColors.onSurface, size: 24))),
                const SizedBox(width: 12),
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

              // ── Title ──
              Text('Human Impact', style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.w700, color: VisoraColors.onSurface, letterSpacing: -0.4))
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 4),
              Text('The real cost of biased AI', style: GoogleFonts.inter(
                fontSize: 14, color: VisoraColors.onSurfaceVariant))
                .animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // ── Legal Risk Level ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Legal Risk Level', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: VisoraColors.errorContainer, borderRadius: BorderRadius.circular(4)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.warning_rounded, color: VisoraColors.error, size: 14),
                      const SizedBox(width: 4),
                      Text('CRITICAL', style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w600, color: VisoraColors.error, letterSpacing: 0.5)),
                    ])),
                ]),
                const SizedBox(height: 16),
                RichText(text: TextSpan(children: [
                  TextSpan(text: '95', style: GoogleFonts.inter(
                    fontSize: 48, fontWeight: FontWeight.w700, color: VisoraColors.error)),
                  TextSpan(text: '/100', style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w400, color: VisoraColors.onSurfaceVariant)),
                ])),
                const SizedBox(height: 12),
                Text('Immediate intervention required to prevent regulatory action.',
                  style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.onSurfaceVariant, height: 1.5)),
              ])).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.06),

              const SizedBox(height: 12),

              // ── Impact Scale & Financial Impact ──
              Row(children: [
                Expanded(child: VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.groups_rounded, color: VisoraColors.error, size: 20),
                    const SizedBox(width: 8),
                    Flexible(child: Text('Impact Scale', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.onSurface))),
                  ]),
                  const SizedBox(height: 12),
                  Text('2,847', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
                  const SizedBox(height: 4),
                  Text('Unfair Decisions/Month', style: GoogleFonts.inter(fontSize: 11, color: VisoraColors.onSurfaceVariant)),
                ]))),
                const SizedBox(width: 12),
                Expanded(child: VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.account_balance_rounded, color: VisoraColors.error, size: 20),
                    const SizedBox(width: 8),
                    Flexible(child: Text('Financial Liability', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.onSurface))),
                  ]),
                  const SizedBox(height: 12),
                  Text('\$4.27B', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: VisoraColors.error)),
                  const SizedBox(height: 4),
                  Text('Projected Lawsuit Exposure', style: GoogleFonts.inter(fontSize: 11, color: VisoraColors.onSurfaceVariant)),
                ]))),
              ]).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.06),

              const SizedBox(height: 24),

              // ── Demographic Disparity A/B Test ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Demographic Disparity Analysis (A/B Test)', style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                const SizedBox(height: 20),

                // Profile A
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VisoraColors.background,
                    borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(color: VisoraColors.surfaceHigh, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded, color: VisoraColors.onSurfaceVariant, size: 28)),
                    const SizedBox(height: 12),
                    Text('Priya Sharma', style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                    const SizedBox(height: 4),
                    Text('Original Candidate Profile', style: GoogleFonts.inter(
                      fontSize: 12, color: VisoraColors.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: VisoraColors.errorContainer, borderRadius: BorderRadius.circular(9999)),
                      child: Text('REJECTED (Score: 42)', style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.error))),
                  ]),
                ),

                const SizedBox(height: 12),
                Center(child: Column(children: [
                  Icon(Icons.arrow_downward_rounded, color: VisoraColors.primary, size: 20),
                  Text('Name Swapped Only', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w500, color: VisoraColors.primary)),
                ])),
                const SizedBox(height: 12),

                // Profile B
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VisoraColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VisoraColors.primary.withValues(alpha: 0.2))),
                  child: Column(children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(color: VisoraColors.primaryContainer, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded, color: VisoraColors.primary, size: 28)),
                    const SizedBox(height: 12),
                    Text('Peter Sharma', style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                    const SizedBox(height: 4),
                    Text('Modified Shadow Profile', style: GoogleFonts.inter(
                      fontSize: 12, color: VisoraColors.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: VisoraColors.tertiaryContainer, borderRadius: BorderRadius.circular(9999)),
                      child: Text('HIRED (Score: 81)', style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0D652D)))),
                  ]),
                ),
              ])).animate().fadeIn(delay: 400.ms, duration: 500.ms),

              const SizedBox(height: 24),

              // ── Regulatory Compliance ──
              Text('Regulatory Compliance Status', style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w600, color: VisoraColors.onSurface))
                .animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 12),

              _RegItem(icon: Icons.gavel_rounded, title: 'EU AI Act', status: 'VIOLATION', isViolation: true)
                .animate().fadeIn(delay: 550.ms, duration: 300.ms),
              const SizedBox(height: 8),
              _RegItem(icon: Icons.security_rounded, title: 'GDPR', status: 'VIOLATION', isViolation: true)
                .animate().fadeIn(delay: 600.ms, duration: 300.ms),
              const SizedBox(height: 8),
              _RegItem(icon: Icons.business_center_rounded, title: 'EEOC', status: 'VIOLATION', isViolation: true)
                .animate().fadeIn(delay: 650.ms, duration: 300.ms),

              const SizedBox(height: 32),

              // ── Back CTA ──
              MouseRegion(cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                  child: Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      color: VisoraColors.primary,
                      borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('Back to Results', style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)))))).animate().fadeIn(delay: 700.ms),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _RegItem extends StatelessWidget {
  final IconData icon; final String title, status; final bool isViolation;
  const _RegItem({required this.icon, required this.title, required this.status, required this.isViolation});

  @override
  Widget build(BuildContext context) {
    return VisoraCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(
          color: isViolation ? VisoraColors.errorContainer : VisoraColors.tertiaryContainer,
          shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: isViolation ? VisoraColors.error : VisoraColors.success)),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: VisoraColors.onSurface))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isViolation ? VisoraColors.errorContainer : VisoraColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(4)),
        child: Text(status, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: isViolation ? VisoraColors.error : VisoraColors.success, letterSpacing: 0.5))),
    ]));
  }
}
