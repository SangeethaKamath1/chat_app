import 'package:chat_app/audio_call/screens/call_screen.dart';
import 'package:chat_app/audio_call/controller/call_bindig.dart';
import 'package:chat_app/bindings/auth_binding.dart';
import 'package:chat_app/chat/chat_screen.dart';
import 'package:chat_app/chat/controller/chat_binding.dart';
import 'package:chat_app/group/create_group/create_group_screen.dart';
import 'package:chat_app/group/group_chat/controller/group_chat_binding.dart';
import 'package:chat_app/group/group_chat/group_chat_screen.dart';
import 'package:chat_app/login/login_screen.dart';
import 'package:chat_app/recent_conversation/recent_conversation_screen.dart';
import 'package:chat_app/register/register_screen.dart';
import 'package:get/route_manager.dart';

import '../add_members/add_members_screen.dart';
import '../add_members/controller/add_members_binding.dart';
import '../group/create_group/controller/create_group_binding.dart';
import '../group/group_detail/controller/group_detail_binding.dart';
import '../group/group_detail/group_detail_screen.dart';
import '../recent_conversation/controller/recent_conversation_binding.dart';
import '../search/controller/search_binding.dart';
import '../search/search_screen.dart';
import '../view_members/controller/view_members_binding.dart';
import '../view_members/view_members.dart';

class AppRoutes{
  static const String login="/login";
  static const String register="/register";
  static const String  chat="/chat";
  static const String  search="/search";
  static const String recentConversation = "/recentConversation";
  static const String createGroup = "/createGroup";
  static const String addMembers = "/addMembers";
  static const String groupDetail = "/groupDetail";
  static const String viewMembers = "/viewMemebers";
  static const String groupChatScreen="/groupChatScreen";
  static const String callScreen ="/callScreen";
  static List<GetPage> pages=[
  // GetPage(
  //     name: login,
  //     page: () => const LoginScreen(),
  //   binding: AuthBinding()
  //   ),

  //   GetPage(
  //     name:register,
  //     page:()=>RegisterScreen(),
  //     binding: AuthBinding()),

      GetPage(
      name:groupChatScreen,
      page:()=>GroupChatScreen(),
      binding: GroupChatBinding()),
      
      GetPage(name:chat,page: ()=>ChatScreen(),
      binding: ChatBinding()),


      GetPage(name:search,
      page:()=>UserSearchScreen(),
      binding: UserSearchBinding()),

      GetPage(name:recentConversation,
      page:()=>RecentConversationScreen(),
      binding: RecentConversationBinding()),

      GetPage(name:createGroup,
      page:()=>CreateGroupScreen(),
      binding: CreateGroupBinding()),

       GetPage(name:addMembers,
      page:()=>AddMembersScreen(),
      binding: AddMembersBinding()),
      
      GetPage(name:groupDetail,
       page:()=>GroupDetailScreen(),
      binding: GroupDetailBinding()
      ),
      GetPage(name:callScreen,
      page:()=>VoiceCallScreen(),
     ),

      GetPage(name:viewMembers,
      page:()=>ViewMembersScreen(),
      binding:ViewMembersBinding())
  ];
}