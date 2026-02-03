import 'package:amu_alumni/utils/resources/color_resources.dart';
import 'package:chat_app/chat_app.dart';
import 'package:chat_app/helpers.dart';
import 'package:chat_app/src/theme/controller/chat_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../chat/controller/chat_controller.dart';
import '../group/group_chat/controller/group_chat_controller.dart';
import 'controller/recent_conversation_controller.dart';

class RecentConversationScreen extends StatefulWidget {
  const RecentConversationScreen({super.key});

  @override
  State<RecentConversationScreen> createState() =>
      _RecentConversationScreenState();
}

class _RecentConversationScreenState extends State<RecentConversationScreen> {
  final RecentConversationController controller =
      Get.find<RecentConversationController>();

  /// ✅ Forward mode selection (max 5)
  /// key = conversationId, value = user.type (PRIVATE_CHAT / GROUP_CHAT)
  final RxMap<int, String> selectedConversations = <int, String>{}.obs;

  bool get isForwardMode =>
      (Get.arguments as Map<String, dynamic>?)?["mode"] == "forward";

  /// ✅ who initiated forward: "private" | "group"
  String get forwardFrom =>
      (Get.arguments as Map<String, dynamic>?)?["from"]?.toString() ?? "private";

  void toggleSelect(int conversationId, String type) {
    if (conversationId == 0) return;

    if (selectedConversations.containsKey(conversationId)) {
      selectedConversations.remove(conversationId);
      return;
    }

    if (selectedConversations.length >= 5) {
      Get.snackbar("Limit reached", "You can forward to up to 5 chats");
      return;
    }

    selectedConversations[conversationId] = type;
  }

  Future<void> forwardNow() async {
    if (selectedConversations.isEmpty) {
      Get.snackbar("Select chats", "Choose at least 1 chat");
      return;
    }

    try {
      if (forwardFrom == "group") {
        if (!Get.isRegistered<GroupChatController>()) {
          Get.snackbar("Error", "Group chat controller not found");
          return;
        }

        final groupController = Get.find<GroupChatController>();

        if (groupController.forwardMessage.value == null) {
          Get.snackbar("Error", "No message selected to forward");
          return;
        }

        await groupController.forwardToMultipleConversations(
          targetConversation: selectedConversations,
        );
      } else {
        if (!Get.isRegistered<ChatController>()) {
          Get.snackbar("Error", "Chat controller not found");
          return;
        }

        final chatController = Get.find<ChatController>();

        if (chatController.forwardMessage.value == null) {
          Get.snackbar("Error", "No message selected to forward");
          return;
        }

        await chatController.forwardToMultipleConversations(
          targetConversation: selectedConversations,
        );
      }

      selectedConversations.clear();
      Get.back();
      Get.snackbar("Forwarded", "Message forwarded");
    } catch (e) {
      Get.snackbar("Error", "Forward failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isForwardMode ? "Forward to..." : "Conversations",
            style: const TextStyle(color: Colors.white),
          ),
          leading: isForwardMode
              ? InkWell(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: Colors.white),
                )
              : InkWell(
                  onTap: () {
                    chatConfigController.config.prefs
                        .setInt(chatConfigController.config.conversationId, 0);
                    Get.toNamed(ChatAppRoutes.createGroup)?.then((_) {
                      controller.page = 0;
                      controller.isLastPage = false;
                      controller.search();
                    });
                  },
                  child: const Icon(Icons.group_add, color: Colors.white),
                ),
          automaticallyImplyLeading: false,
          backgroundColor: chatConfigController.config.primaryColor,
          actions: [
            if (!isForwardMode)
              InkWell(
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.page = 0;
                    controller.isLastPage = false;
                    controller.search();
                  });
                  Get.toNamed(ChatAppRoutes.searchScreenInChat);
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.search, color: Colors.white),
                ),
              ),
          ],
        ),

        /// ✅ Forward bottom bar
        bottomNavigationBar: isForwardMode
            ? Obx(() {
                final count = selectedConversations.length;
                return SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: chatConfigController.config.primaryColor,
                      boxShadow: const [
                        BoxShadow(blurRadius: 4, color: Colors.black26),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Forward ($count/5)",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: count == 0 ? null : () => forwardNow(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                chatConfigController.config.primaryColor,
                          ),
                          child: const Text("Send"),
                        ),
                      ],
                    ),
                  ),
                );
              })
            : null,

        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () {
                  controller.isRefreshing.value = true;
                  controller.page = 0;
                  controller.isLastPage = false;
                  return controller.search();
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels ==
                        notification.metrics.maxScrollExtent) {
                      if (!controller.isLoading.value &&
                          !controller.isFetching.value) {
                        controller.search();
                      }
                    }
                    return false;
                  },
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        !controller.isRefreshing.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.results.isEmpty) {
                      return Center(
                        child: Text(
                          "No conversations found",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: controller.results.length,
                      itemBuilder: (context, index) {
                        final user = controller.results[index];
                        final convId = user.id ?? 0;

                        return ListTile(
                          leading: Stack(
                            children: [
                              ClipOval(
                                child: user.type == "PRIVATE_CHAT"
                                    ? (user.peerUser?.profilePicture != null &&
                                            user.peerUser?.profilePicture
                                                    ?.isNotEmpty ==
                                                true)
                                        ? Image.network(
                                            user.peerUser?.profilePicture ?? "",
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                              Icons.account_circle,
                                              size: 36,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.account_circle,
                                            size: 36,
                                            color: Colors.grey,
                                          )
                                    : (user.icon != null &&
                                            user.icon?.isNotEmpty == true)
                                        ? Image.network(
                                            user.icon ?? "",
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                              Icons.group,
                                              size: 36,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.group,
                                            size: 36,
                                            color: Colors.grey,
                                          ),
                              ),
                              user.type == "PRIVATE_CHAT"
                                  ? Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Obx(() {
                                        final isOnline =
                                            user.status.value == "online";
                                        return Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: isOnline
                                                ? Colors.green
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        );
                                      }),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),

                          title: Text(
                            user.owner != null
                                ? (user.groupName ?? "")
                                : (user.peerUser?.username ?? ""),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),

                          subtitle: Obx(() {
                            if (user.isTyping.value) {
                              return const Text(
                                "Typing...",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            if (user.unreadCount.value > 0) {
                              return Text(
                                "${user.unreadCount.value} new messages",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          }),

                          /// ✅ Trailing: checkbox in forward mode, menu otherwise
                          trailing: isForwardMode
                              ? Obx(() {
                                  final selected =
                                      selectedConversations.containsKey(convId);

                                  return Checkbox(
                                    value: selected,
                                    activeColor: ColorResources.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    side: MaterialStateBorderSide.resolveWith(
                                      (_) => const BorderSide(
                                        width: 1.0,
                                        color: ColorResources.primary,
                                      ),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (_) =>
                                        toggleSelect(convId, user.type ?? ""),
                                  );
                                })
                              : PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color:
                                        isDark ? Colors.white : Colors.black,
                                  ),
                                  onSelected: (value) {
                                    if (value == "clear") {
                                      _showClearChatDialog(
                                        context,
                                        controller,
                                        convId,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: "clear",
                                      child: Text(
                                        "Delete Chat",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                          onTap: () {
                            if (isForwardMode) {
                              toggleSelect(convId, user.type ?? "");
                              return;
                            }

                            // ✅ normal behaviour (open chat)
                            chatConfigController.config.prefs.setInt(
                              chatConfigController.config.conversationId,
                              convId,
                            );

                            if (user.type == "PRIVATE_CHAT") {
                              Get.toNamed(
                                ChatAppRoutes.chat,
                                arguments: {
                                  "name": user.peerUser?.username,
                                  "icon": user.peerUser?.profilePicture ?? "",
                                  "id": user.peerUser?.id,
                                  "conversationId": user.id,
                                  "status": user.status,
                                  "useruid": user.peerUser?.useruid ?? "",
                                  "isBlockedBy":
                                      user.peerUser?.isBlockedBy ?? false
                                },
                              )?.then((_) {
                                controller.page = 0;
                                controller.isLastPage = false;
                                controller.search();
                              });
                            } else {
                              Get.toNamed(
                                ChatAppRoutes.groupChatScreen,
                                arguments: {
                                  "name": user.groupName,
                                  "icon": user.icon,
                                  "conversationId": user.id,
                                  "status": user.status,
                                },
                              )?.then((_) {
                                controller.page = 0;
                                controller.isLastPage = false;
                                controller.search();
                              });
                            }
                          },
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔴 CLEAR CHAT CONFIRMATION
void _showClearChatDialog(
  BuildContext context,
  RecentConversationController controller,
  int conversationId,
) {
  Get.dialog(
    AlertDialog(
      title: const Text("Delete Chat"),
      content: const Text(
        "Are you sure you want to clear this chat? This action cannot be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            Get.back();
            await controller.clearConversation(conversationId);
          },
          child: const Text(
            "Delete chat",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}
