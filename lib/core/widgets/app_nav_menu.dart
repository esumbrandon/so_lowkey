import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

void showAppNavigationModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore_outlined, color: AppColors.biscuit),
                  const SizedBox(width: 10),
                  const Text(
                    'Navigate Screens (Dev Mode)',
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
              const SizedBox(height: 12),
              _NavTile(
                icon: Icons.forest_outlined,
                title: 'Lounges (Parallel Play)',
                subtitle: 'Ambient audio rooms and presence',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/lounges');
                },
              ),
              _NavTile(
                icon: Icons.people_outline,
                title: 'Discovery',
                subtitle: 'Find quiet companions with matching energy',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/discovery');
                },
              ),
              _NavTile(
                icon: Icons.chat_bubble_outline,
                title: 'Active Chat (Demo)',
                subtitle: 'Async chat with Rowan Moss & graceful exit',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/chat/demo_chat_rowan?alias=Rowan Moss');
                },
              ),
              _NavTile(
                icon: Icons.person_add_outlined,
                title: 'Onboarding Flow',
                subtitle: 'Introvert profile & prompt setup wizard',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/onboarding');
                },
              ),
              _NavTile(
                icon: Icons.lock_outline,
                title: 'Login Screen',
                subtitle: 'Authentication and sign-in landing screen',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.biscuit, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
