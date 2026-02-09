
import 'package:chat_app/chat/chat_websocket/group_chat_web_socket_service.dart';
import 'package:get/get.dart';

import 'group_chat_controller.dart';

class GroupChatBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(()=>GroupChatController());
      Get.lazyPut(()=>GroupChatWebSocketService());

  }

}