class LoungeModel {
  final String id;
  final String name;
  final String? description;
  final String ambientAudioUrl;
  final String iconName;

  LoungeModel({
    required this.id,
    required this.name,
    this.description,
    required this.ambientAudioUrl,
    required this.iconName,
  });

  factory LoungeModel.fromMap(Map<String, dynamic> map) {
    return LoungeModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      ambientAudioUrl: map['ambient_audio_url'] as String,
      iconName: map['icon_name'] as String,
    );
  }
}

class LoungePresenceModel {
  final String userId;
  final String loungeId;
  final String statusText;

  LoungePresenceModel({
    required this.userId,
    required this.loungeId,
    required this.statusText,
  });

  // Note: realtime .stream() queries can't perform joins, so alias is
  // resolved separately in the UI layer via loungePresenceAliasesProvider.
  factory LoungePresenceModel.fromMap(Map<String, dynamic> map) {
    return LoungePresenceModel(
      userId: map['user_id'] as String,
      loungeId: map['lounge_id'] as String,
      statusText: map['status_text'] as String? ?? 'Reading quietly',
    );
  }
}
