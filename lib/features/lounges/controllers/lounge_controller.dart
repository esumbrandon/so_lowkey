import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lounge_model.dart';

final loungesProvider = FutureProvider.autoDispose<List<LoungeModel>>((
  ref,
) async {
  final rows = await Supabase.instance.client.from('lounges').select();
  return (rows as List)
      .map((r) => LoungeModel.fromMap(r as Map<String, dynamic>))
      .toList();
});

/// Realtime list of who else is passively present in a lounge.
final loungePresenceProvider = StreamProvider.autoDispose
    .family<List<LoungePresenceModel>, String>((ref, loungeId) {
      final client = Supabase.instance.client;

      return client
          .from('lounge_presences')
          .stream(primaryKey: ['user_id'])
          .eq('lounge_id', loungeId)
          .map(
            (rows) => rows.map((r) => LoungePresenceModel.fromMap(r)).toList(),
          );
    });

/// Resolves aliases for a set of present user ids. `.stream()` queries can't
/// join, so presence and profile data are fetched separately and merged here.
final loungePresenceAliasesProvider = FutureProvider.autoDispose
    .family<Map<String, String>, List<String>>((ref, userIds) async {
      if (userIds.isEmpty) return {};

      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id, alias')
          .inFilter('id', userIds);

      return {
        for (final row in rows) row['id'] as String: row['alias'] as String,
      };
    });

class LoungeController {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> joinLounge(
    String loungeId, {
    String statusText = 'Reading quietly',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('lounge_presences').upsert({
      'user_id': userId,
      'lounge_id': loungeId,
      'status_text': statusText,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> leaveLounge() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('lounge_presences').delete().eq('user_id', userId);
  }

  Future<void> updateStatusText(String statusText) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('lounge_presences')
        .update({'status_text': statusText})
        .eq('user_id', userId);
  }
}

final loungeControllerProvider = Provider<LoungeController>(
  (ref) => LoungeController(),
);
