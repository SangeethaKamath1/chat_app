

import 'package:get/get.dart';

import 'recent_conversation_controller.dart';

class RecentConversationBinding extends Bindings{
  @override
  void dependencies() {
   Get.lazyPut<RecentConversationController>(()=>RecentConversationController());
  }
  
}