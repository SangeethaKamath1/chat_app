
import 'package:chat_app/chat_app.dart';
import 'package:chat_app/helpers.dart';
import 'package:chat_app/src/theme/controller/chat_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'controller/recent_conversation_controller.dart';

class RecentConversationScreen extends GetView<RecentConversationController> {
  const RecentConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
   
           

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Conversations",
            style: TextStyle(color: Colors.white),
          ),
          leading: InkWell(
            onTap: () {
              chatConfigController.config.prefs
                  .setInt(chatConfigController.config.conversationId, 0);
              Get.toNamed(ChatAppRoutes.createGroup)?.then((_) {
                controller.page = 0;
                controller.isLastPage = false;
                //Get.put(SubscribeWebSocketService(conversationController));
                controller.search();
              });
            },
            child: const Icon(Icons.group_add),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: chatConfigController.config.primaryColor,
          actions: [
            InkWell(
              onTap: () {
                // Get.delete<PingWebSocketService>(force: true);
                // Get.put(PingWebSocketService()).connect();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.page = 0;
                  controller.isLastPage = false;
                 // Get.put(SubscribeWebSocketService(conversationController));
                  controller.search();
                });
                Get.toNamed(ChatAppRoutes.searchScreenInChat);
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.search),
              ),
            )
          ],
        ),
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
                          "No conevrsations found",
                          style: TextStyle(
                            color: MediaQuery.platformBrightnessOf(context) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: controller.results.length,
                      itemBuilder: (context, index) {
                        final user = controller.results[index];

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
                                                color: Colors.white, width: 2),
                                          ),
                                        );
                                      }),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),

                          title: Text(
                            user.owner != null
                                ? user.groupName ?? ""
                                : user.peerUser?.username ?? "",
                            style: TextStyle(
                              color: MediaQuery.platformBrightnessOf(context) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
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
                                //${formatDate(DateTime.fromMillisecondsSinceEpoch(conversationController.lastMessageList[index].createdAt ?? 0))}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            // final lastMsg =
                            //     controller.lastMessageList[index];

                            // if (lastMsg.message?.isNotEmpty == true) {
                            //   return Row(
                            //     mainAxisAlignment:
                            //         MainAxisAlignment.spaceBetween,
                            //     children: [
                            //       SizedBox(
                            //         width: 200,
                            //         child: Text(
                            //           lastMsg.message ?? "",
                            //           maxLines: 1,
                            //           overflow: TextOverflow.ellipsis,
                            //           style: const TextStyle(
                            //             fontSize: 12,
                            //             color: Colors.grey,
                            //             fontWeight: FontWeight.bold,
                            //           ),
                            //         ),
                            //       ),
                            //       Text(
                            //         formatDate(
                            //           DateTime.fromMillisecondsSinceEpoch(
                            //               lastMsg.createdAt ?? 0),
                            //         ),
                            //         style: const TextStyle(
                            //           fontSize: 12,
                            //           color: Colors.grey,
                            //           fontWeight: FontWeight.bold,
                            //         ),
                            //       ),
                              //  ],
                             // );
                           // }

                            return const SizedBox.shrink();
                          }),

                          /// 🔥 CLEAR CHAT MENU
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: MediaQuery.platformBrightnessOf(context) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onSelected: (value) {
                              if (value == "clear") {
                                _showClearChatDialog(
                                  context,
                                  controller,
                                  user.id ?? 0,
                                 
                                  
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: "clear",
                                child: Text(
                                  "Delete Chat",
                                  style: TextStyle(
                                    color: MediaQuery.platformBrightnessOf(
                                                context) ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          onTap: () {
                            chatConfigController.config.prefs.setInt(
                              chatConfigController.config.conversationId,
                              user.id ?? 0,
                            );

                            // Get.delete<PingWebSocketService>(force: true);
                            // Get.put(PingWebSocketService()).connect();

                            if (user.type == "PRIVATE_CHAT") {
                              Get.toNamed(
                                ChatAppRoutes.chat,
                                arguments: {
                                  "name": user.peerUser?.username,
                                  "icon": user.peerUser?.profilePicture ?? "",
                                  "id": user.peerUser?.id,
                                  "conversationId": user.id,
                                  "status": user.status,
                                  "useruid":user.peerUser?.useruid??"",
                                  "isBlockedBy":user.peerUser?.isBlockedBy??false
                                },
                              )?.then((_) {
                                controller.page = 0;
                                controller.isLastPage = false;
                                // Get.put(SubscribeWebSocketService(
                                //     conversationController));
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
                                // Get.put(SubscribeWebSocketService(
                                //     conversationController));
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
      title: Text(
        "Delete Chat",
        //style: TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,),
      ),
      content: Text(
        "Are you sure you want to clear this chat? This action cannot be undone.",
        //style: TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            "Cancel",
            //style: TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,),
          ),
        ),
        TextButton(
          onPressed: () async {
            Get.back();
            await controller.clearConversation(conversationId);
            // controller.page = 0;
            // controller.isLastPage = false;
            // controller.search();
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
