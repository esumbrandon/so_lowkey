import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/mock/mock_data.dart';
import '../models/connection_model.dart';

/// Streams all connections for the current user.
/// In offline dev mode returns the [mockConnections] list as a single-value stream.
final connectionsProvider =
    StreamProvider.autoDispose<List<ConnectionModel>>((ref) {
  if (!isSupabaseConfigured) {
    return Stream.value(List.from(mockConnections));
  }

  try {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    // Stream connections where I am the initiator or recipient,
    // ordered by most recent interaction first.
    return client
        .from('connections')
        .stream(primaryKey: ['id'])
        .order('last_interaction_at', ascending: false)
        .map((rows) {
          final all = (rows as List)
              .where((r) =>
                  r['initiator_id'] == userId || r['recipient_id'] == userId)
              .toList();

          return _resolveConnections(all, userId, client);
        })
        .asyncMap((future) => future);
  } catch (_) {
    return Stream.value(List.from(mockConnections));
  }
});

/// Resolves raw connection rows into [ConnectionModel]s by fetching peer profiles.
Future<List<ConnectionModel>> _resolveConnections(
  List<dynamic> rows,
  String myId,
  SupabaseClient client,
) async {
  if (rows.isEmpty) return [];

  // Collect all peer IDs we need to look up.
  final peerIds = <String>{};
  for (final row in rows) {
    final isInitiator = row['initiator_id'] == myId;
    peerIds.add(
      isInitiator ? row['recipient_id'] as String : row['initiator_id'] as String,
    );
  }

  // Batch fetch peer profiles.
  final profileRows = await client
      .from('profiles')
      .select('id, alias, battery_status, reply_pace')
      .inFilter('id', peerIds.toList());

  final profileMap = <String, Map<String, dynamic>>{};
  for (final p in profileRows as List) {
    profileMap[p['id'] as String] = Map<String, dynamic>.from(p as Map);
  }

  return rows.map((row) {
    final r = Map<String, dynamic>.from(row as Map);
    final isInitiator = r['initiator_id'] == myId;
    final peerId = isInitiator
        ? r['recipient_id'] as String
        : r['initiator_id'] as String;
    final peer = profileMap[peerId] ?? {};

    r['initiator_profile'] = isInitiator ? {} : peer;
    r['recipient_profile'] = isInitiator ? peer : {};

    return ConnectionModel.fromMap(r, myId: myId);
  }).toList();
}

// ── Dev-mode notifier that simulates accept/decline ─────────────────────────

class DevConnectionsNotifier extends StateNotifier<List<ConnectionModel>> {
  DevConnectionsNotifier() : super(List.from(mockConnections));

  void accept(String connectionId) {
    state = state.map((c) {
      if (c.id != connectionId) return c;
      return ConnectionModel(
        id: c.id,
        initiatorId: c.initiatorId,
        recipientId: c.recipientId,
        status: 'active',
        lastInteractionAt: DateTime.now(),
        createdAt: c.createdAt,
        peerAlias: c.peerAlias,
        peerBatteryStatus: c.peerBatteryStatus,
        peerReplyPace: c.peerReplyPace,
        lastMessageContent:
            'Your connection request was accepted. Start the conversation!',
        lastMessageAt: DateTime.now(),
      );
    }).toList();
  }

  void decline(String connectionId) {
    state = state.where((c) => c.id != connectionId).toList();
  }
}

final devConnectionsNotifierProvider = StateNotifierProvider<
    DevConnectionsNotifier, List<ConnectionModel>>(
  (ref) => DevConnectionsNotifier(),
);

// ── Connections controller ────────────────────────────────────────────────────

class ConnectionsController {
  final Ref _ref;
  ConnectionsController(this._ref);

  /// Accept a pending connection request, promoting it to 'active'.
  Future<void> accept(String connectionId) async {
    if (!isSupabaseConfigured) {
      _ref.read(devConnectionsNotifierProvider.notifier).accept(connectionId);
      return;
    }

    try {
      final client = Supabase.instance.client;
      await client.from('connections').update({
        'status': 'active',
        'last_interaction_at': DateTime.now().toIso8601String(),
      }).eq('id', connectionId);
    } catch (_) {}
  }

  /// Decline / remove a pending connection request.
  Future<void> decline(String connectionId) async {
    if (!isSupabaseConfigured) {
      _ref.read(devConnectionsNotifierProvider.notifier).decline(connectionId);
      return;
    }

    try {
      final client = Supabase.instance.client;
      await client
          .from('connections')
          .delete()
          .eq('id', connectionId);
    } catch (_) {}
  }
}

final connectionsControllerProvider = Provider<ConnectionsController>(
  (ref) => ConnectionsController(ref),
);
