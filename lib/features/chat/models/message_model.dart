class MessageModel {
  final String id;
  final String connectionId;
  final String senderId;
  final String content;
  final bool isGracefulExit;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.connectionId,
    required this.senderId,
    required this.content,
    required this.isGracefulExit,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      connectionId: map['connection_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String? ?? '',
      isGracefulExit: map['is_graceful_exit'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
