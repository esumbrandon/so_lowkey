import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/widgets/app_nav_menu.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleSignIn(Future<void> Function() signInFn) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await signInFn();
      if (mounted) {
        context.go('/lounges');
      }
    } catch (e) {
      if (!isSupabaseConfigured && mounted) {
        context.go('/lounges');
      } else {
        setState(() => _error = 'Could not sign in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  tooltip: 'Dev Screen Switcher',
                  color: AppColors.textMuted,
                  onPressed: () => showAppNavigationModal(context),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.nightlight_round,
                color: AppColors.biscuit,
                size: 56,
              ),
              const SizedBox(height: 24),
              const Text(
                'So-Lowkey',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'A quiet corner of the internet for people who\'d rather connect slowly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 48),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.terracotta),
                ),
                const SizedBox(height: 16),
              ],
              _AuthButton(
                label: 'Continue with Apple',
                icon: Icons.apple,
                isLoading: _isLoading,
                onPressed: () => _handleSignIn(authController.signInWithApple),
                background: AppColors.textPrimary,
                foreground: AppColors.background,
              ),
              const SizedBox(height: 12),
              _AuthButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                isLoading: _isLoading,
                onPressed: () => _handleSignIn(authController.signInWithGoogle),
                background: AppColors.surfaceElevated,
                foreground: AppColors.textPrimary,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.biscuit,
                  side: const BorderSide(color: AppColors.biscuit),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.explore_outlined, size: 20),
                label: const Text(
                  'Explore App (Dev Mode)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () => context.go('/lounges'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
