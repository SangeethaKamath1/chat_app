import 'package:chat_app/chat/chat_websocket/ping_web_socket.dart';
import 'package:chat_app/chat/chat_websocket/subscribe_web_socket.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../add_members/controller/add_members_controller.dart';
import '../chat/chat_websocket/chat_web_socket_service.dart';
import '../constants/app_constant.dart';
import '../routes/app_routes.dart';
import '../service/shared_preference.dart';
import 'controller/recent_conversation_controller.dart';

class RecentConversationScreen extends StatelessWidget {
  const RecentConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RecentConversationController conversationController =
        Get.find<RecentConversationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversations"),
        leading: InkWell(
            onTap: () {
               SharedPreference().setInt(AppConstant.conversationId, 0);
              Get.toNamed(AppRoutes.createGroup)?.then((_) {
                conversationController.page = 0;
                conversationController.isLastPage = false;
                Get.put(SubscribeWebSocketService());
                conversationController.search();
              });
            },
            child: Icon(Icons.group_add)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        actions: [
          InkWell(
            onTap: () {
              Get.delete<PingWebSocketService>(force: true);
              Get.put(PingWebSocketService()).connect();
              Get.toNamed(AppRoutes.search)?.then((_) {
                // This runs AFTER you come back from Chat
                conversationController.page = 0;
                conversationController.isLastPage = false;
                Get.put(SubscribeWebSocketService());
                conversationController.search();
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(Icons.search),
            ),
          )
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels ==
              notification.metrics.maxScrollExtent) {
            !conversationController.isLoading.value
                ? conversationController.search()
                : null;
            return true;
          }
          return false;
        },
        child: Column(
          children: [
            /// Search field
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: conversationController.searchController,
                onChanged: conversationController.onSearchTextChanged,
                decoration: const InputDecoration(
                  hintText: "Search username...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ),

            /// Results
            Expanded(
              child: Obx(() {
                if (conversationController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (conversationController.results.isEmpty) {
                  return const Center(child: Text("No users found"));
                }
                return ListView.builder(
                  itemCount: conversationController.results.length,
                  itemBuilder: (context, index) {
                    final user = conversationController.results[index];

                    return ListTile(
                      leading: Stack(
                        children: [
                          const Icon(Icons.person,
                              color: Colors.blue, size: 40),
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
                      title: Text(user.owner != null
                          ? user.groupName ?? ""
                          : user.peerUser?.username ?? ""),
                      subtitle: Obx(() => user.isTyping.value
                          ? Text(
                              "Typing...",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const SizedBox.shrink()),
                      onTap: () {
                        SharedPreference()
                            .setInt(AppConstant.conversationId, user.id ?? 0);
                        Get.delete<PingWebSocketService>(force: true);
                        Get.put(PingWebSocketService()).connect();
                        user.type == "PRIVATE_CHAT"
                            ? Get.toNamed(AppRoutes.chat, arguments: {
                                "name": user.peerUser?.username,
                                // "description":user
                                "id": user.peerUser?.id,
                                "conversationId": user.id,
                                "status": user.status
                              })?.then((_) {
                                // This runs AFTER you come back from Chat
                                conversationController.page = 0;
                                conversationController.isLastPage = false;
                                Get.put(SubscribeWebSocketService());
                                conversationController.search();
                              })
                            : Get.toNamed(AppRoutes.groupChatScreen,
                                arguments: {
                                    "name": user.groupName,
                                    // "description":user

                                    "conversationId": user.id,
                                    "status": user.status
                                  })?.then((_) {
                                // This runs AFTER you come back from Chat
                                conversationController.page = 0;
                                conversationController.isLastPage = false;
                                Get.put(SubscribeWebSocketService());
                                conversationController.search();
                              });
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
