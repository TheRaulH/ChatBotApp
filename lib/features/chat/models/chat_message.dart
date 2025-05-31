class ChatMessage {
  final int? id;
  final int chatId;
  final String content;
  final bool isUserMessage;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.chatId,
    required this.content,
    required this.isUserMessage,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'content': content,
      'is_user_message': isUserMessage ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      chatId: map['chat_id'],
      content: map['content'],
      isUserMessage: map['is_user_message'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
