import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'YOUR_SUPABASE_URL';
  const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

  if (supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseKey != 'YOUR_SUPABASE_ANON_KEY' &&
      supabaseUrl.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
    } catch (e) {
      debugPrint('Running in offline/dev mode: $e');
    }
  }

  runApp(const ProviderScope(child: SoLowkey()));
}

class SoLowkey extends ConsumerWidget {
  const SoLowkey({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'So-Lowkey',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
