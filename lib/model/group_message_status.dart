// models/message_status.dart
class GroupMessageStatus {
  final List<UserStatus>? delivered;
  final List<UserStatus>? sent;
  final List<UserStatus>? seen;

  GroupMessageStatus({
     this.delivered,
     this.sent,
     this.seen

  });

  factory GroupMessageStatus.fromJson(Map<String, dynamic> json) {
    return GroupMessageStatus(
      delivered: (json['DELIVERED'] as List? ?? [])
          .map((user) => UserStatus.fromJson(user))
          .toList(),
      sent: (json['SEND'] as List? ?? [])
          .map((user) => UserStatus.fromJson(user))
          .toList(),
           seen: (json['SEEN'] as List? ?? [])
          .map((user) => UserStatus.fromJson(user))
          .toList(),
    );
  }

  
}

class UserStatus {
  final int id;
  final String username;
  final DateTime updatedAt;

  UserStatus({
    required this.id,
    required this.username,
    required this.updatedAt,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      id: json['id'] ?? 0,
      username: json['username'] ?? 'Unknown',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }
}