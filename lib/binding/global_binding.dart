import 'package:get/get.dart';

import '../add_members/controller/add_members_controller.dart';
import '../view_members/controller/view_members_controller.dart';

class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(()=>ViewMembersController(), fenix: true);
    Get.lazyPut(() => AddMembersController(),fenix:true);
  }
}