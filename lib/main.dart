import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/results_screen.dart';
import 'screens/simulation_screen.dart';
import 'screens/remediation_screen.dart';
import 'screens/human_cost_screen.dart';
import 'screens/text_scanner_screen.dart';
import 'widgets/bottom_nav.dart';
import 'services/encryption_service.dart';
import 'services/auth_provider.dart';
import 'services/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize AES-256 encryption with secret from .env
  EncryptionService.initialize(
    secretKey: dotenv.env['ENCRYPTION_KEY'] ?? 'visora-default-key-2024-secure',
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: VisoraApp()));
}

class VisoraApp extends ConsumerStatefulWidget {
  const VisoraApp({super.key});

  @override
  ConsumerState<VisoraApp> createState() => _VisoraAppState();
}

class _VisoraAppState extends ConsumerState<VisoraApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Restore any existing encrypted session
    ref.read(authProvider.notifier).restoreSession();

    _router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        final isLoginRoute = state.uri.toString() == '/login';

        // Not authenticated → force login
        if (!auth.isAuthenticated && !isLoginRoute) return '/login';
        // Authenticated + on login → redirect to home
        if (auth.isAuthenticated && isLoginRoute) return '/home';

        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/home',     builder: (c, s) => const HomeScreen()),
            GoRoute(path: '/simulate', builder: (c, s) => const SimulationScreen()),
            GoRoute(path: '/reports',  builder: (c, s) => const RemediationScreen()),
            GoRoute(path: '/scanner',  builder: (c, s) => const TextScannerScreen()),
          ],
        ),
        GoRoute(path: '/upload',     builder: (c, s) => const UploadScreen()),
        GoRoute(path: '/progress',   builder: (c, s) => const ProgressScreen()),
        GoRoute(path: '/results',    builder: (c, s) => const ResultsScreen()),
        GoRoute(path: '/human-cost', builder: (c, s) => const HumanCostScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to trigger router rebuilds on login/logout
    ref.watch(authProvider);
    // Watch settings for live theme switching
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Visora',
      debugShowCheckedModeBanner: false,
      theme: VisoraTheme.light,
      darkTheme: VisoraTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: _router,
    );
  }
}

