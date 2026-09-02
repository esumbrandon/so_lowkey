import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/discovery/screens/discovery_screen.dart';
import '../../features/lounges/screens/lounge_screen.dart';
import '../../features/chat/screens/chat_detail_screen.dart';

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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = _GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authRefresh,
    redirect: (context, state) async {
      final user = Supabase.instance.client.auth.currentUser;
      final loggingIn = state.matchedLocation == '/login';

      if (user == null) {
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        // Signed in but on the login page — send onward. Onboarding screen
        // itself upserts the profile, so a light existence check is enough.
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/discovery',
        builder: (context, state) => const DiscoveryScreen(),
      ),
      GoRoute(
        path: '/lounges',
        builder: (context, state) => const LoungeScreen(),
      ),
      GoRoute(
        path: '/chat/:connectionId',
        builder: (context, state) {
          final connectionId = state.pathParameters['connectionId']!;
          final peerAlias =
              state.uri.queryParameters['alias'] ?? 'So-Lowkey Companion';
          return ChatDetailScreen(
            connectionId: connectionId,
            peerAlias: peerAlias,
          );
        },
      ),
    ],
  );
});
