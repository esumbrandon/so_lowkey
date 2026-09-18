import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'adaptive_loading.dart';

class AppSplashScreen extends StatefulWidget {
  final String statusMessage;

  const AppSplashScreen({
    super.key,
    this.statusMessage = 'Finding your quiet space...',
  });

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.20, end: 0.45).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Breathing ambient orb with icon
            AnimatedBuilder(
              animation: _breathingController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [AppColors.biscuit, AppColors.surfaceElevated],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.biscuit.withValues(
                            alpha: _glowAnimation.value,
                          ),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.spa_rounded,
                        color: AppColors.background,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),

            // Branded typography
            const Text(
              'So-Lowkey',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quiet connection for introverts',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 48),

            // Adaptive spinner and calm status
            const AdaptiveLoadingIndicator(size: 20),
            const SizedBox(height: 16),
            Text(
              widget.statusMessage,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
