import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/platform_adaptive.dart';
import '../../../core/widgets/adaptive_loading.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(ownProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          profileAsync.whenData((_) => const SizedBox.shrink()).value ??
              const SizedBox.shrink(),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: AdaptiveLoadingIndicator()),
        error: (e, _) => const Center(
          child: Text(
            'Could not load profile.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  final ProfileData profile;

  const _ProfileBody({required this.profile});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  late ProfileData _profile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _save() async {
    AppHaptics.light();
    setState(() => _isSaving = true);
    await ref.read(profileControllerProvider).updateProfile(_profile);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showAdaptiveConfirmationDialog(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out? You can return anytime.',
      confirmText: 'Sign Out',
      cancelText: 'Stay',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(profileControllerProvider).signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        // ── Avatar + Alias ──────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.biscuit.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 44,
                  color: AppColors.sage,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _profile.alias,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_profile.city != null || _profile.country != null) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    _profile.city,
                    _profile.country,
                  ].where((s) => s != null && s.isNotEmpty).join(', '),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Settings Sections ───────────────────────────────────────────────
        _SectionHeader('Energy & Availability'),
        const SizedBox(height: 10),

        _SettingCard(
          child: Column(
            children: [
              _PickerRow(
                label: 'Battery Status',
                subtitle: 'How much social energy do you have?',
                icon: Icons.battery_4_bar_outlined,
                child: _BatteryPicker(
                  value: _profile.batteryStatus,
                  onChanged: (v) {
                    if (v != null) {
                      setState(
                        () => _profile = _profile.copyWith(batteryStatus: v),
                      );
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              _PickerRow(
                label: 'Reply Pace',
                subtitle: 'How quickly do you typically respond?',
                icon: Icons.schedule_outlined,
                child: _ReplyPacePicker(
                  value: _profile.replyPace,
                  onChanged: (v) {
                    if (v != null) {
                      setState(
                        () => _profile = _profile.copyWith(replyPace: v),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _SectionHeader('Discovery'),
        const SizedBox(height: 10),

        _SettingCard(
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            secondary: const Icon(
              Icons.visibility_outlined,
              color: AppColors.sage,
            ),
            title: const Text(
              'Show me in Discovery',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Others can send you connection requests',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: _profile.isDiscoverable,
            activeThumbColor: AppColors.biscuit,
            onChanged: (v) =>
                setState(() => _profile = _profile.copyWith(isDiscoverable: v)),
          ),
        ),

        if (_profile.circles.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader('Interest Circles'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _profile.circles.map((circle) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.biscuit.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  circle,
                  style: const TextStyle(
                    color: AppColors.biscuit,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        if (_profile.sparkPrompt != null && _profile.sparkAnswer != null) ...[
          const SizedBox(height: 20),
          _SectionHeader('Spark'),
          const SizedBox(height: 10),
          _SettingCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile.sparkPrompt!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _profile.sparkAnswer!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 28),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.biscuit,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const AdaptiveLoadingIndicator(
                    size: 20,
                    strokeWidth: 2,
                    color: AppColors.background,
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
          ),
        ),

        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.terracotta,
              side: const BorderSide(color: AppColors.terracotta),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: _confirmSignOut,
          ),
        ),
        const SizedBox(height: 12),

        // App version note
        Center(
          child: Text(
            'So-Lowkey · v1.0.0',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _PickerRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.sage, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          child,
        ],
      ),
    );
  }
}

class _BatteryPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String?>? onChanged;

  const _BatteryPicker({required this.value, this.onChanged});

  static const _options = [
    ('recharging', 'Recharging'),
    ('low', 'Low'),
    ('medium', 'Medium'),
    ('full', 'Full'),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: AppColors.surfaceElevated,
      underline: const SizedBox.shrink(),
      style: const TextStyle(color: AppColors.biscuit, fontSize: 13),
      items: _options.map((opt) {
        return DropdownMenuItem(value: opt.$1, child: Text(opt.$2));
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _ReplyPacePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String?>? onChanged;

  const _ReplyPacePicker({required this.value, this.onChanged});

  static const _options = [
    ('slow_mail', 'Slow mail'),
    ('few_days', 'Few days'),
    ('same_day', 'Same day'),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: AppColors.surfaceElevated,
      underline: const SizedBox.shrink(),
      style: const TextStyle(color: AppColors.biscuit, fontSize: 13),
      items: _options.map((opt) {
        return DropdownMenuItem(value: opt.$1, child: Text(opt.$2));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
