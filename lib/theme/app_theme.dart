import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VisoraColors {
  static const googleBlue = Color(0xFF4285F4);
  static const googleRed = Color(0xFFEA4335);
  static const googleYellow = Color(0xFFFBBC04);
  static const googleGreen = Color(0xFF34A853);

  static const background = Color(0xFFF8FAFD);
  static const surfaceDim = Color(0xFFF1F4F9);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF8FAFD);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFEAF0F8);
  static const surfaceHighest = Color(0xFFDDE5F0);
  static const surfaceBright = Color(0xFFFFFFFF);

  static const primary = Color(0xFF1A73E8);
  static const primaryContainer = Color(0xFFD2E3FC);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixedDim = Color(0xFF1A73E8);
  static const inversePrimary = Color(0xFF8AB4F8);

  static const secondary = Color(0xFF5F6368);
  static const secondaryContainer = Color(0xFFE8EAED);
  static const onSecondary = Color(0xFFFFFFFF);

  static const tertiary = Color(0xFF1E8E3E);
  static const tertiaryFixed = Color(0xFFCEEAD6);
  static const tertiaryContainer = Color(0xFFE6F4EA);

  static const error = Color(0xFFD93025);
  static const errorContainer = Color(0xFFFCE8E6);
  static const onError = Color(0xFFFFFFFF);

  static const onBackground = Color(0xFF202124);
  static const onSurface = Color(0xFF202124);
  static const onSurfaceVariant = Color(0xFF5F6368);
  static const outline = Color(0xFFDADCE0);
  static const outlineVariant = Color(0xFFE8EAED);

  static const danger = error;
  static const success = Color(0xFF188038);
  static const warning = Color(0xFFF9AB00);
  static const info = primary;

  static const gradientStart = Color(0xFF4285F4);
  static const gradientEnd = Color(0xFF1A73E8);
  static const cardBorder = outlineVariant;
  static const cardInnerGlow = Color(0x00000000);
  static const ghostBorder = outline;
  static const warningBg = Color(0xFFFEF7E0);
  static const warningFg = Color(0xFFB06000);

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientEnd],
      );

  static LinearGradient get primaryGradientDiag => primaryGradient;

  static Color get glassBackground => surfaceLowest.withValues(alpha: 0.92);
}

class VisoraTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _textTheme(VisoraColors.onSurface, VisoraColors.onSurfaceVariant);
    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: VisoraColors.background,
      colorScheme: const ColorScheme.light(
        primary: VisoraColors.primary,
        primaryContainer: VisoraColors.primaryContainer,
        secondary: VisoraColors.secondary,
        secondaryContainer: VisoraColors.secondaryContainer,
        tertiary: VisoraColors.tertiary,
        tertiaryContainer: VisoraColors.tertiaryContainer,
        error: VisoraColors.error,
        errorContainer: VisoraColors.errorContainer,
        surface: VisoraColors.surface,
        onPrimary: VisoraColors.onPrimary,
        onSurface: VisoraColors.onSurface,
        onSurfaceVariant: VisoraColors.onSurfaceVariant,
        onError: VisoraColors.onError,
        outline: VisoraColors.outline,
        outlineVariant: VisoraColors.outlineVariant,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: VisoraColors.surfaceLowest,
        foregroundColor: VisoraColors.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: VisoraColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: VisoraColors.outlineVariant),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return VisoraColors.primary;
          return Colors.transparent;
        }),
      ),
      dividerColor: VisoraColors.outlineVariant,
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium,
        inputDecorationTheme: _inputDecoration(VisoraColors.surfaceLowest),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VisoraColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: VisoraColors.surfaceHighest,
          disabledForegroundColor: VisoraColors.onSurfaceVariant,
          elevation: 0,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VisoraColors.primary,
          side: const BorderSide(color: VisoraColors.outline),
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VisoraColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: _inputDecoration(VisoraColors.surfaceLowest),
      sliderTheme: SliderThemeData(
        activeTrackColor: VisoraColors.primary,
        inactiveTrackColor: VisoraColors.surfaceHigh,
        thumbColor: VisoraColors.primary,
        overlayColor: VisoraColors.primary.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return VisoraColors.primary;
          return VisoraColors.surfaceLowest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VisoraColors.primaryContainer;
          }
          return VisoraColors.surfaceHighest;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get dark {
    const bg = Color(0xFF121417);
    const surface = Color(0xFF1A1D21);
    const surfaceHigh = Color(0xFF242A31);
    const text = Color(0xFFE8EAED);
    const muted = Color(0xFFB7BDC6);
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _textTheme(text, muted);
    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8AB4F8),
        primaryContainer: Color(0xFF203A5E),
        secondary: Color(0xFFC3C6CB),
        secondaryContainer: Color(0xFF2B3037),
        tertiary: Color(0xFF81C995),
        tertiaryContainer: Color(0xFF17351F),
        error: Color(0xFFF28B82),
        errorContainer: Color(0xFF41211F),
        surface: surface,
        onPrimary: Color(0xFF0B1424),
        onSurface: text,
        onSurfaceVariant: muted,
        onError: Color(0xFF23100F),
        outline: Color(0xFF454B54),
        outlineVariant: Color(0xFF2E343B),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2E343B)),
        ),
      ),
      dividerColor: const Color(0xFF2E343B),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8AB4F8),
          foregroundColor: const Color(0xFF0B1424),
          elevation: 0,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF8AB4F8),
          side: const BorderSide(color: Color(0xFF454B54)),
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: _inputDecoration(surfaceHigh, dark: true),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF8AB4F8),
        inactiveTrackColor: surfaceHigh,
        thumbColor: const Color(0xFF8AB4F8),
        overlayColor: const Color(0xFF8AB4F8).withValues(alpha: 0.14),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
    );
  }

  static InputDecorationTheme _inputDecoration(Color fill, {bool dark = false}) {
    final border = dark ? const Color(0xFF454B54) : VisoraColors.outline;
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF8AB4F8) : VisoraColors.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VisoraColors.error),
      ),
      labelStyle: GoogleFonts.inter(
        color: dark ? const Color(0xFFB7BDC6) : VisoraColors.onSurfaceVariant,
        letterSpacing: 0,
      ),
      hintStyle: GoogleFonts.inter(
        color: dark ? const Color(0xFF8F98A5) : VisoraColors.onSurfaceVariant,
        letterSpacing: 0,
      ),
    );
  }

  static TextTheme _textTheme(Color text, Color muted) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(fontSize: 52, fontWeight: FontWeight.w800, color: text, letterSpacing: 0),
      displayMedium: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w800, color: text, letterSpacing: 0),
      displaySmall: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: text, letterSpacing: 0),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: text, letterSpacing: 0),
      headlineMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: text, letterSpacing: 0),
      headlineSmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: text, letterSpacing: 0),
      titleLarge: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800, color: text, letterSpacing: 0),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: text, letterSpacing: 0),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: text, letterSpacing: 0),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: text, height: 1.5, letterSpacing: 0),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: muted, height: 1.5, letterSpacing: 0),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: muted, height: 1.45, letterSpacing: 0),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: text, letterSpacing: 0),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: muted, letterSpacing: 0),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: muted, letterSpacing: 0),
    );
  }
}

class VisoraPage extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final bool center;

  const VisoraPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 112),
    this.maxWidth = 1180,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _PageGridPainter(Theme.of(context).dividerColor))),
        SafeArea(
          child: center ? Center(child: content) : content,
        ),
      ],
    );
  }
}

class _PageGridPainter extends CustomPainter {
  final Color color;
  _PageGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..strokeWidth = 1;
    const step = 56.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PageGridPainter oldDelegate) => oldDelegate.color != color;
}

class VisoraBrandMark extends StatelessWidget {
  final double size;
  const VisoraBrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(left: 8, top: 8, child: _brandTile(VisoraColors.googleBlue, size * 0.24)),
          Positioned(right: 8, top: 8, child: _brandTile(VisoraColors.googleRed, size * 0.18)),
          Positioned(left: 8, bottom: 8, child: _brandTile(VisoraColors.googleGreen, size * 0.18)),
          Positioned(right: 8, bottom: 8, child: _brandTile(VisoraColors.googleYellow, size * 0.24)),
        ],
      ),
    );
  }

  Widget _brandTile(Color color, double tileSize) {
    return Container(
      width: tileSize,
      height: tileSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class VisoraHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onBack;

  const VisoraHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          IconButton.outlined(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
        ],
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: cs.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 16),
          trailing!,
        ],
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class VisoraCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool prominent;

  const VisoraCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.onTap,
    this.prominent = false,
  });

  @override
  State<VisoraCard> createState() => _VisoraCardState();
}

class _VisoraCardState extends State<VisoraCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered && widget.onTap != null ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: widget.color ?? cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.borderColor ?? Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.prominent || _hovered ? 0.10 : 0.055),
              blurRadius: widget.prominent || _hovered ? 26 : 16,
              offset: Offset(0, widget.prominent || _hovered ? 14 : 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(20),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expanded;
  final bool secondary;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 50,
    this.expanded = true,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: onPressed == null ? 0.6 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: secondary ? null : VisoraColors.primaryGradient,
          color: secondary ? Theme.of(context).colorScheme.surface : null,
          borderRadius: BorderRadius.circular(8),
          border: secondary ? Border.all(color: Theme.of(context).dividerColor) : null,
          boxShadow: secondary
              ? null
              : [
                  BoxShadow(
                    color: VisoraColors.primary.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: secondary ? Theme.of(context).colorScheme.primary : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: secondary ? Theme.of(context).colorScheme.primary : Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor: onPressed == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: expanded ? SizedBox(width: double.infinity, child: child) : child,
    );
  }
}

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final IconData icon;
  final Color color;
  final double? progress;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.helper,
    required this.icon,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (progress != null)
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: Theme.of(context).dividerColor,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color),
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(helper!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class SeverityBadge extends StatelessWidget {
  final String label;
  const SeverityBadge({super.key, required this.label});

  Color get _bgColor {
    switch (label.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL BIAS':
      case 'CRITICAL':
      case 'VIOLATION':
      case 'REJECTED':
        return VisoraColors.errorContainer;
      case 'MEDIUM':
      case 'MODERATE':
      case 'WARNING':
      case 'PROCESSING':
        return VisoraColors.warningBg;
      case 'LOW':
      case 'COMPLIANT':
      case 'PASSED':
      case 'HIRED':
      case 'READY':
      case 'SECURE':
      case 'VERIFIED':
        return VisoraColors.tertiaryContainer;
      case 'GEMINI AI':
      case 'LIVE GOVERNANCE':
      case 'CSV':
      case 'QUEUED':
        return VisoraColors.primaryContainer;
      default:
        return VisoraColors.surfaceHigh;
    }
  }

  Color get _fgColor {
    switch (label.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL BIAS':
      case 'CRITICAL':
      case 'VIOLATION':
      case 'REJECTED':
        return const Color(0xFFA50E0E);
      case 'MEDIUM':
      case 'MODERATE':
      case 'WARNING':
      case 'PROCESSING':
        return VisoraColors.warningFg;
      case 'LOW':
      case 'COMPLIANT':
      case 'PASSED':
      case 'HIRED':
      case 'READY':
      case 'SECURE':
      case 'VERIFIED':
        return const Color(0xFF0D652D);
      case 'GEMINI AI':
      case 'LIVE GOVERNANCE':
      case 'CSV':
      case 'QUEUED':
        return VisoraColors.primary;
      default:
        return VisoraColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _fgColor.withValues(alpha: 0.16)),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _fgColor,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const InfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
