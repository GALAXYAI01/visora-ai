import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Visora "Luminous Professional" Design System
// ═══════════════════════════════════════════════════════════════════════════════

class VisoraColors {
  // ── Surface Hierarchy (Light Foundation) ──────────────────────────────────
  static const background     = Color(0xFFF8F9FA);
  static const surfaceDim     = Color(0xFFF1F3F4);
  static const surfaceLowest  = Color(0xFFFFFFFF);
  static const surfaceLow     = Color(0xFFF8F9FA);
  static const surface        = Color(0xFFF1F3F4);
  static const surfaceHigh    = Color(0xFFE8EAED);
  static const surfaceHighest = Color(0xFFDADCE0);
  static const surfaceBright  = Color(0xFFFFFFFF);

  // ── Primary (Google Blue) ────────────────────────────────────────────────
  static const primary           = Color(0xFF1A73E8);
  static const primaryContainer  = Color(0xFFD2E3FC);
  static const onPrimary         = Color(0xFFFFFFFF);
  static const primaryFixedDim   = Color(0xFF1A73E8);
  static const inversePrimary    = Color(0xFF1A73E8);

  // ── Secondary ────────────────────────────────────────────────────────────
  static const secondary          = Color(0xFF5F6368);
  static const secondaryContainer = Color(0xFFE8EAED);
  static const onSecondary        = Color(0xFFFFFFFF);

  // ── Tertiary (Green) ─────────────────────────────────────────────────────
  static const tertiary          = Color(0xFF1E8E3E);
  static const tertiaryFixed     = Color(0xFFCEEAD6);
  static const tertiaryContainer = Color(0xFFCEEAD6);

  // ── Error ───────────────────────────────────────────────────────────────
  static const error          = Color(0xFFD93025);
  static const errorContainer = Color(0xFFFCE8E6);
  static const onError        = Color(0xFFFFFFFF);

  // ── On-Surface Text ─────────────────────────────────────────────────────
  static const onBackground     = Color(0xFF202124);
  static const onSurface        = Color(0xFF202124);
  static const onSurfaceVariant = Color(0xFF5F6368);
  static const outline          = Color(0xFFDADCE0);
  static const outlineVariant   = Color(0xFFF1F3F4);

  // ── Semantic Status ─────────────────────────────────────────────────────
  static const danger  = Color(0xFFD93025);
  static const success = Color(0xFF1E8E3E);
  static const warning = Color(0xFFF9AB00);
  static const info    = Color(0xFF1A73E8);

  // ── Gradients (simplified for light theme) ──────────────────────────────
  static const gradientStart = Color(0xFF1A73E8);
  static const gradientEnd   = Color(0xFF1557B0);

  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.centerLeft, end: Alignment.centerRight,
    colors: [gradientStart, gradientEnd],
  );

  static LinearGradient get primaryGradientDiag => const LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  // ── Card styling ────────────────────────────────────────────────────────
  static Color get glassBackground => const Color(0xFFFFFFFF).withValues(alpha: 0.95);
  static const cardBorder    = Color(0xFFF1F3F4);
  static const cardInnerGlow = Color(0x00000000);
  static const ghostBorder   = Color(0xFFDADCE0);

  // ── Status badge colors ─────────────────────────────────────────────────
  static const warningBg = Color(0xFFFEF7E0);
  static const warningFg = Color(0xFFB06000);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Theme
// ═══════════════════════════════════════════════════════════════════════════════

class VisoraTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: VisoraColors.background,
      colorScheme: const ColorScheme.light(
        primary:          VisoraColors.primary,
        primaryContainer: VisoraColors.primaryContainer,
        secondary:        VisoraColors.secondary,
        tertiary:         VisoraColors.tertiary,
        error:            VisoraColors.error,
        surface:          VisoraColors.surfaceLowest,
        onPrimary:        VisoraColors.onPrimary,
        onSurface:        VisoraColors.onSurface,
        onError:          VisoraColors.onError,
      ),
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: VisoraColors.surfaceLowest, elevation: 0, scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: VisoraColors.onSurface),
        iconTheme: const IconThemeData(color: VisoraColors.onSurface),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: VisoraColors.surfaceLowest,
        selectedItemColor: VisoraColors.primary,
        unselectedItemColor: VisoraColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed, elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: VisoraColors.surfaceLowest, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: VisoraColors.outlineVariant, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VisoraColors.primary,
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: VisoraColors.surfaceLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: VisoraColors.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: VisoraColors.outline)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VisoraColors.primary, width: 2)),
        labelStyle: GoogleFonts.inter(color: VisoraColors.onSurfaceVariant),
        hintStyle: GoogleFonts.inter(color: VisoraColors.onSurfaceVariant),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: VisoraColors.primary,
        thumbColor: VisoraColors.primary,
        inactiveTrackColor: VisoraColors.surfaceHigh,
        overlayColor: VisoraColors.primary.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      dividerColor: VisoraColors.outlineVariant,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Keep backward compatibility
  static ThemeData get dark => light;

  static TextTheme get _textTheme => TextTheme(
    displayLarge:  GoogleFonts.inter(fontSize: 56, fontWeight: FontWeight.w700, color: VisoraColors.onSurface),
    displayMedium: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w700, color: VisoraColors.onSurface),
    displaySmall:  GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: VisoraColors.onSurface),
    headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: VisoraColors.onSurface),
    headlineMedium:GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: VisoraColors.onSurface),
    headlineSmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: VisoraColors.onSurface),
    titleLarge:    GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: VisoraColors.onSurface),
    titleMedium:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: VisoraColors.onSurface),
    titleSmall:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.onSurface),
    bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: VisoraColors.onSurface),
    bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: VisoraColors.onSurfaceVariant),
    bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: VisoraColors.onSurfaceVariant),
    labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.onSurface),
    labelMedium:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 0.5),
    labelSmall:    GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1.0),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Reusable Widget Helpers
// ═══════════════════════════════════════════════════════════════════════════════

/// A clean card with white background and subtle shadow.
class VisoraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;

  const VisoraCard({super.key, required this.child, this.padding, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? VisoraColors.surfaceLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VisoraColors.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Primary CTA button — pill shaped, solid Google Blue.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  const GradientButton({super.key, required this.label, this.onPressed, this.icon, this.height = 52});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF3C4257),
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(color: VisoraColors.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Status badge — CRITICAL BIAS (red), WARNING (amber), COMPLIANT (green).
class SeverityBadge extends StatelessWidget {
  final String label;
  const SeverityBadge({super.key, required this.label});

  Color get _bgColor {
    switch (label.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL BIAS':
      case 'CRITICAL':      return VisoraColors.errorContainer;
      case 'MEDIUM':
      case 'WARNING':       return VisoraColors.warningBg;
      case 'LOW':
      case 'COMPLIANT':     return VisoraColors.tertiaryContainer;
      default:              return VisoraColors.surfaceHigh;
    }
  }

  Color get _fgColor {
    switch (label.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL BIAS':
      case 'CRITICAL':      return const Color(0xFFA50E0E);
      case 'MEDIUM':
      case 'WARNING':       return VisoraColors.warningFg;
      case 'LOW':
      case 'COMPLIANT':     return const Color(0xFF0D652D);
      default:              return VisoraColors.onSurfaceVariant;
    }
  }

  Color get _borderColor {
    switch (label.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL BIAS':
      case 'CRITICAL':      return VisoraColors.error.withValues(alpha: 0.2);
      case 'MEDIUM':
      case 'WARNING':       return VisoraColors.warning.withValues(alpha: 0.2);
      case 'LOW':
      case 'COMPLIANT':     return VisoraColors.success.withValues(alpha: 0.2);
      default:              return VisoraColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderColor),
      ),
      child: Center(
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _fgColor, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
