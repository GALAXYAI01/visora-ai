import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class GeminiTypingCard extends StatefulWidget {
  final String text;
  const GeminiTypingCard({super.key, required this.text});

  @override
  State<GeminiTypingCard> createState() => _GeminiTypingCardState();
}

class _GeminiTypingCardState extends State<GeminiTypingCard> {
  String _displayed = '';
  int _index = 0;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (_index >= widget.text.length) {
        t.cancel();
        if (mounted) setState(() => _done = true);
        return;
      }
      if (mounted) {
        setState(() {
          _displayed += widget.text[_index];
          _index++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VisoraColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VisoraColors.cardBorder),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VisoraColors.primaryContainer.withOpacity(0.07),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: const Center(
                child: Text('G', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
              ),
            ),
            const SizedBox(width: 8),
            Text('Gemini AI Insight',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: VisoraColors.outline)),
            const Spacer(),
            if (!_done)
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: VisoraColors.primaryContainer, borderRadius: BorderRadius.circular(4)),
              ),
          ]),
          const SizedBox(height: 10),
          Text(
            '"$_displayed${!_done ? '▌' : '"'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: VisoraColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          if (_done) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: VisoraColors.surfaceHighest,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text('ACTIONABLE ADVICE',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                  color: VisoraColors.primaryContainer, letterSpacing: 0.8)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Animated counter widget ─────────────────────────────────────────────────
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        widget.formatter(widget.value * _anim.value),
        style: widget.style,
      ),
    );
  }
}
