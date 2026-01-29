

import 'package:chat_app/chat_app.dart';
import 'package:get/get.dart';

import 'recent_conversation_controller.dart';

class RecentConversationBinding extends Bindings{
  @override
  void dependencies() {
    Get.put(SubscribeWebSocketService());
   Get.put(RecentConversationController());
   
  }
}