import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/utils/platform_adaptive.dart';
import '../controllers/chat_controller.dart';

class GracefulExitDialog extends ConsumerWidget {
  final String connectionId;
  const GracefulExitDialog({super.key, required this.connectionId});

  static const List<String> exitOptions = [
    "Heading off to recharge my battery—thank you for the quiet company!",
    "Stepping away from chats for a while to focus on solitary projects.",
    "My social energy is currently depleted. Wishing you the best!",
  ];

  static Future<void> showAdaptive(
    BuildContext context,
    WidgetRef ref,
    String connectionId,
  ) async {
    if (isApplePlatform) {
      await showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Graceful Exit'),
          message: const Text(
            'Leave this conversation without ghosting anxiety. Choose a calm departure message:',
          ),
          actions: exitOptions.map((opt) {
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _performExit(context, ref, connectionId, opt);
              },
              child: Text(
                opt,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.biscuit),
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => GracefulExitDialog(connectionId: connectionId),
    );
  }

  static Future<void> _performExit(
    BuildContext context,
    WidgetRef ref,
    String connectionId,
    String reason,
  ) async {
    AppHaptics.medium();
    if (!isSupabaseConfigured) {
      ref
          .read(devMessagesNotifierProvider.notifier)
          .addMessage(
            connectionId: connectionId,
            content: reason,
            isGracefulExit: true,
          );
      if (context.mounted) {
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
      }
    } catch (_) {
      // Ignore network errors gracefully
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
                onTap: () {
                  Navigator.of(context).pop();
                  _performExit(context, ref, connectionId, opt);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.surface),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    opt,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
