class ApiConstants {
  static const String baseUrl = "http://66.29.152.193:8106/chat-service/api/v1/";
  static const String pingWebsocketUrl = "ws://66.29.152.193:8106/chat-service/presence";
  static const String subscriptionWebsocketUrl = "ws://66.29.152.193:8106/chat-service/presence";
  static const String groupChatWebsocketUrl="ws://66.29.152.193:8106/chat-service/group-chat";
  static const String chatWebSocketService="ws://66.29.152.193:8106/chat-service/chat";
  static const chatService = "chat-service/api/v1/";
  static const String login = "user/log-in";
  static const String register = "user/register";
  // static const String searchUser="${chatService}user/search";
  static const String createConversation="${chatService}conversation/create/";
  static const String recentConversationList ="${chatService}conversation/conversation-list";
  static const String chatHistory = "${chatService}conversation/chat-history";
  static const String emojiList = "${chatService}conversation/reaction";
  static const String setGroupIcon = "${chatService}group/set-group-icon/";
  static const String createGroup = "${chatService}group/create";
  static const String viewMembers = "${chatService}group/list-members/";
  static const String addMember="${chatService}group/add-member";
  static const String removeMember="${chatService}group/remove-member";
  static const String memberPromote="${chatService}group/promote";
   static const String updateGroup="${chatService}group/update";
   static const String currentUserDetails="${chatService}conversation/current-user/";
   static const String messageStatus = "${chatService}group/message-stats/";
   static const String exitGroup ="${chatService}group/exit/";
   static const String currentGroupDetails="${chatService}group/";
   static const String searchUser="https://dev.trrings.com/user-service/api/v1/user-follow/getFollower";

  
}
