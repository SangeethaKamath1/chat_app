import 'package:chat_module/group/create_group/controller/create_group_controller.dart';
import 'package:get/get.dart';



class CreateGroupBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<CreateGroupController>(()=>CreateGroupController());
    // TODO: implement dependencies
  }

}