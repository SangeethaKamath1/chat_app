import 'package:chat_app/add_members/controller/chat_add_members_controller.dart';
import 'package:get/get.dart';

class ChatAddMembersBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<ChatAddMembersController>(()=>ChatAddMembersController());
    // TODO: implement dependencies
  }
  
}