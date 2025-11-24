
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../chat/chat_websocket/ping_web_socket.dart';
import '../constants/app_constant.dart';
import '../routes/app_routes.dart';
import '../service/shared_preference.dart';
import '../src/theme/controller/chat_theme_controller.dart';
import 'controller/search_controller.dart';


class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});



  @override
  Widget build(BuildContext context) {
     final SearchUserController searchController= Get.find<SearchUserController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search User"),
        backgroundColor: chatThemeController.theme.primaryColor,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification){
          if(notification.metrics.pixels == notification.metrics.maxScrollExtent){
       !searchController.isLoading.value?searchController.search():null;
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
                controller: searchController.searchController,
                onChanged: searchController.onSearchTextChanged,
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
                if (searchController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (searchController.results.isEmpty) {
                  return const Center(child: Text("No users found"));
                }
                return ListView.builder(
                  itemCount: searchController.results.length,
                  itemBuilder: (context, index) {
                    final user = searchController.results[index];
                    if(index==0){
                      debugPrint("user id:${user.id}");
                      }
                    return ListTile(
                      leading:  Icon(Icons.person, color: chatThemeController.theme.primaryColor),
                      title: Text(user.username??""),
                      onTap: () {
                        SharedPreference().setInt(AppConstant.conversationId, user.conversationId??0);
                       Get.delete<PingWebSocketService>(force: true);
   Get.put(PingWebSocketService()).connect();
                       Get.toNamed(AppRoutes.chat,
                       arguments: {
                        "id":user.id,
                        "name":user.username,
                        "conversationId":user.conversationId ?? ""
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
