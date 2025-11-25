import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../src/theme/controller/chat_theme_controller.dart';
import 'controller/add_members_controller.dart';

class AddMembersScreen extends StatelessWidget {
  const AddMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddMembersController controller =  Get.find<AddMembersController>();
    controller.onInit();
   

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Members"),
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
              decoration: const InputDecoration(
                hintText: "Search users...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
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
                itemBuilder: (context, index) {
                  final user = controller.results[index];
                 
                     

                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.username??""),
                    subtitle: controller.selectedUsers.contains(user)?
                    Text("Aleady added to the goup"):const SizedBox.shrink()
                    ,
                    trailing: Obx(
                     () {
                        return controller.selectedUsers.contains(user)?const SizedBox.shrink():
                        Checkbox(
                          value: controller.tempUsers.contains(user),
                          onChanged: (_) => controller.toggleUser(user),
                        );
                      }
                    ),
                    onTap: () => controller.toggleUser(user),
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