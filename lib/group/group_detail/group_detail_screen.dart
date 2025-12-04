import 'package:chat_app/constants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../chat_app.dart';
import '../../routes/chat_app_routes.dart';
import 'controller/group_detail_controller.dart';

class GroupDetailScreen extends StatelessWidget {
  GroupDetailScreen({super.key});

  final GroupDetailController controller = Get.find<GroupDetailController>();

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: (){
            Get.back();
          },
          child: Icon(Icons.arrow_back,color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,
                      ),
        )
,
        title: const Text("Group Details"),
        centerTitle: true,
        actions: [
          Obx(() {
            final isAdmin =
                controller.currentUser.value.isAdmin == true ||
                    controller.currentUser.value.isOwner == true;

            if (!isAdmin) return const SizedBox.shrink();

            return Obx(() {
              return controller.isEditing.value
                  ? IconButton(
                      icon: Icon(
                        Icons.check,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        if (controller.nameController.text.trim().isNotEmpty) {
                          controller.saveGroupDetails();
                        } else {
                          Fluttertoast.showToast(
                              msg: "Please enter the group name");
                        }
                      },
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        controller.isEditing.value = true;
                      },
                    );
            });
          })
        ],
      ),

      // Main Body
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // -------------------------
              // GROUP ICON SECTION
              // -------------------------
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (controller.isEditing.value) {
                        controller.pickGroupIcon();
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey[300],
                         backgroundImage: controller.groupIcon.value != null
      ? FileImage(controller.groupIcon.value!)
      // Step 2: otherwise use network image if available
      : (controller.groupImage.isNotEmpty
          ? NetworkImage(controller.groupImage)
          : null),

  // Step 3: show default icon if no image exists
  child: controller.groupIcon.value == null && controller.groupImage.isEmpty
      ? Icon(
          Icons.group,
          color: chatConfigController.config.primaryColor,
          size: 40,
        )
      : null,
                        ),

                        if (controller.isEditing.value)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.6),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // -------------------------
                  // GROUP NAME
                  // -------------------------
                 Obx(() {
  final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  if (controller.isEditing.value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller.nameController,
        textAlign: TextAlign.center,
        autofocus: true,
        style: TextStyle(color: isDark ?Colors.white:Colors.black),
        decoration: InputDecoration(
          hintText: "Enter the group name",
          hintStyle: TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,
                    ),
          border: InputBorder.none,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? Colors.white70 : Colors.black87,
              width: 1.2,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: chatConfigController.config.primaryColor,
              width: 1.8,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
      ),
    );
  }

  // 🔹 Read Mode
  return Text(
    controller.nameController.text.isNotEmpty
        ? controller.nameController.text
        : "Enter the group name",
   style: TextStyle(color: isDark ?Colors.white:Colors.black),
    textAlign: TextAlign.center,
  );
}),


                  const SizedBox(height: 10),

                  // -------------------------
                  // GROUP DESCRIPTION
                  // -------------------------
                Obx(() {
  final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  if (controller.isEditing.value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller.descriptionController,
        textAlign: TextAlign.center,
        maxLines: null,
        minLines: 2,
        
       style: TextStyle(color: isDark ?Colors.white:Colors.black),
        decoration: InputDecoration(
          hintText: "Enter the description",
          hintStyle: TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,
                    ),
          filled: false,
          
          border: InputBorder.none,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? Colors.white70 : Colors.black87,
              width: 1.0,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: chatConfigController.config.primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 View Mode
  final text = controller.descriptionController.text.trim();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Text(
      text.isNotEmpty ? text : "Enter the description",
       style: TextStyle(color: isDark ?Colors.white:Colors.black),
      textAlign: TextAlign.center,
    ),
  );
}),

                ],
              ),

              // -------------------------
              // OPTIONS LIST
              // -------------------------
              const SizedBox(height: 24),
              const Divider(),

              _OptionTile(
                icon: Icons.people_outline,
                title: "View Members",
                subtitle: "See all group members",
                onTap: () => Get.toNamed(ChatAppRoutes.viewMembers),
              ),

              // Only admin/owner can add members
              if (controller.currentUser.value.isAdmin == true ||
                  controller.currentUser.value.isOwner == true)
                _OptionTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: "Add Members",
                  subtitle: "Invite people to this group",
                  onTap: () => Get.toNamed(ChatAppRoutes.chatAddMembers),
                ),

              _OptionTile(
                icon: Icons.exit_to_app_outlined,
                title: "Exit Group",
                subtitle: "Leave this group",
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
                    },
                  );
                },
              ),

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
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor:
            (iconColor ?? Colors.grey).withOpacity(0.1),
        child: Icon(
          icon,
          color: iconColor ?? chatConfigController.config.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }
}
