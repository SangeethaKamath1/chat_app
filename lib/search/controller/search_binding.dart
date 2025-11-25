import 'package:chat_app/search/controller/search_controller.dart';

import 'package:get/get.dart';

class UserSearchBinding extends Bindings{
  @override
  void dependencies() {
   Get.lazyPut<SearchUserController>(()=>SearchUserController());
  }
  
}