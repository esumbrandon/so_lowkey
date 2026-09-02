import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

/// Realtime stream of messages for a given connection, ordered oldest-first.
/// So-Lowkey is strictly asynchronous: no typing indicators, no read markers —
/// this stream only ever reflects persisted messages.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, connectionId) {
      final client = Supabase.instance.client;

      return client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('connection_id', connectionId)
          .order('created_at')
          .map((rows) => rows.map((r) => MessageModel.fromMap(r)).toList());
    });

class ChatController {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> sendMessage({
    required String connectionId,
    required String content,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');
    if (content.trim().isEmpty) return;

    await _client.from('messages').insert({
      'connection_id': connectionId,
      'sender_id': userId,
      'content': content.trim(),
      'is_graceful_exit': false,
    });

    await _client
        .from('connections')
        .update({'last_interaction_at': DateTime.now().toIso8601String()})
        .eq('id', connectionId);
  }
}

final chatControllerProvider = Provider<ChatController>(
  (ref) => ChatController(),
);
