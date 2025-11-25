import 'package:get/get.dart';

import '../chat_theme.dart';

class ChatConfigController extends GetxController {
  late ChatConfig config;

  void setTheme(ChatConfig value) {
    config = value;
  }
}

ChatConfigController get chatConfigController => Get.find<ChatConfigController>();
