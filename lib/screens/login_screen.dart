import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnack('Please enter both username and password', VisoraColors.error);
      return;
    }

    final success = await ref.read(authProvider.notifier).login(username, password);
    if (success && mounted) context.go('/home');
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _LoginBackgroundPainter(Theme.of(context).brightness == Brightness.dark))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 820;
                      final product = _ProductPanel(wide: wide)
                          .animate()
                          .fadeIn(duration: 360.ms)
                          .slideX(begin: wide ? -0.04 : 0);
                      return Flex(
                        direction: wide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (wide) Expanded(flex: 5, child: product) else product,
                          SizedBox(width: wide ? 28 : 0, height: wide ? 0 : 22),
                          SizedBox(
                            width: wide ? 420 : double.infinity,
                            child: _LoginPanel(
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              rememberMe: _rememberMe,
                              isLoading: auth.isLoading,
                              error: auth.error,
                              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                              onRememberChanged: (value) => setState(() => _rememberMe = value),
                              onSubmit: _handleLogin,
                            ).animate().fadeIn(delay: 100.ms, duration: 360.ms).slideY(begin: 0.04),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPanel extends StatelessWidget {
  final bool wide;
  const _ProductPanel({required this.wide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: wide ? 12 : 0),
      child: Column(
        crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VisoraBrandMark(size: 46),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visora', style: Theme.of(context).textTheme.headlineSmall),
                  Text('AI Bias Audit Platform', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'Professional governance for high-stakes AI decisions.',
            textAlign: wide ? TextAlign.left : TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Measure fairness, surface human impact, and export compliance evidence with a focused workflow built for review teams.',
              textAlign: wide ? TextAlign.left : TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: wide ? 520 : double.infinity,
            height: 240,
            child: const _DecisionMatrix(),
          ),
        ],
      ),
    );
  }
}

class _DecisionMatrix extends StatefulWidget {
  const _DecisionMatrix();

  @override
  State<_DecisionMatrix> createState() => _DecisionMatrixState();
}

class _DecisionMatrixState extends State<_DecisionMatrix> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _DecisionMatrixPainter(_controller.value, Theme.of(context).brightness == Brightness.dark),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 16, color: VisoraColors.success),
                  const SizedBox(width: 8),
                  Text('AES-256 session security', style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DecisionMatrixPainter extends CustomPainter {
  final double t;
  final bool dark;

  _DecisionMatrixPainter(this.t, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [const Color(0xFF1A1D21), const Color(0xFF203A5E)]
            : [const Color(0xFFFFFFFF), const Color(0xFFE8F0FE)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bg);

    final grid = Paint()
      ..color = (dark ? Colors.white : VisoraColors.primary).withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 18), Offset(x, size.height - 18), grid);
    }
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), grid);
    }

    final colors = [VisoraColors.googleBlue, VisoraColors.googleRed, VisoraColors.googleYellow, VisoraColors.googleGreen];
    for (int i = 0; i < 4; i++) {
      final y = 42 + i * 38.0;
      final start = 42.0;
      final end = size.width - 58 - math.sin((t * math.pi * 2) + i) * 18;
      final paint = Paint()
        ..color = colors[i].withValues(alpha: 0.78)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(start, y), Offset(end, y), paint);
      canvas.drawCircle(Offset(end, y), 6, Paint()..color = colors[i]);
    }

    final ring = Paint()
      ..color = VisoraColors.success.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width - 72, 68), radius: 36),
      -math.pi / 2,
      math.pi * 1.62,
      false,
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant _DecisionMatrixPainter oldDelegate) => oldDelegate.t != t || oldDelegate.dark != dark;
}

class _LoginPanel extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isLoading;
  final String? error;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onSubmit;

  const _LoginPanel({
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.isLoading,
    required this.error,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      prominent: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin login', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Use your encrypted workspace credentials.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          const _InputLabel(label: 'Username'),
          const SizedBox(height: 8),
          TextField(
            controller: usernameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'admin',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 18),
          const _InputLabel(label: 'Password'),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: 'Enter password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: onTogglePassword,
                icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(value: rememberMe, onChanged: (value) => onRememberChanged(value ?? false)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Remember me', style: Theme.of(context).textTheme.bodySmall)),
              TextButton(onPressed: () {}, child: const Text('Forgot?')),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            InfoBanner(
              icon: Icons.error_outline_rounded,
              title: 'Authentication failed',
              body: error!,
              color: VisoraColors.error,
            ).animate().shakeX(hz: 4, amount: 3),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(isLoading ? 'Signing in...' : 'Sign In'),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: VisoraColors.success, size: 17),
              const SizedBox(width: 8),
              Expanded(child: Text('Encrypted local session', style: Theme.of(context).textTheme.bodySmall)),
              const SeverityBadge(label: 'Secure'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface));
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  final bool dark;
  _LoginBackgroundPainter(this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [const Color(0xFF121417), const Color(0xFF18233A)]
            : [const Color(0xFFF8FAFD), const Color(0xFFEAF2FF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final line = Paint()
      ..color = (dark ? Colors.white : VisoraColors.primary).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const step = 64.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    final colors = [VisoraColors.googleBlue, VisoraColors.googleRed, VisoraColors.googleYellow, VisoraColors.googleGreen];
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()..color = colors[i].withValues(alpha: dark ? 0.20 : 0.16);
      canvas.drawRect(Rect.fromLTWH(size.width - 18.0 * (i + 1), 0, 8, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoginBackgroundPainter oldDelegate) => oldDelegate.dark != dark;
}
