import 'package:chat_app/chat/controller/chat_controller.dart';
import 'package:chat_app/chat_app.dart';
import 'package:get/get.dart';

class ChatBinding extends Bindings{
  @override
@override
  void dependencies() {
    Get.lazyPut(()=>ChatController());
    Get.lazyPut(()=>ChatWebSocketService());
  }

}