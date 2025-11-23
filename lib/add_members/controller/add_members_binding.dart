import 'package:chat_module/add_members/controller/add_members_controller.dart';
import 'package:get/get.dart';

class AddMembersBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<AddMembersController>(()=>AddMembersController());
    // TODO: implement dependencies
  }
  
}