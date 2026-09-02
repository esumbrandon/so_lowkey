import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Streams Supabase auth state changes so the router / UI can react to
/// sign-in, sign-out, and token refresh events.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Convenience provider for the current signed-in user, if any.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

/// Whether the signed-in user has completed onboarding (i.e. has a profile row).
final hasProfileProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final result = await Supabase.instance.client
      .from('profiles')
      .select('id')
      .eq('id', user.id)
      .maybeSingle();

  return result != null;
});

class AuthController {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.solowkey.app://login-callback',
    );
  }

  Future<void> signInWithApple() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.solowkey.app://login-callback',
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(),
);
