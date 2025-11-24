import 'package:get/get.dart';

import '../chat_theme.dart';

class ChatThemeController extends GetxController {
  late ChatTheme theme;

  void setTheme(ChatTheme newTheme) {
    theme = newTheme;
  }
}

ChatThemeController get chatThemeController => Get.find<ChatThemeController>();
