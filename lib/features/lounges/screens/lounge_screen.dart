import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/ambient_audio_controller.dart';
import '../controllers/lounge_controller.dart';
import '../models/lounge_model.dart';

const _loungeIcons = {
  'book': Icons.menu_book_outlined,
  'coffee': Icons.coffee_outlined,
  'rain': Icons.water_drop_outlined,
  'plant': Icons.local_florist_outlined,
  'stars': Icons.nightlight_round,
  'default': Icons.forest_outlined,
};

class LoungeScreen extends ConsumerWidget {
  const LoungeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loungesAsync = ref.watch(loungesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Lounges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'Discover people',
            onPressed: () => context.go('/discovery'),
          ),
        ],
      ),
      body: loungesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.biscuit),
        ),
        error: (err, st) => const Center(
          child: Text(
            'Could not load lounges.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        data: (lounges) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lounges.length,
          itemBuilder: (context, index) {
            final lounge = lounges[index];
            return _LoungeTile(lounge: lounge);
          },
        ),
      ),
    );
  }
}

class _LoungeTile extends StatelessWidget {
  final LoungeModel lounge;
  const _LoungeTile({required this.lounge});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceElevated,
          child: Icon(
            _loungeIcons[lounge.iconName] ?? _loungeIcons['default'],
            color: AppColors.sage,
          ),
        ),
        title: Text(
          lounge.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: lounge.description != null
            ? Text(
                lounge.description!,
                style: const TextStyle(color: AppColors.textMuted),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LoungeRoomScreen(lounge: lounge)),
        ),
      ),
    );
  }
}

/// The "inside" view of a lounge: ambient audio + a passive list of who
/// else is quietly present. No chat here — this is parallel play, not talk.
class LoungeRoomScreen extends ConsumerStatefulWidget {
  final LoungeModel lounge;
  const LoungeRoomScreen({super.key, required this.lounge});

  @override
  ConsumerState<LoungeRoomScreen> createState() => _LoungeRoomScreenState();
}

class _LoungeRoomScreenState extends ConsumerState<LoungeRoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loungeControllerProvider).joinLounge(widget.lounge.id);
      ref
          .read(ambientAudioProvider.notifier)
          .playLoungeTrack(widget.lounge.ambientAudioUrl);
    });
  }

  @override
  void dispose() {
    ref.read(loungeControllerProvider).leaveLounge();
    ref.read(ambientAudioProvider.notifier).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presenceAsync = ref.watch(loungePresenceProvider(widget.lounge.id));
    final audioState = ref.watch(ambientAudioProvider);
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.lounge.name),
        actions: [
          IconButton(
            icon: Icon(
              audioState.value == true
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              color: AppColors.biscuit,
            ),
            onPressed: () =>
                ref.read(ambientAudioProvider.notifier).togglePlayPause(),
          ),
        ],
      ),
      body: presenceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.biscuit),
        ),
        error: (err, st) => const Center(
          child: Text(
            'Could not load who is here.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        data: (presences) {
          final others = presences.where((p) => p.userId != myId).toList();
          final aliasesAsync = ref.watch(
            loungePresenceAliasesProvider(others.map((p) => p.userId).toList()),
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${others.length} other${others.length == 1 ? '' : 's'} quietly here with you',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: aliasesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.biscuit,
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (aliases) => others.isEmpty
                        ? const Center(
                            child: Text(
                              'It\'s just you for now. Enjoy the quiet.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            itemCount: others.length,
                            itemBuilder: (context, index) {
                              final presence = others[index];
                              final alias =
                                  aliases[presence.userId] ?? 'Someone nearby';
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.surfaceElevated,
                                  child: Icon(
                                    Icons.person_outline,
                                    color: AppColors.sage,
                                  ),
                                ),
                                title: Text(alias),
                                subtitle: Text(
                                  presence.statusText,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
