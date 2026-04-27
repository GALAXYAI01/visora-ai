import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import 'gemini_chatbot.dart';
import 'profile_drawer.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String loc) {
    if (loc.startsWith('/simulate')) return 1;
    if (loc.startsWith('/scanner')) return 2;
    if (loc.startsWith('/reports')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: isWide
                ? Row(
                    children: [
                      _SideRail(currentIndex: currentIndex),
                      Expanded(child: child),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned.fill(child: child),
                      Positioned(left: 16, bottom: 96, child: _ProfileButton(compact: true)),
                      Positioned(left: 0, right: 0, bottom: 0, child: _BottomNav(currentIndex: currentIndex)),
                    ],
                  ),
          ),
          Positioned(
            right: isWide ? 24 : 16,
            bottom: isWide ? 24 : 96,
            child: _ChatFab(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const GeminiChatSheet(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  final int currentIndex;
  const _SideRail({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              const VisoraBrandMark(size: 44),
              const SizedBox(height: 28),
              _RailItem(
                icon: Icons.dashboard_rounded,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              _RailItem(
                icon: Icons.tune_rounded,
                label: 'Sim',
                active: currentIndex == 1,
                onTap: () => context.go('/simulate'),
              ),
              _RailItem(
                icon: Icons.document_scanner_rounded,
                label: 'Scan',
                active: currentIndex == 2,
                onTap: () => context.go('/scanner'),
              ),
              _RailItem(
                icon: Icons.assessment_rounded,
                label: 'Report',
                active: currentIndex == 3,
                onTap: () => context.go('/reports'),
              ),
              const Spacer(),
              const _ProfileButton(compact: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 500),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? cs.primaryContainer.withValues(alpha: 0.84) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: active ? Border.all(color: cs.primary.withValues(alpha: 0.12)) : null,
              ),
              child: Column(
                children: [
                  Icon(icon, color: active ? cs.primary : cs.onSurfaceVariant, size: 21),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? cs.primary : cs.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends ConsumerWidget {
  final bool compact;
  const _ProfileButton({required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth.userName?.trim().isNotEmpty == true ? auth.userName!.trim() : 'User';
    final initials = name.characters.first.toUpperCase();

    return Tooltip(
      message: 'Profile',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => showProfileDrawer(context, ref),
          child: Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ask Visora AI',
      child: FloatingActionButton(
        elevation: 6,
        highlightElevation: 8,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: onTap,
        child: const Icon(Icons.auto_awesome_rounded),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/simulate');
        break;
      case 2:
        context.go('/scanner');
        break;
      case 3:
        context.go('/reports');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_rounded, label: 'Home', active: currentIndex == 0, onTap: () => _onTap(context, 0)),
              _NavItem(icon: Icons.tune_rounded, label: 'Simulate', active: currentIndex == 1, onTap: () => _onTap(context, 1)),
              _NavItem(icon: Icons.document_scanner_rounded, label: 'Scanner', active: currentIndex == 2, onTap: () => _onTap(context, 2)),
              _NavItem(icon: Icons.assessment_rounded, label: 'Reports', active: currentIndex == 3, onTap: () => _onTap(context, 3)),
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 48,
                height: 30,
                decoration: BoxDecoration(
                  color: active ? cs.primaryContainer.withValues(alpha: 0.9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: active ? cs.primary : cs.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? cs.primary : cs.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
