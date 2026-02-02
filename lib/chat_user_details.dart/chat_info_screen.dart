import 'package:amu_alumni/amu_alumni.dart';
import 'package:amu_alumni/utils/resources/color_resources.dart';
import 'package:amu_alumni/view/profile/view/otherUserProfile/controller/others_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../chat_app.dart';
import '../../routes/chat_app_routes.dart';
import 'controller/chat_info_controller.dart';


class ChatInfoScreen extends StatelessWidget {
  ChatInfoScreen({super.key});

  final ChatController chatController = Get.find<ChatController>();
  final ChatInfoController chatInfoController = Get.find<ChatInfoController>();
  final RxBool isMuted = false.obs; // UI only for now

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: (){
            Get.back(result: chatInfoController.isBlocked.value);
          },
          child: Icon(Icons.arrow_back,color:Colors.white,
                      ),
        ),
        title: const Text("Chat Info", style: TextStyle(color: Colors.white)),
        backgroundColor: chatConfigController.config.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          _header(isDark),

          const SizedBox(height: 8),

          _sectionTitle("Actions"),
          _actionRow(
            icon: Icons.call,
            title: "Audio Call",
            titleColor:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,
            onTap: () async => _startCall(isVideo: false),
          ),
          _actionRow(
            icon: Icons.video_call,
            titleColor:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,
            title: "Video Call",
            onTap: () async => _startCall(isVideo: true),
          ),

          const SizedBox(height: 12),

          _sectionTitle("Notifications"),
          Obx(() {
            return SwitchListTile(
              value: isMuted.value,
              onChanged: (v) {
                isMuted.value = v;
               isMuted.value? chatInfoController.muteUser():chatInfoController.unmuteUser();
                Get.snackbar(
                  "Notifications",
                  v ? "Muted" : "Unmuted",
                );
                // later: save to prefs / backend
              },
              title:  Text("Mute notifications",style: TextStyle(color: MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,),),
              activeColor: ColorResources.primary,
              secondary: const Icon(Icons.notifications_off),
            );
          }),

          const SizedBox(height: 12),

          _sectionTitle("Privacy"),
          // _actionRow(
          //   icon: Icons.person,
          //   titleColor:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,
                    
          //   title: "View Profile",
          //   onTap: () async {
          //     // You already do this in ChatScreen title tap
          //     if (chatController.userUid.isEmpty) {
          //       await chatController.getProfile();
          //     }
          //     if (chatController.userUid.isEmpty) {
          //       Get.snackbar("Please wait", "Profile is loading");
          //       return;
          //     }

          //     final GlobalNotifierController globalNotifier =
          //         Get.find<GlobalNotifierController>();

          //     Get.lazyPut(() => OthersProfileController(uid: chatController.userUid));
          //     globalNotifier.setUserId(chatController.userUid);

          //     Get.toNamed(AppRoutes.othersProfile);
          //   },
          // ),
          Obx(
             () {
              return _actionRow(
                icon: Icons.block,
                title: chatInfoController.isBlocked.value? "Unblock":"Block",
                titleColor: Colors.red,
                iconColor: Colors.red,
                onTap: () => _confirmBlock(context,chatInfoController),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _header(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey[200],
            child: ClipOval(
              child: (chatController.icon).isNotEmpty
                  ? Image.network(
                      chatController.icon,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_circle,
                        size: 64,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.account_circle, size: 64, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatController.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Obx(() {
                  // If you passed status RxString into chat args and stored, show it.
                  // If not available, you can remove this.
                  return Text(
                    chatController.status.value.isEmpty
                        ? ""
                        : (chatController.status.value == "online"
                            ? "Online"
                            : "Offline"),
                    style: TextStyle(
                      color: chatController.status.value == "online"
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _startCall({required bool isVideo}) async {
    // permissions
    final micStatus = await Permission.microphone.request();
    if (micStatus.isDenied) {
      Get.snackbar("Permission Required", "Allow microphone access");
      return;
    }
    if (micStatus.isPermanentlyDenied) {
      Get.snackbar("Permission Required", "Enable microphone permission from Settings");
      return;
    }

    if (isVideo) {
      final camStatus = await Permission.camera.request();
      if (camStatus.isDenied) {
        Get.snackbar("Permission Required", "Allow camera access");
        return;
      }
      if (camStatus.isPermanentlyDenied) {
        Get.snackbar("Permission Required", "Enable camera permission from Settings");
        return;
      }
    }

    // reuse your existing call logic (same as ChatScreen)
    chatController.chatWebSocket.roomId =
        "${chatController.conversationId}_${chatController.uuid.v4()}";

    chatController.chatWebSocket.setRoom(chatController.chatWebSocket.roomId);

    final conversationIdInt = int.tryParse(chatController.conversationId) ?? 0;
    if (conversationIdInt != 0) {
      chatController.chatWebSocket.connect(conversationIdInt);
    }

    Get.toNamed(
      ChatAppRoutes.callScreen,
      arguments: {
        'isCaller': true,
        'callId': chatController.chatWebSocket.roomId,
        'fromNotification': false,
        'callerName': chatController.name,
        'callerId': chatController.userId,
        'isVideo': isVideo,
        'isBlockedBy':chatInfoController.isBlockedBy.value,
        "isBlocked":chatInfoController.isBlocked.value
      },
    );
  }

void _confirmBlock(BuildContext context, ChatInfoController chatInfoController) {
  Get.dialog(
    Obx(() {
      final isBlocked = chatInfoController.isBlocked.value;

      return AlertDialog(
        title: Text(isBlocked ? "Unblock user?" : "Block user?"),
        content: Text(
          isBlocked
              ? "You will start receiving messages and calls from this user again."
              : "You will no longer receive messages and calls from this user.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Get.back();

              if (isBlocked) {
                await chatInfoController.unblockUser();
                Get.snackbar("Unblocked", "User unblocked successfully");
              } else {
                await chatInfoController.bloackUser();
                Get.snackbar("Blocked", "User blocked successfully");
              }
            },
            child: Text(
              isBlocked ? "Unblock" : "Block",
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }),
  );
}
}
