import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/discovery/screens/discovery_screen.dart';
import '../../features/lounges/screens/lounge_screen.dart';
import '../../features/chat/screens/chat_detail_screen.dart';
import '../../features/connections/screens/connections_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../mock/mock_data.dart';
import '../utils/platform_adaptive.dart';
import '../widgets/app_splash_screen.dart';
import '../widgets/main_shell.dart';

// ── Global Root Navigator Key ─────────────────────────────────────────────────
// Allows detail pages (like chat) to be pushed onto the root navigator above the shell,
// preserving the navigation history so iOS interactive edge swipe-to-back works natively.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// ── Auth change notifier for router refresh ───────────────────────────────────

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ── Router provider ───────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  if (!isSupabaseConfigured) {
    return _buildOfflineRouter();
  }
  return _buildLiveRouter(ref);
});

// ── Shell branches shared by both modes ──────────────────────────────────────

List<StatefulShellBranch> _buildShellBranches() {
  return [
    // Branch 0 — Lounges
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/lounges',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoungeScreen(),
          ),
        ),
      ],
    ),
    // Branch 1 — Discovery
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/discovery',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DiscoveryScreen(),
          ),
        ),
      ],
    ),
    // Branch 2 — Connections
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/connections',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ConnectionsScreen(),
          ),
        ),
      ],
    ),
    // Branch 3 — Profile
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
  ];
}

// ── Shared external routes ───────────────────────────────────────────────────

List<RouteBase> _buildSharedExternalRoutes() {
  return [
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/loading',
      pageBuilder: (context, state) => buildAdaptivePage(
        key: state.pageKey,
        child: const AppSplashScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/login',
      pageBuilder: (context, state) => buildAdaptivePage(
        key: state.pageKey,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/onboarding',
      pageBuilder: (context, state) => buildAdaptivePage(
        key: state.pageKey,
        child: const OnboardingScreen(),
      ),
    ),
    // Chat pushes above the shell with platform-native transition (iOS swipe-back gesture enabled)
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/chat/:connectionId',
      pageBuilder: (context, state) {
        final connectionId = state.pathParameters['connectionId']!;
        final peerAlias =
            state.uri.queryParameters['alias'] ?? 'So-Lowkey Companion';
        return buildAdaptivePage(
          key: state.pageKey,
          child: ChatDetailScreen(
            connectionId: connectionId,
            peerAlias: peerAlias,
          ),
        );
      },
    ),
  ];
}

// ── Offline / dev-mode router ─────────────────────────────────────────────────

GoRouter _buildOfflineRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/lounges',
    routes: [
      // Main shell with bottom nav (mobile) or side rail (desktop/web)
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: _buildShellBranches(),
      ),
      ..._buildSharedExternalRoutes(),
    ],
  );
}

// ── Live / Supabase-backed router ─────────────────────────────────────────────

GoRouter _buildLiveRouter(Ref ref) {
  final authRefresh = _GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/lounges',
    refreshListenable: authRefresh,
    redirect: (context, state) async {
      final user = Supabase.instance.client.auth.currentUser;
      final location = state.matchedLocation;

      final isAuthRoute =
          location == '/login' || location == '/onboarding' || location == '/loading';

      // Unauthenticated users → login
      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      // Authenticated user on login → check if onboarding is needed
      if (location == '/login') {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();
        return profile == null ? '/onboarding' : '/lounges';
      }

      return null;
    },
    routes: [
      // Main shell with bottom nav (mobile) or side rail (desktop/web)
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: _buildShellBranches(),
      ),
      ..._buildSharedExternalRoutes(),
    ],
  );
}
