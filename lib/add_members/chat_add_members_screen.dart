import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/group_member.dart';
import '../src/theme/controller/chat_theme_controller.dart';
import 'controller/chat_add_members_controller.dart';

class ChatAddMembersScreen extends StatelessWidget {
  const ChatAddMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatAddMembersController controller =  Get.find<ChatAddMembersController>();
  
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    controller.onInit();
   

    return Scaffold(
      appBar: AppBar(
        title:  Text("Add Members",style:TextStyle(color:Colors.white,fontSize: 18,fontWeight: FontWeight.w700)),
        backgroundColor: chatConfigController.config.primaryColor,
        actions: [
          TextButton(
            onPressed:(){
              debugPrint("from create group:${controller.fromCreateGroup}");
               controller.fromCreateGroup? controller.finishSelection():controller.addMembers();},
            child: const Text(
              "Done",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
      body: Column(
        children: [
     Padding(
  padding: const EdgeInsets.all(12),
  child: TextField(
    controller: controller.searchController,
    onChanged: controller.onSearchTextChanged,

    style: TextStyle(
      color: isDark ? Colors.white : Colors.black,
    ),

    decoration: InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,

      hintText: "Search users...",
      hintStyle: TextStyle(
        color: isDark ? Colors.white60 : Colors.black54,
      ),

      prefixIcon: Icon(
        Icons.search,
        color: isDark ? Colors.white70 : Colors.black54,
      ),

      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: chatConfigController.config.primaryColor,
          width: 1.4,
        ),
      ),
    ),
  ),
),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.results.isEmpty) {
                return const Center(child: Text("No users found"));
              }
              return ListView.builder(
                itemCount: controller.results.length,
                controller: controller.scrollController, 
                itemBuilder: (context, index) {
                  final user = controller.results[index];
                 
                     

       return Container(
  color: isDark ? Colors.grey.shade900 : Colors.white, // background
  child: ListTile(
    leading: ClipOval(
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

    title: Text(
      user.username ?? "",
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
    ),

    subtitle: controller.selectedUsers.contains(
            Member(username: user.username, id: user.id))
        ? Text(
            "Already added to the group",
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          )
        : const SizedBox.shrink(),

    trailing: Obx(() {
      return controller.selectedUsers.contains(
              Member(username: user.username, id: user.id))
          ? const SizedBox.shrink()
          : Theme(
  data: Theme.of(context).copyWith(
    checkboxTheme: CheckboxThemeData(
      side: MaterialStateBorderSide.resolveWith(
        (states) =>  BorderSide(color: MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black, width: 2),
      ),
    ),
  ),
            child: Checkbox(
                activeColor: chatConfigController.config.primaryColor,
                checkColor: Colors.white,
                focusColor: MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,
                value: controller.tempUsers.contains(
                  Member(username: user.username, id: user.id),
                ),
                onChanged: (_) => controller.toggleUser(
                  Member(username: user.username, id: user.id),
                ),
              ),
          );
    }),

    onTap: () => controller.toggleUser(
      Member(username: user.username, id: user.id),
    ),
  ),
);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}