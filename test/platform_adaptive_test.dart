import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solokey/core/utils/platform_adaptive.dart';
import 'package:solokey/core/widgets/adaptive_loading.dart';
import 'package:solokey/core/widgets/app_splash_screen.dart';

void main() {
  group('Platform Adaptive Widgets & Helpers Tests', () {
    testWidgets('AdaptiveLoadingIndicator renders appropriately', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: AdaptiveLoadingIndicator(size: 24)),
          ),
        ),
      );

      expect(find.byType(AdaptiveLoadingIndicator), findsOneWidget);
      // Under default test platform (android), it renders CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ShimmerSkeleton and Skeletons render without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ShimmerSkeleton(width: 100, height: 20),
                  ShimmerSkeleton.circle(size: 40),
                  SizedBox(height: 300, child: LoungeSkeletonList()),
                  SizedBox(height: 300, child: ConnectionsSkeletonList()),
                  SizedBox(height: 300, child: ChatMessagesSkeleton()),
                  SizedBox(height: 400, child: DiscoveryCardSkeleton()),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerSkeleton), findsWidgets);
      expect(find.byType(LoungeSkeletonList), findsOneWidget);
      expect(find.byType(ConnectionsSkeletonList), findsOneWidget);
      expect(find.byType(ChatMessagesSkeleton), findsOneWidget);
      expect(find.byType(DiscoveryCardSkeleton), findsOneWidget);

      // Verify pulse animation tick
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('AppSplashScreen renders branding and status message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppSplashScreen(statusMessage: 'Finding your quiet space...'),
        ),
      );

      expect(find.text('So-Lowkey'), findsOneWidget);
      expect(find.text('Quiet connection for introverts'), findsOneWidget);
      expect(find.text('Finding your quiet space...'), findsOneWidget);
      expect(find.byType(AdaptiveLoadingIndicator), findsOneWidget);

      // Verify breathing animation tick
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets('AdaptiveBackButton handles tap and renders back icon', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leading: AdaptiveBackButton(
                onPressed: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveBackButton), findsOneWidget);
      await tester.tap(find.byType(AdaptiveBackButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    test('buildAdaptivePageRoute instantiates CupertinoPageRoute', () {
      final route = buildAdaptivePageRoute(
        builder: (_) => const SizedBox.shrink(),
      );
      expect(route, isA<CupertinoPageRoute>());
    });

    test(
      'buildAdaptivePage instantiates CupertinoPage for edge swipe gesture',
      () {
        final page = buildAdaptivePage(child: const SizedBox.shrink());
        expect(page, isA<CupertinoPage>());
      },
    );

    testWidgets('iOS edge swipe-back gesture pops pushed detail screen', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      buildAdaptivePageRoute(
                        builder: (_) => const Scaffold(
                          body: Center(child: Text('Detail Screen')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Detail'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open detail
      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Screen'), findsOneWidget);

      // Perform iOS back gesture: drag from left edge (x=5) across screen
      final gesture = await tester.startGesture(const Offset(5, 300));
      for (int i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(60, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // Verified: detail popped and we are back on root screen!
      expect(find.text('Open Detail'), findsOneWidget);
      expect(find.text('Detail Screen'), findsNothing);

      debugDefaultTargetPlatformOverride = null;
    });

    test('Platform detection flags report correct mobile platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(isIOSPlatform, isTrue);
      expect(isAndroidPlatform, isFalse);
      expect(isApplePlatform, isTrue);
      expect(isMobilePlatform, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(isIOSPlatform, isFalse);
      expect(isAndroidPlatform, isTrue);
      expect(isApplePlatform, isFalse);
      expect(isMobilePlatform, isTrue);

      debugDefaultTargetPlatformOverride = null;
    });

    test('AppHaptics methods trigger without throwing errors', () {
      expect(() => AppHaptics.light(), returnsNormally);
      expect(() => AppHaptics.medium(), returnsNormally);
      expect(() => AppHaptics.heavy(), returnsNormally);
      expect(() => AppHaptics.selection(), returnsNormally);
    });
  });
}
