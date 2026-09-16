import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/platform_adaptive.dart';

/// Platform-adaptive loading spinner.
/// - iOS/macOS: [CupertinoActivityIndicator]
/// - Android/Web/Desktop: [CircularProgressIndicator] with warm styling
class AdaptiveLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AdaptiveLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppColors.biscuit;

    if (isApplePlatform) {
      return CupertinoActivityIndicator(
        radius: size / 2,
        color: indicatorColor,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );
  }
}

/// A soft, pulsing placeholder skeleton for calm loading states.
class ShimmerSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;

  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 14.0,
    this.margin,
    this.shape = BoxShape.rectangle,
  });

  const ShimmerSkeleton.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shape = BoxShape.circle;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            color: AppColors.surfaceElevated.withValues(alpha: _opacityAnim.value),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder for the Lounges screen.
class LoungeSkeletonList extends StatelessWidget {
  const LoungeSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 3,
      separatorBuilder: (context, _) => const SizedBox(height: 16),
      itemBuilder: (context, _) {
        return Container(
          height: 140,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.surfaceElevated.withValues(alpha: 0.6),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ShimmerSkeleton.circle(size: 40),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerSkeleton(width: 130, height: 16, borderRadius: 6),
                      SizedBox(height: 8),
                      ShimmerSkeleton(width: 90, height: 12, borderRadius: 4),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerSkeleton(width: 110, height: 14, borderRadius: 6),
                  ShimmerSkeleton(width: 80, height: 28, borderRadius: 14),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder for Discovery profile card.
class DiscoveryCardSkeleton extends StatelessWidget {
  const DiscoveryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.surfaceElevated.withValues(alpha: 0.6),
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerSkeleton.circle(size: 64),
                SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerSkeleton(width: 140, height: 20, borderRadius: 6),
                    SizedBox(height: 10),
                    ShimmerSkeleton(width: 80, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
            SizedBox(height: 28),
            ShimmerSkeleton(width: double.infinity, height: 16, borderRadius: 6),
            SizedBox(height: 10),
            ShimmerSkeleton(width: 200, height: 16, borderRadius: 6),
            SizedBox(height: 24),
            Row(
              children: [
                ShimmerSkeleton(width: 90, height: 28, borderRadius: 14),
                SizedBox(width: 10),
                ShimmerSkeleton(width: 110, height: 28, borderRadius: 14),
              ],
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ShimmerSkeleton.circle(size: 54),
                ShimmerSkeleton.circle(size: 62),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for Connections list.
class ConnectionsSkeletonList extends StatelessWidget {
  const ConnectionsSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 4,
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              ShimmerSkeleton.circle(size: 48),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerSkeleton(width: 120, height: 16, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerSkeleton(
                        width: double.infinity, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder for chat message bubbles.
class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Align(
          alignment: Alignment.centerLeft,
          child: ShimmerSkeleton(width: 220, height: 60, borderRadius: 18),
        ),
        SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: ShimmerSkeleton(width: 180, height: 44, borderRadius: 18),
        ),
        SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: ShimmerSkeleton(width: 260, height: 74, borderRadius: 18),
        ),
      ],
    );
  }
}
