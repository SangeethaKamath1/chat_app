import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/service/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import 'controller/group_detail_controller.dart';

class GroupDetailScreen extends StatelessWidget {
   GroupDetailScreen({super.key});
 final GroupDetailController controller = Get.find<GroupDetailController>();
  @override
  Widget build(BuildContext context) {
    debugPrint("user id:${SharedPreference().getString(AppConstant.userId)}");
   

    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Details"),
        centerTitle: true,
     actions: [
        Obx(
        () {
            return controller.currentUser.value.isAdmin==true || controller.currentUser.value.isOwner ==true?    Obx(() => controller.isEditing.value 
                  ? IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                      controller.nameController.text.trim().isNotEmpty? controller.saveGroupDetails():Fluttertoast.showToast(msg: "Please Enter the group Name");
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        controller.isEditing.value = true;
                      },
                    )):const SizedBox.shrink();
          }
        ),
        ]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          return Column(
            children: [
              // 🟢 Group Header Section
              Column(
                children: [
              GestureDetector(
                    onTap:(){
      controller.isEditing.value?controller.pickGroupIcon():null;
                    } ,
                    child:
                    
                      CircleAvatar(
                      radius: 45,
                       backgroundImage: controller.groupIcon.value != null
                      ? FileImage(controller.groupIcon.value!)
                      : null,
                      
                      child: Icon(Icons.camera_alt, size: 28, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Group Name (editable or read-only)
                  Obx(
                     () {
                      return controller.isEditing.value
                          ? TextField(
                              controller: controller.nameController,
                              textAlign: TextAlign.center,
                              decoration:  InputDecoration(
                                hintText: "Enter the group name",
                                border: InputBorder.none,
                              ),
                              onChanged: (value){
                                controller.nameController.text=value;
                              },
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            )
                          : Text(
                           controller.nameController.text.isEmpty?"Enter the group name":controller.nameController.text,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            );
                    }
                  ),
                  const SizedBox(height: 6),

                  // Group Description (editable or read-only)
                 Obx(
                    () {
                      return controller.isEditing.value
                          ? TextField(
                              controller: controller.descriptionController,
                              textAlign: TextAlign.center,
                              decoration:  InputDecoration(
                                hintText: "Enter the description",
                                border: InputBorder.none,
                              ),
                              
                            )
                          : Text(
                              controller.descriptionController.text.isNotEmpty
                                  ? controller.descriptionController.text
                                  : "Enter the description",
                              style: Theme.of(context).textTheme.bodyMedium,
                            );
                    }
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),

              // ⚙️ Options Section
              _OptionTile(
                icon: Icons.people_outline,
                title: "View Members",
                subtitle: "See all group members",
                onTap: () => Get.toNamed(AppRoutes.viewMembers),
              ),
           controller.currentUser.value.isAdmin == true||controller.currentUser.value.isOwner==true?   _OptionTile(
                icon: Icons.person_add_alt_1_outlined,
                title: "Add Members",
                subtitle: "Invite people to this group",
                onTap: () => Get.toNamed(AppRoutes.addMembers),
              ):const SizedBox.shrink(),
              _OptionTile(
                icon: Icons.exit_to_app_outlined,
                title: "Exit Group",
                subtitle: "Leave and delete this group permanently",
                iconColor: Colors.red,
                onTap: () {
                  Get.defaultDialog(
                    title: "Exit Group",
                    middleText: "Are you sure you want to exit this group?",
                    textCancel: "Cancel",
                    textConfirm: "Exit",
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    onConfirm: () {
                      controller.exitGroup();

                      Get.back();
                      // controller.exitGroup();
                    },
                  );
                },
              ),
              // _OptionTile(
              //   icon: Icons.flag_outlined,
              //   title: "Report Group",
              //   subtitle: "Report inappropriate content or behavior",
              //   iconColor: Colors.orange,
              //   onTap: () {
              //     // TODO: handle report
              //   },
              // ),

              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor:
            (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
        child: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }
}
