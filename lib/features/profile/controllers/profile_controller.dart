import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/mock/mock_data.dart';

/// Represents the current user's own profile data.
class ProfileData {
  final String id;
  final String alias;
  final String batteryStatus;
  final String replyPace;
  final int maxActiveChats;
  final String? sparkPrompt;
  final String? sparkAnswer;
  final bool isDiscoverable;
  final String? country;
  final String? region;
  final String? city;
  final List<String> circles;

  const ProfileData({
    required this.id,
    required this.alias,
    required this.batteryStatus,
    required this.replyPace,
    required this.maxActiveChats,
    this.sparkPrompt,
    this.sparkAnswer,
    required this.isDiscoverable,
    this.country,
    this.region,
    this.city,
    required this.circles,
  });

  ProfileData copyWith({
    String? alias,
    String? batteryStatus,
    String? replyPace,
    int? maxActiveChats,
    String? sparkPrompt,
    String? sparkAnswer,
    bool? isDiscoverable,
    String? country,
    String? region,
    String? city,
    List<String>? circles,
  }) {
    return ProfileData(
      id: id,
      alias: alias ?? this.alias,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      replyPace: replyPace ?? this.replyPace,
      maxActiveChats: maxActiveChats ?? this.maxActiveChats,
      sparkPrompt: sparkPrompt ?? this.sparkPrompt,
      sparkAnswer: sparkAnswer ?? this.sparkAnswer,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
      circles: circles ?? this.circles,
    );
  }

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      id: map['id'] as String,
      alias: map['alias'] as String? ?? 'Anonymous',
      batteryStatus: map['battery_status'] as String? ?? 'medium',
      replyPace: map['reply_pace'] as String? ?? 'few_days',
      maxActiveChats: (map['max_active_chats'] as int?) ?? 3,
      sparkPrompt: map['spark_prompt'] as String?,
      sparkAnswer: map['spark_answer'] as String?,
      isDiscoverable: map['is_discoverable'] as bool? ?? true,
      country: map['country'] as String?,
      region: map['region'] as String?,
      city: map['city'] as String?,
      circles:
          (map['circles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Mock profile for offline dev mode.
  static const ProfileData mock = ProfileData(
    id: mockUserId,
    alias: 'Quiet Traveler',
    batteryStatus: 'medium',
    replyPace: 'few_days',
    maxActiveChats: 3,
    sparkPrompt: 'A niche rabbit hole I fell down recently:',
    sparkAnswer: 'The history of procedurally generated worlds in 8-bit games.',
    isDiscoverable: true,
    country: null,
    region: null,
    city: null,
    circles: ['Tech', 'Books', 'Film'],
  );
}

/// Fetches the current user's own profile row from Supabase.
final ownProfileProvider = FutureProvider<ProfileData>((ref) async {
  if (!isSupabaseConfigured) return ProfileData.mock;

  try {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return ProfileData.mock;

    final row = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return ProfileData.mock;
    return ProfileData.fromMap(row);
  } catch (_) {
    return ProfileData.mock;
  }
});

class ProfileController {
  final Ref _ref;
  ProfileController(this._ref);

  /// Persist an updated profile to Supabase.
  Future<void> updateProfile(ProfileData updated) async {
    if (!isSupabaseConfigured) return;

    try {
      final client = Supabase.instance.client;
      await client
          .from('profiles')
          .update({
            'alias': updated.alias,
            'battery_status': updated.batteryStatus,
            'reply_pace': updated.replyPace,
            'max_active_chats': updated.maxActiveChats,
            'spark_prompt': updated.sparkPrompt,
            'spark_answer': updated.sparkAnswer,
            'is_discoverable': updated.isDiscoverable,
            'country': updated.country,
            'region': updated.region,
            'city': updated.city,
            'circles': updated.circles,
          })
          .eq('id', updated.id);

      // Refresh the profile cache
      _ref.invalidate(ownProfileProvider);
    } catch (_) {}
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    if (!isSupabaseConfigured) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}

final profileControllerProvider = Provider<ProfileController>(
  (ref) => ProfileController(ref),
);
