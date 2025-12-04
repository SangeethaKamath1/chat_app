import 'package:get/get.dart';

import '../add_members/controller/chat_add_members_controller.dart';
import '../view_members/controller/view_members_controller.dart';

class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(()=>ViewMembersController(), fenix: true);
    Get.lazyPut(() => ChatAddMembersController(),fenix:true);
  }
}