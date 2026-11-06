/// A user as shown in the admin's user list.
class UserSummary {
  final String id;
  final String name;
  final String email;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const UserSummary({
    required this.id,
    required this.name,
    required this.email,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory UserSummary.fromJson(Map<String, dynamic> j) => UserSummary(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        lastMessage: j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] == null
            ? null
            : DateTime.parse(j['last_message_at'] as String).toLocal(),
        unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      );
}
