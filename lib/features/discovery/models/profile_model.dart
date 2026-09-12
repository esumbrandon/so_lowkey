class ProfileModel {
  final String id;
  final String alias;
  final String avatarSeed;
  final String batteryStatus;
  final String replyPace;
  final int maxActiveChats;
  final String? sparkPrompt;
  final String? sparkAnswer;
  final bool isDiscoverable;

  // Location & social circle fields
  final String? region;
  final String? country;
  final String? city;
  final List<String> circles; // e.g. ['Tech', 'Books', 'Music']

  ProfileModel({
    required this.id,
    required this.alias,
    required this.avatarSeed,
    required this.batteryStatus,
    required this.replyPace,
    required this.maxActiveChats,
    this.sparkPrompt,
    this.sparkAnswer,
    required this.isDiscoverable,
    this.region,
    this.country,
    this.city,
    this.circles = const [],
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    // Supabase returns TEXT[] as List<dynamic>
    final rawCircles = map['circles'];
    final circles = rawCircles is List
        ? rawCircles.map((e) => e.toString()).toList()
        : <String>[];

    return ProfileModel(
      id: map['id'] as String,
      alias: map['alias'] as String? ?? 'Anonymous',
      avatarSeed: map['avatar_seed'] as String? ?? 'default_warm',
      batteryStatus: map['battery_status'] as String? ?? 'medium',
      replyPace: map['reply_pace'] as String? ?? 'few_days',
      maxActiveChats: map['max_active_chats'] as int? ?? 3,
      sparkPrompt: map['spark_prompt'] as String?,
      sparkAnswer: map['spark_answer'] as String?,
      isDiscoverable: map['is_discoverable'] as bool? ?? true,
      region: map['region'] as String?,
      country: map['country'] as String?,
      city: map['city'] as String?,
      circles: circles,
    );
  }

  String get replyPaceLabel {
    switch (replyPace) {
      case 'same_day':
        return 'Replies same day';
      case 'slow_mail':
        return 'Slow mail pacing';
      case 'few_days':
      default:
        return 'Replies within days';
    }
  }

  /// Human-readable location string for display on the profile card.
  String? get locationLabel {
    final parts = [city, region, country].where((s) => s != null && s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}
