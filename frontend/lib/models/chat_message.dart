class ChatMessage {
  final String id;
  final String userId;
  final String senderRole; // 'user' or 'admin'
  final String text;
  final DateTime createdAt;
  final bool outOfOffice;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.outOfOffice = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        senderRole: j['sender_role'] as String,
        text: j['text'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        outOfOffice: j['out_of_office'] as bool? ?? false,
      );
}
