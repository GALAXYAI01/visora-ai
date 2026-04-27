import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/providers.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});
  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  double _age = 34;
  double _hours = 45;
  String _education = 'Bachelors';
  String _race = 'White';
  String _gender = 'Male';

  @override
  Widget build(BuildContext context) {
    final sim = ref.watch(simulationProvider);
    return Scaffold(
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
                  fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                const Spacer(),
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: VisoraColors.primaryContainer, shape: BoxShape.circle),
                  child: Center(child: Text('EP', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: VisoraColors.primary)))),
                const SizedBox(width: 50), // space for profile avatar
              ]).animate().fadeIn(duration: 200.ms),

              Divider(height: 32, color: VisoraColors.surface),

              // ── Title ──
              Text('What-If Simulator', style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.4))
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 8),
              Text('Adjust parameters to simulate model predictions and identify potential vulnerabilities.',
                style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6))
                .animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 32),

              // ── Subject Profile Card ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.tune_rounded, color: VisoraColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Subject Profile', style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                ]),
                const SizedBox(height: 16),
                Divider(color: VisoraColors.surface),
                const SizedBox(height: 20),

                // Age slider
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Age', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                  Text('${_age.round()}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                ]),
                Slider(value: _age, min: 18, max: 80,
                  onChanged: (v) => setState(() => _age = v)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('18', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text('80', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ])),

                const SizedBox(height: 24),

                // Hours/Week slider
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Hours/Week', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                  Text('${_hours.round()} hrs', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                ]),
                Slider(value: _hours, min: 0, max: 80,
                  onChanged: (v) => setState(() => _hours = v)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('0', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text('80', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ])),

                const SizedBox(height: 24),

                // Education dropdown
                Text('Education Level', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: VisoraColors.outline),
                    borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true, value: _education,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                      icon: Icon(Icons.expand_more_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      items: ['HS-grad', 'Some-college', 'Bachelors', 'Masters', 'Doctorate']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e == 'Bachelors' ? 'Bachelors Degree' : e))).toList(),
                      onChanged: (v) => setState(() => _education = v!)))),

                const SizedBox(height: 24),

                // Race dropdown
                Text('Race / Ethnicity', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: VisoraColors.outline),
                    borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true, value: _race,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                      icon: Icon(Icons.expand_more_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      items: ['White', 'Black', 'Asian-Pac-Islander', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e == 'White' ? 'Caucasian' : e))).toList(),
                      onChanged: (v) => setState(() => _race = v!)))),

                const SizedBox(height: 24),

                // Gender toggle
                Text('Gender', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: VisoraColors.outline),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: ['Male', 'Female', 'Non-Binary'].map((g) {
                    final selected = _gender == g;
                    return Expanded(child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = g),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? VisoraColors.surfaceHigh : Colors.transparent,
                            borderRadius: BorderRadius.circular(7)),
                          child: Center(child: Text(g, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? VisoraColors.primary : VisoraColors.onSurfaceVariant)))))));
                  }).toList()),
                ),

                const SizedBox(height: 24),
                Divider(color: VisoraColors.surface),
                const SizedBox(height: 16),

                // CTA
                sim.isLoading
                  ? const Center(child: CircularProgressIndicator(color: VisoraColors.primary))
                  : MouseRegion(cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => ref.read(simulationProvider.notifier).predict(
                          age: _age.round(), hoursPerWeek: _hours.round(),
                          education: _education, race: _race, gender: _gender),
                        child: Container(
                          width: double.infinity, height: 52,
                          decoration: BoxDecoration(
                            color: VisoraColors.primary,
                            borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Predict Decision', style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          ])))),
              ])).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.06),

              // ── Result Card ──
              if (sim.result != null) ...[
                const SizedBox(height: 20),
                VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.auto_awesome_rounded, color: VisoraColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Prediction Result', style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (sim.result!['prediction'] == '>50K') ? VisoraColors.tertiaryContainer : VisoraColors.errorContainer,
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon((sim.result!['prediction'] == '>50K') ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: (sim.result!['prediction'] == '>50K') ? VisoraColors.success : VisoraColors.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Predicted: ${sim.result!['prediction'] ?? 'N/A'}', style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                        Text('Confidence: ${((sim.result!['confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ])),
                    ])),
                  if (sim.result!['bias_flag'] == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VisoraColors.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(Icons.warning_rounded, color: VisoraColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('⚠ Potential bias detected in this prediction',
                          style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.error))),
                      ])),
                  ],
                ])).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              ],

              if (sim.error != null) ...[
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: VisoraColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                  child: Text(sim.error!, style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.error))),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
