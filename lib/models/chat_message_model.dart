class ChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      senderId: json['senderId'] as String,
      senderRole: json['senderRole'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
