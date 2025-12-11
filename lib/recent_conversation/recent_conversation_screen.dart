import 'package:chat_app/chat/chat_websocket/ping_web_socket.dart';
import 'package:chat_app/chat/chat_websocket/subscribe_web_socket.dart';
import 'package:chat_app/chat_app.dart';
import 'package:chat_app/helpers.dart';
import 'package:chat_app/src/theme/controller/chat_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constant.dart';

import 'controller/recent_conversation_controller.dart';

class RecentConversationScreen extends StatelessWidget {
  const RecentConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RecentConversationController conversationController = Get.find<
        RecentConversationController>(); // final RecentConversationController conversationController =
    //     Get.find<RecentConversationController>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Conversations",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          leading: InkWell(
              onTap: () {
                chatConfigController.config.prefs
                    .setInt(chatConfigController.config.conversationId, 0);
                Get.toNamed(ChatAppRoutes.createGroup)?.then((_) {
                  conversationController.page = 0;
                  conversationController.isLastPage = false;
                  Get.put(SubscribeWebSocketService(conversationController));
                  conversationController.search();
                });
              },
              child: Icon(Icons.group_add)),
          automaticallyImplyLeading: false,
          backgroundColor: chatConfigController.config.primaryColor,
          actions: [
            InkWell(
              onTap: () {
                Get.delete<PingWebSocketService>(force: true);
                Get.put(PingWebSocketService()).connect();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  conversationController.page = 0;
                  conversationController.isLastPage = false;
                  Get.put(SubscribeWebSocketService(conversationController));
                  conversationController.search();
                });

                Get.toNamed(ChatAppRoutes.searchScreenInChat);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(Icons.search),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(12),
            //   child: TextField(
            //     controller: conversationController.searchController,
            //     focusNode: conversationController.searchFocusNode,
            //     onChanged: conversationController.onSearchTextChanged,
            //     decoration: InputDecoration(
            //       hintText: "Search username...",
            //       hintStyle: TextStyle(
            //         color: MediaQuery.platformBrightnessOf(context) ==
            //                 Brightness.dark
            //             ? Colors.white
            //             : Colors.black,
            //       ),
            //       prefixIcon: Icon(
            //         Icons.search,
            //         color: MediaQuery.platformBrightnessOf(context) ==
            //                 Brightness.dark
            //             ? Colors.white
            //             : Colors.black,
            //       ),
            //       enabledBorder: OutlineInputBorder(
            //           borderRadius: BorderRadius.all(
            //             Radius.circular(12),
            //           ),
            //           borderSide: BorderSide(
            //             color: MediaQuery.platformBrightnessOf(context) ==
            //                     Brightness.dark
            //                 ? Colors.white
            //                 : Colors.black,
            //           )),
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.all(Radius.circular(12)),
            //       ),
            //     ),
            //   ),
            // ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () {
                  conversationController.isRefreshing.value = true;
                  conversationController.page = 0;
                  conversationController.isLastPage = false;
                  return conversationController.search();
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels ==
                        notification.metrics.maxScrollExtent) {
                      !conversationController.isLoading.value &&!conversationController.isFetching.value
                          ? conversationController.search()
                          : null;
                    }
                    return false;
                  },
                  child: Obx(() {
                    if (conversationController.isLoading.value &&
                        !conversationController.isRefreshing.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (conversationController.results.isEmpty) {
                      return const Center(
                          child: Text("No conevrsations found"));
                    }
                    return ListView.builder(
                      itemCount: conversationController.results.length,
                      itemBuilder: (context, index) {
                        final user = conversationController.results[index];

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
                                            fit: BoxFit.cover,
                                            width: 36,
                                            height: 36,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.account_circle,
                                                size: 36,
                                                color: Colors.grey,
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.account_circle,
                                            size: 36,
                                            color: Colors.grey,
                                          )
                                    : (user.icon != null &&
                                            user.icon?.isNotEmpty == true)
                                        ? Image.network(
                                            user.icon ?? "",
                                            fit: BoxFit.cover,
                                            width: 36,
                                            height: 36,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.group,
                                                size: 36,
                                                color: Colors.grey,
                                              );
                                            },
                                          )
                                        : Icon(
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
                                            (user.status.value == "online");
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
                                color:
                                    MediaQuery.platformBrightnessOf(context) ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              )),
                          subtitle: Obx(() => user.isTyping.value
                              ? Text(
                                  "Typing...",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : (user.unreadCount.value) > 0
                                  ? Text(
                                      "${user.unreadCount?.value} new messages ${formatDate(DateTime.fromMillisecondsSinceEpoch(conversationController.lastMessageList[index].createdAt ?? 0))}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : conversationController
                                              .lastMessageList[index]
                                              .message
                                              ?.isNotEmpty ==
                                          true
                                      ? chatConfigController.config.prefs
                                                  .getInt(chatConfigController
                                                      .config.id)
                                                  .toString() !=
                                              conversationController
                                                  .lastMessageList[index]
                                                  .senderUUID
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    conversationController
                                                            .lastMessageList[
                                                                index]
                                                            .message ??
                                                        "",
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  formatDate(DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                          conversationController
                                                                  .lastMessageList[
                                                                      index]
                                                                  .createdAt ??
                                                              0)),
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              "Sent ${formatDate(DateTime.fromMillisecondsSinceEpoch(conversationController.lastMessageList[index].createdAt ?? 0))}",
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                      : const SizedBox.shrink()),
                          onTap: () {
                            chatConfigController.config.prefs.setInt(
                                chatConfigController.config.conversationId,
                                user.id ?? 0);
                            Get.delete<PingWebSocketService>(force: true);
                            Get.put(PingWebSocketService()).connect();
                            user.type == "PRIVATE_CHAT"
                                ? Get.toNamed(ChatAppRoutes.chat, arguments: {
                                    "name": user.peerUser?.username,
                                    // "description":user
                                    "icon": user.peerUser?.profilePicture ?? "",
                                    "id": user.peerUser?.id,

                                    "conversationId": user.id,
                                    "status": user.status
                                  })?.then((_) {
                                    // This runs AFTER you come back from Chat
                                    conversationController.page = 0;
                                    conversationController.isLastPage = false;
                                    Get.put(SubscribeWebSocketService(conversationController));
                                    conversationController.search();
                                  })
                                : Get.toNamed(ChatAppRoutes.groupChatScreen,
                                    arguments: {
                                        "name": user.groupName,
                                        "icon": user.icon,
                                        // "description":user

                                        "conversationId": user.id,
                                        "status": user.status
                                      })?.then((_) {
                                    // This runs AFTER you come back from Chat
                                    conversationController.page = 0;
                                    conversationController.isLastPage = false;
                                    Get.put(SubscribeWebSocketService(conversationController));
                                    conversationController.search();
                                  });
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
