import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/mock/mock_data.dart';
import '../models/lounge_model.dart';

final loungesProvider = FutureProvider.autoDispose<List<LoungeModel>>((
  ref,
) async {
  if (!isSupabaseConfigured) {
    return mockLounges;
  }

  try {
    final rows = await Supabase.instance.client.from('lounges').select();
    return (rows as List)
        .map((r) => LoungeModel.fromMap(r as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return mockLounges;
  }
});

/// Realtime list of who else is passively present in a lounge.
final loungePresenceProvider = StreamProvider.autoDispose
    .family<List<LoungePresenceModel>, String>((ref, loungeId) {
      if (!isSupabaseConfigured) {
        return Stream.value(mockPresences[loungeId] ?? []);
      }

      try {
        final client = Supabase.instance.client;
        return client
            .from('lounge_presences')
            .stream(primaryKey: ['user_id'])
            .eq('lounge_id', loungeId)
            .map(
              (rows) => rows.map((r) => LoungePresenceModel.fromMap(r)).toList(),
            );
      } catch (_) {
        return Stream.value(mockPresences[loungeId] ?? []);
      }
    });

/// Resolves aliases for a set of present user ids.
final loungePresenceAliasesProvider = FutureProvider.autoDispose
    .family<Map<String, String>, List<String>>((ref, userIds) async {
      if (userIds.isEmpty) return {};

      if (!isSupabaseConfigured) {
        return {
          for (final id in userIds) id: mockAliases[id] ?? 'Quiet Companion',
        };
      }

      try {
        final rows = await Supabase.instance.client
            .from('profiles')
            .select('id, alias')
            .inFilter('id', userIds);

        return {
          for (final row in rows) row['id'] as String: row['alias'] as String,
        };
      } catch (_) {
        return {
          for (final id in userIds) id: mockAliases[id] ?? 'Quiet Companion',
        };
      }
    });

class LoungeController {
  Future<void> joinLounge(
    String loungeId, {
    String statusText = 'Reading quietly',
  }) async {
    if (!isSupabaseConfigured) return;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('lounge_presences').upsert({
        'user_id': userId,
        'lounge_id': loungeId,
        'status_text': statusText,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> leaveLounge() async {
    if (!isSupabaseConfigured) return;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('lounge_presences').delete().eq('user_id', userId);
    } catch (_) {}
  }

  Future<void> updateStatusText(String statusText) async {
    if (!isSupabaseConfigured) return;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client
          .from('lounge_presences')
          .update({'status_text': statusText})
          .eq('user_id', userId);
    } catch (_) {}
  }
}

final loungeControllerProvider = Provider<LoungeController>(
  (ref) => LoungeController(),
);
