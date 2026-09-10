import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/mock/mock_data.dart';

/// Streams Supabase auth state changes so the router / UI can react to
/// sign-in, sign-out, and token refresh events.
final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!isSupabaseConfigured) {
    return const Stream.empty();
  }
  try {
    return Supabase.instance.client.auth.onAuthStateChange;
  } catch (_) {
    return const Stream.empty();
  }
});

/// Convenience provider for the current signed-in user, if any.
final currentUserProvider = Provider<User?>((ref) {
  if (!isSupabaseConfigured) {
    return mockCurrentUser;
  }
  try {
    final authState = ref.watch(authStateProvider).valueOrNull;
    return authState?.session?.user ?? Supabase.instance.client.auth.currentUser;
  } catch (_) {
    return mockCurrentUser;
  }
});

/// Whether the signed-in user has completed onboarding (i.e. has a profile row).
final hasProfileProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (!isSupabaseConfigured) return true;

  try {
    final user = ref.watch(currentUserProvider);
    if (user == null) return false;

    final result = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    return result != null;
  } catch (_) {
    return true;
  }
});

class AuthController {
  Future<void> signInWithGoogle() async {
    if (!isSupabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.solowkey.app://login-callback',
      );
    } catch (_) {}
  }

  Future<void> signInWithApple() async {
    if (!isSupabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.solowkey.app://login-callback',
      );
    } catch (_) {}
  }

  Future<void> signOut() async {
    if (!isSupabaseConfigured) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(),
);
