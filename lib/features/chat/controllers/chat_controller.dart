import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/mock/mock_data.dart';
import '../models/message_model.dart';

/// In-memory state for offline dev testing
class DevMessagesNotifier extends StateNotifier<List<MessageModel>> {
  DevMessagesNotifier() : super(List.from(initialMockMessages));

  void addMessage({
    required String connectionId,
    required String content,
    bool isGracefulExit = false,
  }) {
    final newMsg = MessageModel(
      id: 'mock_msg_${DateTime.now().millisecondsSinceEpoch}',
      connectionId: connectionId,
      senderId: mockUserId,
      content: content,
      isGracefulExit: isGracefulExit,
      createdAt: DateTime.now(),
    );
    state = [...state, newMsg];
  }
}

final devMessagesNotifierProvider =
    StateNotifierProvider<DevMessagesNotifier, List<MessageModel>>((ref) {
      return DevMessagesNotifier();
    });

/// Realtime stream of messages for a given connection, ordered oldest-first.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, connectionId) {
      if (!isSupabaseConfigured) {
        final messages = ref.watch(devMessagesNotifierProvider);
        final filtered = messages
            .where((m) => m.connectionId == connectionId)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return Stream.value(filtered);
      }

      try {
        final client = Supabase.instance.client;
        return client
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('connection_id', connectionId)
            .order('created_at')
            .map((rows) => rows.map((r) => MessageModel.fromMap(r)).toList());
      } catch (_) {
        final messages = ref.watch(devMessagesNotifierProvider);
        return Stream.value(
          messages.where((m) => m.connectionId == connectionId).toList(),
        );
      }
    });

class ChatController {
  final Ref _ref;
  ChatController(this._ref);

  Future<void> sendMessage({
    required String connectionId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    if (!isSupabaseConfigured) {
      _ref
          .read(devMessagesNotifierProvider.notifier)
          .addMessage(connectionId: connectionId, content: content.trim());
      return;
    }

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('messages').insert({
        'connection_id': connectionId,
        'sender_id': userId,
        'content': content.trim(),
        'is_graceful_exit': false,
      });

      await client
          .from('connections')
          .update({'last_interaction_at': DateTime.now().toIso8601String()})
          .eq('id', connectionId);
    } catch (_) {
      _ref
          .read(devMessagesNotifierProvider.notifier)
          .addMessage(connectionId: connectionId, content: content.trim());
    }
  }
}

final chatControllerProvider = Provider<ChatController>(
  (ref) => ChatController(ref),
);
