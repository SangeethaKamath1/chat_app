import 'package:chat_app/constants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/custom_dialoue.dart';
import '../src/theme/controller/chat_theme_controller.dart';
import 'controller/view_members_controller.dart';

class ViewMembersScreen extends StatelessWidget {
  const ViewMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ViewMembersController>();
    controller.memberPageNumber=0;
controller.viewMembers();
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Members"),
        backgroundColor: chatConfigController.config.primaryColor,
        actions: [
          TextButton(
            onPressed: () {},
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
              if (controller.isLoadingMembers.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.groupMembers.isEmpty) {
                return const Center(child: Text("No users found"));
              }

              return ListView.builder(
                itemCount: controller.groupMembers.length,
                itemBuilder: (context, index) {
                  final user = controller.groupMembers[index];
                 // debugPrint("member id:${controller.groupMembers[4].id},${chatConfigController.config.prefs.getString(constant.userId)}");

                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.username ?? ""),
                    subtitle: user.isOwner == true
                        ? const Text(
                            "Group Owner",
                            style: TextStyle(color: Colors.grey),
                          )
                        : null,
                    trailing:int.parse(chatConfigController.config.prefs.getString(chatConfigController.config.constant.userId)??"")==user.id ||user.isOwner==true
                        ? const SizedBox.shrink()
                        :controller.currentUserDetails.value.isAdmin==true||controller.currentUserDetails.value.isOwner==true?
                      PopupMenuButton<String>(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'remove') {
                                    Get.dialog(
                                      CustomAlertDialogue(
                                        titleText:
                                            "Are you sure you want to remove this member?",
                                        successText: 'Remove',
                                        onRemoveClicked: () {
                                          controller.removeMember(user.id ?? 0);
                                        },
                                      ),
                                    );
                                  } else if (value == 'promote') {
                                    Get.dialog(
                                      CustomAlertDialogue(
                                        titleText:
                                            "Promote ${user.username ?? 'this member'} to admin?",
                                        successText: 'Promote',
                                        onRemoveClicked: () {
                                           controller.promoteToAdmin(index,user.id??0,true);
                                        },
                                      ),
                                    );
                                  }else if(value =="demote"){
                                    Get.dialog(
                                      CustomAlertDialogue(
                                        titleText:
                                            "Demote ${user.username ?? 'this member'}?",
                                        successText: 'demote',
                                        onRemoveClicked: () {
                                           controller.promoteToAdmin(index,user.id??0,false);
                                        },
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [

                                  
      PopupMenuItem<String>(
        value: user.isAdmin == false ? 'promote' : 'demote',
        child: Row(
          children: [
            Icon(
              user.isAdmin == false ? Icons.upgrade : Icons.arrow_downward_sharp,
              color: Colors.blueAccent,
            ),
            const SizedBox(width: 8),
            Text(user.isAdmin == false ? "Promote to Admin" : "Demote"),
          ],
        ),
      ),
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_remove,
                                            color: Colors.redAccent),
                                        SizedBox(width: 8),
                                        Text("Remove"),
                                      ],
                                    ),
                                  ),
                              // PopupMenuItem(
                              //       value:  user.isAdmin==false?'promote':"demote",
                              //       child: Row(
                              //         children: [
                              //           Icon(user.isAdmin==false?Icons.upgrade:Icons.arrow_downward_sharp,
                              //               color: chatConfigController.theme.primaryColorAccent),
                              //           SizedBox(width: 8),
                              //           Text(user.isAdmin==false?"Promote to Admin":"Demote"),
                              //         ],
                              //       ),
                              //     ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              )
                         
                        :const SizedBox.shrink(),
                    onTap: () {},
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
