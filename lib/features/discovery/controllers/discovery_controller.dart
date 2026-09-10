import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/mock/mock_data.dart';
import '../models/profile_model.dart';

/// Fetches discoverable profiles, excluding the current user and anyone
/// already connected to them.
final discoveryProvider = FutureProvider.autoDispose<List<ProfileModel>>((
  ref,
) async {
  if (!isSupabaseConfigured) {
    return mockProfiles;
  }

  try {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return mockProfiles;

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
  } catch (_) {
    return mockProfiles;
  }
});

class DiscoveryController {
  /// Sends a connection request.
  Future<void> sendConnectionRequest(String recipientId) async {
    if (!isSupabaseConfigured) {
      // Simulate successful request in offline dev mode
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('connections').insert({
        'initiator_id': userId,
        'recipient_id': recipientId,
        'status': 'pending',
      });
    } catch (_) {}
  }

  /// Accepts a pending connection request, moving it to 'active'.
  Future<void> acceptConnection(String connectionId) async {
    if (!isSupabaseConfigured) return;

    try {
      final client = Supabase.instance.client;
      await client
          .from('connections')
          .update({
            'status': 'active',
            'last_interaction_at': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId);
    } catch (_) {}
  }
}

final discoveryControllerProvider = Provider<DiscoveryController>(
  (ref) => DiscoveryController(),
);
