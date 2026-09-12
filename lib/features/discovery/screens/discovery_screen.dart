import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/widgets/app_nav_menu.dart';
import '../controllers/discovery_controller.dart';
import '../models/profile_model.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  static const _batteryIcons = {
    'recharging': Icons.battery_alert,
    'low': Icons.battery_2_bar,
    'medium': Icons.battery_4_bar,
    'full': Icons.battery_full,
  };

  Future<void> _connect(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
  ) async {
    final controller = ref.read(discoveryControllerProvider);
    try {
      await controller.sendConnectionRequest(profile.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent a quiet hello to ${profile.alias}.'),
            action: SnackBarAction(
              label: 'Open Chat',
              textColor: AppColors.biscuit,
              onPressed: () {
                context.go('/chat/demo_chat_${profile.id}?alias=${profile.alias}');
              },
            ),
          ),
        );
        final filter = ref.read(discoveryFilterProvider);
        ref.invalidate(discoveryProvider(filter));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send that request. Try again later.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(discoveryFilterProvider);
    final profilesAsync = ref.watch(discoveryProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Nerds'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: 'Dev Screen Switcher',
            onPressed: () => showAppNavigationModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.forest_outlined),
            tooltip: 'Lounges',
            onPressed: () => context.go('/lounges'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Bar ────────────────────────────────────────────────
          _FilterBar(filter: filter),
          // ── Profile List ──────────────────────────────────────────────
          Expanded(
            child: profilesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.biscuit),
              ),
              error: (err, st) => const Center(
                child: Text(
                  'Something went quiet. Pull to try again.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              data: (profiles) {
                if (profiles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            filter.isEmpty
                                ? 'No new quiet corners to discover right now. Check back soon.'
                                : 'No nerds match that filter yet. Try broadening your search.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          if (!filter.isEmpty) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              icon: const Icon(Icons.clear_all,
                                  color: AppColors.biscuit),
                              label: const Text(
                                'Clear Filters',
                                style: TextStyle(color: AppColors.biscuit),
                              ),
                              onPressed: () {
                                ref
                                    .read(discoveryFilterProvider.notifier)
                                    .state = const DiscoveryFilter();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.biscuit,
                  onRefresh: () async {
                    ref.invalidate(discoveryProvider(filter));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      return _ProfileCard(
                        profile: profile,
                        onConnect: () => _connect(context, ref, profile),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Filter Bar
// ────────────────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final DiscoveryFilter filter;
  const _FilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surface, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Country filter chip
            _FilterChipButton(
              icon: Icons.public_outlined,
              label: filter.country ?? 'Country',
              isActive: filter.country != null,
              onTap: () => _showCountryPicker(context, ref),
              onClear: filter.country != null
                  ? () => ref.read(discoveryFilterProvider.notifier).state =
                      filter.copyWith(country: null)
                  : null,
            ),
            const SizedBox(width: 8),
            // Region filter chip
            _FilterChipButton(
              icon: Icons.location_on_outlined,
              label: filter.region ?? 'Region',
              isActive: filter.region != null,
              onTap: () => _showRegionInput(context, ref),
              onClear: filter.region != null
                  ? () => ref.read(discoveryFilterProvider.notifier).state =
                      filter.copyWith(region: null)
                  : null,
            ),
            const SizedBox(width: 8),
            // Circle filter chip
            _FilterChipButton(
              icon: Icons.interests_outlined,
              label: filter.circle ?? 'Circle',
              isActive: filter.circle != null,
              onTap: () => _showCirclePicker(context, ref),
              onClear: filter.circle != null
                  ? () => ref.read(discoveryFilterProvider.notifier).state =
                      filter.copyWith(circle: null)
                  : null,
            ),
            if (!filter.isEmpty) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  ref.read(discoveryFilterProvider.notifier).state =
                      const DiscoveryFilter();
                },
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    color: AppColors.terracotta,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Country picker ──────────────────────────────────────────────────────
  static const _popularCountries = [
    'United States', 'United Kingdom', 'Canada', 'Australia',
    'Germany', 'France', 'Japan', 'India', 'Brazil', 'Sweden',
    'Netherlands', 'Nigeria', 'South Korea', 'New Zealand', 'Spain',
  ];

  void _showCountryPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PickerSheet(
        title: 'Filter by Country',
        icon: Icons.public_outlined,
        options: _popularCountries,
        selected: filter.country,
        onSelect: (value) {
          ref.read(discoveryFilterProvider.notifier).state =
              filter.copyWith(country: value);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── Region input ────────────────────────────────────────────────────────
  void _showRegionInput(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: filter.region ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.biscuit),
                const SizedBox(width: 10),
                const Text(
                  'Filter by Region',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Pacific Northwest, Kansai, Scotland…',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  ref.read(discoveryFilterProvider.notifier).state =
                      filter.copyWith(region: value.trim());
                }
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.biscuit,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final val = controller.text.trim();
                  if (val.isNotEmpty) {
                    ref.read(discoveryFilterProvider.notifier).state =
                        filter.copyWith(region: val);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Apply Region Filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Circle picker ───────────────────────────────────────────────────────
  void _showCirclePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PickerSheet(
        title: 'Filter by Circle',
        icon: Icons.interests_outlined,
        options: kAllCircles,
        selected: filter.circle,
        onSelect: (value) {
          ref.read(discoveryFilterProvider.notifier).state =
              filter.copyWith(circle: value);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// Generic bottom-sheet picker for country/circle selection.
class _PickerSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _PickerSheet({
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.biscuit),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  color: AppColors.surface,
                ),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == selected;
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.biscuit
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.biscuit)
                        : null,
                    onTap: () => onSelect(option),
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

/// A small tappable filter chip with an optional clear (×) button.
class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.biscuit.withValues(alpha: 0.15) : AppColors.surface,
          border: Border.all(
            color: isActive ? AppColors.biscuit : AppColors.surfaceElevated,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.biscuit : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.biscuit : AppColors.textMuted,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.biscuit,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Profile Card
// ────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onConnect;

  const _ProfileCard({required this.profile, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceElevated,
                  child: Text(
                    profile.alias.isNotEmpty
                        ? profile.alias[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.biscuit,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.alias,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.replyPaceLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  DiscoveryScreen._batteryIcons[profile.batteryStatus] ??
                      Icons.battery_4_bar,
                  color: AppColors.sage,
                ),
              ],
            ),
            // ── Location & Circles badges ─────────────────────────────
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (profile.locationLabel != null)
                  _Badge(
                    icon: Icons.location_on_outlined,
                    label: profile.locationLabel!,
                    color: AppColors.duskLavender,
                  ),
                ...profile.circles.map(
                  (c) => _Badge(
                    icon: Icons.circle,
                    label: c,
                    color: AppColors.sage,
                    iconSize: 8,
                  ),
                ),
              ],
            ),
            // ── Spark prompt ──────────────────────────────────────────
            if (profile.sparkPrompt != null && profile.sparkAnswer != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.sparkPrompt!,
                      style: const TextStyle(
                        color: AppColors.biscuit,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.sparkAnswer!,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.waving_hand_outlined, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.biscuit,
                  side: const BorderSide(color: AppColors.biscuit),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onConnect,
                label: const Text('Send a Quiet Hello'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill badge for location / circle tags.
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
