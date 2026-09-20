class AppConfig {
  AppConfig._();

  // Injected at build time via --dart-define (never hardcoded here).
  // Run with:
  //   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String deepLinkScheme = 'io.solowkey.app';

  /// OAuth redirect URI sent to Supabase.
  static const String oauthRedirectUri = '$deepLinkScheme://login-callback';

  /// Returns true when real Supabase credentials have been provided.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
