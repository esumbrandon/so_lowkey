import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

/// Platform detection helpers (iOS & Android).
bool get isIOSPlatform => defaultTargetPlatform == TargetPlatform.iOS;
bool get isAndroidPlatform => defaultTargetPlatform == TargetPlatform.android;
bool get isApplePlatform => defaultTargetPlatform == TargetPlatform.iOS;
bool get isMobilePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android;

/// Platform-safe haptics dispatcher for mobile devices.
class AppHaptics {
  AppHaptics._();

  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }
}

/// Adaptive page builder for GoRouter.
///
/// Returns [CupertinoPage] to enable iOS interactive edge swipe-to-back gesture
/// and native smooth slide transitions across mobile platforms.
Page<T> buildAdaptivePage<T>({
  required Widget child,
  LocalKey? key,
  String? name,
}) {
  return CupertinoPage<T>(key: key, name: name, child: child);
}

/// Adaptive page route builder for imperative [Navigator.push] calls.
/// Uses [CupertinoPageRoute] to provide native iOS interactive edge swipe-to-back gesture.
PageRoute<T> buildAdaptivePageRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  return CupertinoPageRoute<T>(builder: builder, settings: settings);
}

/// Adaptive back button that respects platform conventions:
/// - iOS: Chevron arrow icon (Cupertino)
/// - Android: Back arrow icon (Material)
class AdaptiveBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final String? fallbackLocation;

  const AdaptiveBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.fallbackLocation,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.textPrimary;

    return IconButton(
      icon: isApplePlatform
          ? Icon(CupertinoIcons.chevron_back, color: iconColor)
          : Icon(Icons.arrow_back, color: iconColor),
      tooltip: isApplePlatform ? 'Back' : 'Navigate back',
      onPressed: () {
        AppHaptics.light();
        if (onPressed != null) {
          onPressed!();
          return;
        }

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else if (fallbackLocation != null) {
          context.go(fallbackLocation!);
        } else {
          context.go('/lounges');
        }
      },
    );
  }
}

/// Adaptive confirmation dialog that matches Apple HIG on iOS and Material 3 on Android.
Future<bool?> showAdaptiveConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
}) {
  if (isApplePlatform) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(cancelText),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          child: Text(
            cancelText,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          onPressed: () => Navigator.pop(ctx, false),
        ),
        TextButton(
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDestructive ? AppColors.terracotta : AppColors.biscuit,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
}
