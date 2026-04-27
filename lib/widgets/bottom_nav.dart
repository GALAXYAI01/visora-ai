import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'gemini_chatbot.dart';
import 'profile_drawer.dart';
import '../services/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String loc) {
    if (loc.startsWith('/simulate')) return 1;
    if (loc.startsWith('/scanner'))  return 2;
    if (loc.startsWith('/reports'))  return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _locationToIndex(location);
    final auth = ref.watch(authProvider);
    final initials = (auth.userName ?? 'U')[0].toUpperCase();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          // Profile avatar — top right, works on every page
          Positioned(
            right: 16, top: MediaQuery.of(context).padding.top + 8,
            child: GestureDetector(
              onTap: () => showProfileDrawer(context, ref),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF1A73E8)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: VisoraColors.primary.withValues(alpha: 0.3), blurRadius: 8)]),
                child: Center(child: Text(initials, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
          ),
          // Gemini chatbot FAB
          Positioned(
            right: 16, bottom: 152,
            child: _ChatFab(onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const GeminiChatSheet(),
              );
            }),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomNav(currentIndex: idx),
          ),
        ],
      ),
    );
  }
}

class _ChatFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatFab({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0xFF4285F4).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0: context.go('/home');     break;
      case 1: context.go('/simulate'); break;
      case 2: context.go('/scanner');  break;
      case 3: context.go('/reports');  break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded,       label: 'Home',     active: currentIndex == 0, onTap: () => _onTap(context, 0)),
              _NavItem(icon: Icons.analytics_rounded,  label: 'Simulate', active: currentIndex == 1, onTap: () => _onTap(context, 1)),
              _NavItem(icon: Icons.radar_rounded,      label: 'Scanner',  active: currentIndex == 2, onTap: () => _onTap(context, 2)),
              _NavItem(icon: Icons.assessment_rounded,  label: 'Reports',  active: currentIndex == 3, onTap: () => _onTap(context, 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 64, height: 32,
                decoration: active
                  ? BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(9999),
                    )
                  : null,
                child: Icon(icon,
                  color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                  size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
