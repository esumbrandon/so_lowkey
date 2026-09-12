/// Represents a connection between two users, with the peer's profile
/// information embedded for easy display in the connections inbox.
class ConnectionModel {
  final String id;
  final String initiatorId;
  final String recipientId;
  final String status; // 'pending' | 'active' | 'gracefully_closed' | 'blocked'
  final DateTime lastInteractionAt;
  final DateTime createdAt;
  final String? closedReason;

  // Peer profile info — resolved after fetching
  final String peerAlias;
  final String peerBatteryStatus;
  final String peerReplyPace;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;

  const ConnectionModel({
    required this.id,
    required this.initiatorId,
    required this.recipientId,
    required this.status,
    required this.lastInteractionAt,
    required this.createdAt,
    this.closedReason,
    required this.peerAlias,
    required this.peerBatteryStatus,
    required this.peerReplyPace,
    this.lastMessageContent,
    this.lastMessageAt,
  });

  /// Whether this is a pending request waiting for the current user's response.
  bool isIncomingPending(String myId) =>
      status == 'pending' && recipientId == myId;

  /// Whether this is an active two-way conversation.
  bool get isActive => status == 'active';

  /// Whether this connection has been gracefully closed.
  bool get isClosed => status == 'gracefully_closed';

  String get replyPaceLabel {
    switch (peerReplyPace) {
      case 'same_day':
        return 'Replies same day';
      case 'slow_mail':
        return 'Slow mail pacing';
      case 'few_days':
      default:
        return 'Replies within days';
    }
  }

  static ConnectionModel fromMap(
    Map<String, dynamic> map, {
    required String myId,
  }) {
    final isInitiator = map['initiator_id'] == myId;

    // The peer profile is embedded via a join (profiles!initiator_id or profiles!recipient_id)
    final peerProfile = isInitiator
        ? (map['recipient_profile'] as Map<String, dynamic>? ?? {})
        : (map['initiator_profile'] as Map<String, dynamic>? ?? {});

    return ConnectionModel(
      id: map['id'] as String,
      initiatorId: map['initiator_id'] as String,
      recipientId: map['recipient_id'] as String,
      status: map['status'] as String? ?? 'pending',
      lastInteractionAt: DateTime.parse(
        map['last_interaction_at'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      closedReason: map['closed_reason'] as String?,
      peerAlias: peerProfile['alias'] as String? ?? 'Anonymous',
      peerBatteryStatus: peerProfile['battery_status'] as String? ?? 'medium',
      peerReplyPace: peerProfile['reply_pace'] as String? ?? 'few_days',
      lastMessageContent: map['last_message'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
    );
  }
}
