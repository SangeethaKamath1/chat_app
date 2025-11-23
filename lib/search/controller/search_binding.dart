import 'package:chat_module/search/controller/search_controller.dart';

import 'package:get/get.dart';

class SearchBinding extends Bindings{
  @override
  void dependencies() {
   Get.lazyPut<SearchUserController>(()=>SearchUserController());
  }
  
}