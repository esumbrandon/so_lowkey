import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/mock/mock_data.dart';
import '../models/profile_model.dart';

/// Describes how to filter the discovery feed.
/// All fields are optional — null means "no filter applied".
class DiscoveryFilter {
  final String? country;
  final String? region;
  final String? circle;

  const DiscoveryFilter({this.country, this.region, this.circle});

  bool get isEmpty => country == null && region == null && circle == null;

  DiscoveryFilter copyWith({
    Object? country = _sentinel,
    Object? region = _sentinel,
    Object? circle = _sentinel,
  }) {
    return DiscoveryFilter(
      country: country == _sentinel ? this.country : country as String?,
      region: region == _sentinel ? this.region : region as String?,
      circle: circle == _sentinel ? this.circle : circle as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryFilter &&
          country == other.country &&
          region == other.region &&
          circle == other.circle;

  @override
  int get hashCode => Object.hash(country, region, circle);
}

// Sentinel value for copyWith to distinguish null-passing from "no change".
const Object _sentinel = Object();

/// Holds the currently active filter — stored in a StateProvider so the UI
/// can update it and the [discoveryProvider] will automatically refresh.
final discoveryFilterProvider =
    StateProvider<DiscoveryFilter>((ref) => const DiscoveryFilter());

/// Fetches discoverable profiles, excluding the current user and anyone
/// already connected to them. Filtered by [DiscoveryFilter].
final discoveryProvider =
    FutureProvider.autoDispose.family<List<ProfileModel>, DiscoveryFilter>((
  ref,
  filter,
) async {
  if (!isSupabaseConfigured) {
    return _applyFilterToMock(mockProfiles, filter);
  }

  try {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return _applyFilterToMock(mockProfiles, filter);

    final existingConnections = await client
        .from('connections')
        .select('initiator_id, recipient_id')
        .or('initiator_id.eq.$userId,recipient_id.eq.$userId');

    final excludedIds = <String>{userId};
    for (final row in existingConnections) {
      excludedIds.add(row['initiator_id'] as String);
      excludedIds.add(row['recipient_id'] as String);
    }

    var query = client
        .from('profiles')
        .select()
        .eq('is_discoverable', true)
        .not('id', 'in', '(${excludedIds.join(',')})');

    if (filter.country != null) {
      query = query.eq('country', filter.country!);
    }
    if (filter.region != null) {
      query = query.eq('region', filter.region!);
    }
    if (filter.circle != null) {
      query = query.contains('circles', [filter.circle!]);
    }

    final profiles = await query.limit(30);

    return (profiles as List)
        .map((p) => ProfileModel.fromMap(p as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return _applyFilterToMock(mockProfiles, filter);
  }
});

/// Filters the mock profile list in the same way the Supabase query would.
List<ProfileModel> _applyFilterToMock(
  List<ProfileModel> profiles,
  DiscoveryFilter filter,
) {
  return profiles.where((p) {
    if (filter.country != null &&
        p.country?.toLowerCase() != filter.country!.toLowerCase()) {
      return false;
    }
    if (filter.region != null &&
        p.region?.toLowerCase() != filter.region!.toLowerCase()) {
      return false;
    }
    if (filter.circle != null && !p.circles.contains(filter.circle)) {
      return false;
    }
    return true;
  }).toList();
}

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
