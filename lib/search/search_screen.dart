
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../chat/chat_websocket/ping_web_socket.dart';
import '../routes/chat_app_routes.dart';

import '../src/theme/controller/chat_theme_controller.dart';
import 'controller/search_controller.dart';


class UserSearchScreen extends StatelessWidget {
  const UserSearchScreen({super.key});



  @override
  Widget build(BuildContext context) {
     final SearchUserController searchController= Get.isRegistered<SearchUserController>()?
    Get.find<SearchUserController>():Get.put(SearchUserController());

    return Scaffold(
      appBar: AppBar(
        title:  Text("Search User",style: TextStyle(color:Colors.white,)),
        backgroundColor: chatConfigController.config.primaryColor,
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
                style: TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,),
               decoration:  InputDecoration(
                    hintText: "Search username...",
                    
                    hintStyle: TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,),
                    prefixIcon: Icon(Icons.search,color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12),
                      ),
                      borderSide: BorderSide(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,
                    )
                    ),
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
                      leading:  
                     ClipOval(
                              child: (user.profilePictureUrl != null &&
                                      user.profilePictureUrl?.isNotEmpty == true)
                                  ? Image.network(
                                      user.profilePictureUrl ?? "",
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
                                    ) : Icon(
                                   
                                          Icons.account_circle,
                                          
                                      size: 36,
                                      color: Colors.grey,
                                    ),),
                      title: Text(user.username??"",style:TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,)),
                      onTap: () {
                        //chatConfigController.config.prefs.setInt(chatConfigController.config.conversationId, user.conversationId??0);
                       Get.delete<PingWebSocketService>(force: true);
   Get.put(PingWebSocketService()).connect();
                       Get.toNamed(ChatAppRoutes.chat,
                       arguments: {
                        "id":user.id,
                        "name":user.username,
                        "conversationId":
                       // user.conversationId ?? 
                        ""
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
