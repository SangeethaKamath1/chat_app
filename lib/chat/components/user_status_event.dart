class UserStatusEvent {
  final int conversationId;
  final int userId;
  final bool online;

  UserStatusEvent({
    required this.conversationId,
    required this.userId,
    required this.online,
  });
}