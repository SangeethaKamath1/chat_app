import 'package:get/get.dart';

import '../chat_theme.dart';

class ChatConfigController extends GetxController {
  late ChatConfig config;

  void setTheme(ChatConfig config) {
    config = config;
  }
}

ChatConfigController get chatConfigController => Get.find<ChatConfigController>();
