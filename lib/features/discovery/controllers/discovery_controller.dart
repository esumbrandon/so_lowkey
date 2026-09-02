import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

/// Fetches discoverable profiles, excluding the current user and anyone
/// already connected (pending, active, or gracefully closed) to them.
final discoveryProvider = FutureProvider.autoDispose<List<ProfileModel>>((
  ref,
) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final existingConnections = await client
      .from('connections')
      .select('initiator_id, recipient_id')
      .or('initiator_id.eq.$userId,recipient_id.eq.$userId');

  final excludedIds = <String>{userId};
  for (final row in existingConnections) {
    excludedIds.add(row['initiator_id'] as String);
    excludedIds.add(row['recipient_id'] as String);
  }

  final profiles = await client
      .from('profiles')
      .select()
      .eq('is_discoverable', true)
      .not('id', 'in', '(${excludedIds.join(',')})')
      .limit(30);

  return (profiles as List)
      .map((p) => ProfileModel.fromMap(p as Map<String, dynamic>))
      .toList();
});

class DiscoveryController {
  final SupabaseClient _client = Supabase.instance.client;

  /// Sends a connection request. Stays 'pending' until the recipient accepts.
  Future<void> sendConnectionRequest(String recipientId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    await _client.from('connections').insert({
      'initiator_id': userId,
      'recipient_id': recipientId,
      'status': 'pending',
    });
  }

  /// Accepts a pending connection request, moving it to 'active'.
  /// This is where the DB trigger enforces the recipient's max_active_chats.
  Future<void> acceptConnection(String connectionId) async {
    await _client
        .from('connections')
        .update({
          'status': 'active',
          'last_interaction_at': DateTime.now().toIso8601String(),
        })
        .eq('id', connectionId);
  }
}

final discoveryControllerProvider = Provider<DiscoveryController>(
  (ref) => DiscoveryController(),
);
