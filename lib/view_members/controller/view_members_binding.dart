import 'package:chat_module/view_members/controller/view_members_controller.dart';
import 'package:get/get.dart';

class ViewMembersBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<ViewMembersController>(()=>ViewMembersController());
    // TODO: implement dependencies
  }

}