import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../utils/platform_adaptive.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _tabs = [
    _TabItem(
      label: 'Lounges',
      icon: Icons.forest_outlined,
      activeIcon: Icons.forest,
    ),
    _TabItem(
      label: 'Discover',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
    ),
    _TabItem(
      label: 'Connections',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
    ),
    _TabItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hideController;
  late final Animation<Offset> _slideAnim;

  // Track scroll direction
  double _lastScrollPosition = 0;
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;

  // How many pixels the user must scroll before we react
  static const double _kScrollDeltaThreshold = 6.0;

  @override
  void initState() {
    super.initState();
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    // Slides down by 1.5× its own height (clears the safe area + shadow)
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1.5))
        .animate(
          CurvedAnimation(parent: _hideController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _hideController.dispose();
    super.dispose();
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false; // only top-level scroll

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      final position = notification.metrics.pixels;

      // Always reveal when at or near the very top
      if (position <= _kScrollDeltaThreshold) {
        _show();
        _lastScrollPosition = position;
        return false;
      }

      final scrolledEnough =
          (position - _lastScrollPosition).abs() > _kScrollDeltaThreshold;

      if (scrolledEnough) {
        final direction = delta > 0
            ? ScrollDirection
                  .forward // scrolling down → content moves up
            : ScrollDirection.reverse; // scrolling up  → content moves down

        if (direction != _lastScrollDirection) {
          _lastScrollDirection = direction;
          if (direction == ScrollDirection.forward) {
            _hide();
          } else {
            _show();
          }
        }
        _lastScrollPosition = position;
      }
    }

    if (notification is ScrollEndNotification) {
      // Snap back if we ended near the top
      if (notification.metrics.pixels <= _kScrollDeltaThreshold) {
        _show();
      }
    }

    return false;
  }

  void _show() {
    if (_hideController.value != 0) {
      _hideController.reverse();
    }
  }

  void _hide() {
    if (_hideController.value != 1) {
      _hideController.forward();
    }
  }

  void _onTabTapped(int index) {
    // Platform haptics
    AppHaptics.selection();

    // Always reveal bar on any tab tap
    _show();
    _lastScrollDirection = ScrollDirection.idle;

    widget.navigationShell.goBranch(
      index,
      // Re-tap active tab → pop to root of that branch (scroll-to-top effect)
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.sizeOf(context).width >= 768;
    final currentIndex = widget.navigationShell.currentIndex;

    // Platform Best Practice: On Android, pressing back on secondary tabs returns to home
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onTabTapped(0);
      },
      child: Scaffold(
        extendBody: !isWideScreen,
        body: isWideScreen
            ? Row(
                children: [
                  _SideNavRail(currentIndex: currentIndex, onTap: _onTabTapped),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.surfaceElevated,
                  ),
                  Expanded(child: widget.navigationShell),
                ],
              )
            : NotificationListener<ScrollNotification>(
                onNotification: _handleScroll,
                child: widget.navigationShell,
              ),
        bottomNavigationBar: isWideScreen
            ? null
            : SlideTransition(
                position: _slideAnim,
                child: _FloatingNavBar(
                  currentIndex: currentIndex,
                  onTap: _onTabTapped,
                ),
              ),
      ),
    );
  }
}

// ── Tablet / Large Screen Side Navigation Rail ──────────────────────────────

class _SideNavRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SideNavRail({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Calm brand logo badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
                border: Border.all(
                  color: AppColors.biscuit.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.spa_rounded,
                  color: AppColors.biscuit,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 36),
            // Nav Items
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: MainShell._tabs.length,
                separatorBuilder: (context, _) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final tab = MainShell._tabs[index];
                  final isSelected = currentIndex == index;

                  return _SideNavItemRail(
                    tab: tab,
                    isSelected: isSelected,
                    onTap: () => onTap(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItemRail extends StatefulWidget {
  final _TabItem tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavItemRail({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SideNavItemRail> createState() => _SideNavItemRailState();
}

class _SideNavItemRailState extends State<_SideNavItemRail> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tab.label,
        waitDuration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 64,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceElevated
                  : _isHovered
                  ? AppColors.surface.withValues(alpha: 0.7)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.biscuit.withValues(alpha: 0.35)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isSelected ? widget.tab.activeIcon : widget.tab.icon,
                  color: widget.isSelected
                      ? AppColors.biscuit
                      : _isHovered
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tab.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: widget.isSelected
                        ? AppColors.biscuit
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mobile Floating Nav Bar ──────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPadding > 0 ? bottomPadding + 6 : 18,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.10),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: List.generate(
                MainShell._tabs.length,
                (i) => Expanded(
                  child: _NavItem(
                    tab: MainShell._tabs[i],
                    isSelected: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Individual Mobile Nav Item ───────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _TabItem tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: isSelected
                ? Icon(
                    tab.activeIcon,
                    key: ValueKey('${tab.label}_on'),
                    color: AppColors.biscuit,
                    size: 26,
                  )
                : Icon(
                    tab.icon,
                    key: ValueKey('${tab.label}_off'),
                    color: AppColors.textMuted,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
