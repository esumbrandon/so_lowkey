import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_data.dart';
import '../controllers/chat_controller.dart';

class GracefulExitDialog extends ConsumerWidget {
  final String connectionId;
  const GracefulExitDialog({super.key, required this.connectionId});

  static const List<String> exitOptions = [
    "Heading off to recharge my battery—thank you for the quiet company!",
    "Stepping away from chats for a while to focus on solitary projects.",
    "My social energy is currently depleted. Wishing you the best!",
  ];

  Future<void> _executeExit(BuildContext context, WidgetRef ref, String reason) async {
    if (!isSupabaseConfigured) {
      ref.read(devMessagesNotifierProvider.notifier).addMessage(
        connectionId: connectionId,
        content: reason,
        isGracefulExit: true,
      );
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gracefully exited conversation.')),
        );
      }
      return;
    }

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Post graceful closing system message
      await client.from('messages').insert({
        'connection_id': connectionId,
        'sender_id': userId,
        'content': reason,
        'is_graceful_exit': true,
      });

      // 2. Mark connection as gracefully closed
      await client
          .from('connections')
          .update({
            'status': 'gracefully_closed',
            'closed_reason': reason,
            'closed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId);

      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Graceful Exit',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leave this conversation without ghosting anxiety. Choose a calm, pre-composed departure message:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...exitOptions.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _executeExit(context, ref, opt),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.surface),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    opt,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
