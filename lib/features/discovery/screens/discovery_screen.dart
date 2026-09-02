import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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
          SnackBar(content: Text('Sent a quiet hello to ${profile.alias}.')),
        );
        ref.invalidate(discoveryProvider);
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
    final profilesAsync = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.forest_outlined),
            tooltip: 'Lounges',
            onPressed: () => context.go('/lounges'),
          ),
        ],
      ),
      body: profilesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.biscuit),
        ),
        error: (err, st) => Center(
          child: Text(
            'Something went quiet. Pull to try again.',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No new quiet corners to discover right now. Check back soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(discoveryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
    );
  }
}

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
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.biscuit,
                  side: const BorderSide(color: AppColors.biscuit),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onConnect,
                child: const Text('Send a Quiet Hello'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
