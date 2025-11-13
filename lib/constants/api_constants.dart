class ApiConstants {
  static const String baseUrl = "http://66.29.152.193:8106/chat-service/api/v1/";
  static const String pingWebsocketUrl = "ws://66.29.152.193:8106/chat-service/presence";
  static const String subscriptionWebsocketUrl = "ws://66.29.152.193:8106/chat-service/presence";
  static const String groupChatWebsocketUrl="ws://66.29.152.193:8106/chat-service/group-chat";
  static const String chatWebSocketService="ws://66.29.152.193:8106/chat-service/chat";
  static const String login = "user/log-in";
  static const String register = "user/register";
  static const String searchUser="user/search";
  static const String createConversation="conversation/create/";
  static const String recentConversationList ="conversation/conversation-list";
  static const String chatHistory = "conversation/chat-history";
  static const String emojiList = "conversation/reaction";
  static const String setGroupIcon = "group/set-group-icon/";
  static const String createGroup = "group/create";
  static const String viewMembers = "group/list-members/";
  static const String addMember="group/add-member";
  static const String removeMember="group/remove-member";
  static const String memberPromote="group/promote";
   static const String updateGroup="group/update";
   static const String currentUserDetails="conversation/current-user/";
   static const String messageStatus = "group/message-stats/";
   static const String exitGroup ="group/exit/";
   static const String currentGroupDetails="group/";

  
}
