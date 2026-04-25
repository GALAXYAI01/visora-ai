import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_provider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter both username and password',
          style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: VisoraColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    final success = await ref.read(authProvider.notifier).login(username, password);
    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: VisoraColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo & Branding ──
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: VisoraColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: VisoraColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 36),
                ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 24),

                Text('Visora', style: GoogleFonts.inter(
                  fontSize: 32, fontWeight: FontWeight.w700, color: VisoraColors.onSurface, letterSpacing: -0.5))
                  .animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 4),

                Text('AI Bias Audit Platform', style: GoogleFonts.inter(
                  fontSize: 14, color: VisoraColors.onSurfaceVariant))
                  .animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                // ── Login Card ──
                VisoraCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Login', style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
                      const SizedBox(height: 4),
                      Text('Enter your credentials to access the dashboard',
                        style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.onSurfaceVariant)),
                      const SizedBox(height: 28),

                      // ── Username Field ──
                      Text('Username', style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          hintStyle: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant.withValues(alpha: 0.5)),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: VisoraColors.onSurfaceVariant, size: 20),
                          filled: true,
                          fillColor: VisoraColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: VisoraColors.outline)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: VisoraColors.outline)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: VisoraColors.primary, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 20),

                      // ── Password Field ──
                      Text('Password', style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant.withValues(alpha: 0.5)),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: VisoraColors.onSurfaceVariant, size: 20),
                          suffixIcon: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: VisoraColors.onSurfaceVariant, size: 20),
                            ),
                          ),
                          filled: true,
                          fillColor: VisoraColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: VisoraColors.outline)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: VisoraColors.outline)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: VisoraColors.primary, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),

                      const SizedBox(height: 16),

                      // ── Remember Me + Forgot ──
                      Row(children: [
                        SizedBox(width: 20, height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            activeColor: VisoraColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          )),
                        const SizedBox(width: 8),
                        Text('Remember me', style: GoogleFonts.inter(
                          fontSize: 13, color: VisoraColors.onSurfaceVariant)),
                        const Spacer(),
                        MouseRegion(cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {},
                            child: Text('Forgot password?', style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500, color: VisoraColors.primary)),
                          )),
                      ]),

                      const SizedBox(height: 24),

                      // ── Error Message ──
                      if (auth.error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: VisoraColors.errorContainer,
                            borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Icon(Icons.error_outline_rounded, color: VisoraColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(auth.error!,
                              style: GoogleFonts.inter(fontSize: 13, color: VisoraColors.error))),
                          ]),
                        ).animate().fadeIn().shakeX(hz: 4, amount: 4),

                      // ── Login Button ──
                      MouseRegion(cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: auth.isLoading ? null : _handleLogin,
                          child: Container(
                            width: double.infinity, height: 52,
                            decoration: BoxDecoration(
                              color: auth.isLoading ? VisoraColors.primary.withValues(alpha: 0.7) : VisoraColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(
                                color: VisoraColors.primary.withValues(alpha: 0.25),
                                blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Center(child: auth.isLoading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Sign In', style: GoogleFonts.inter(
                                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.08),

                const SizedBox(height: 24),

                // ── Security Badge ──
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shield_rounded, color: VisoraColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text('End-to-end encrypted', style: GoogleFonts.inter(
                    fontSize: 12, color: VisoraColors.onSurfaceVariant)),
                  const SizedBox(width: 16),
                  Icon(Icons.lock_rounded, color: VisoraColors.onSurfaceVariant, size: 14),
                  const SizedBox(width: 4),
                  Text('AES-256', style: GoogleFonts.inter(
                    fontSize: 12, color: VisoraColors.onSurfaceVariant)),
                ]).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
