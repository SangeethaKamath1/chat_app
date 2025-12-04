import 'package:chat_app/chat_app.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../routes/chat_app_routes.dart';
import '../../src/theme/controller/chat_theme_controller.dart';
import 'controller/create_group_controller.dart';

class CreateGroupScreen extends StatelessWidget {
  CreateGroupScreen({super.key});
  final CreateGroupController controller =
      Get.isRegistered<CreateGroupController>()
          ? Get.find<CreateGroupController>()
          : Get.put(CreateGroupController());
  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.white70 : Colors.grey;
    final borderColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text("Create Group",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        backgroundColor: chatConfigController.config.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Group Icon
                Center(
                  child: GestureDetector(
                    onTap: controller.pickGroupIcon,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: controller.groupIcon.value != null
                          ? FileImage(controller.groupIcon.value!)
                          : null,
                      child: controller.groupIcon.value == null
                          ? const Icon(Icons.camera_alt,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// Group Name
                TextField(
                  controller: controller.groupNameController,
                  style: TextStyle(
                      color: primaryTextColor), // ← text color adjusts
                  cursorColor: primaryTextColor,

                  decoration: InputDecoration(
                    labelText: "Group Name",
                    labelStyle: TextStyle(color: labelColor),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor), // ← no green
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: borderColor, width: 2), // ← stays white/black
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// Description
                TextField(
                  controller: controller.descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: primaryTextColor),
                  cursorColor: primaryTextColor,
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(color: labelColor),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// Add Members
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Add Members",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () async {
                        final selected = await Get.toNamed(
                            ChatAppRoutes.chatAddMembers,
                            arguments: {
                              "selected": controller.members.toList(),
                              "fromCreateGroup": true
                            });
                        if (selected != null && selected is List<String>) {
                          controller.members.assignAll(selected);
                        }
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text("Add"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                /// Members List
                Obx(
                  () {
                    return Wrap(
                      spacing: 8,
                      children: controller.membersController.selectedUsers
                          .map((m) => Chip(
                                label: Text(m.username ?? ""),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: () =>
                                    controller.membersController.removeMember(m),
                              ))
                          .toList(),
                    );
                  }
                ),
                const SizedBox(height: 24),

                /// Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.isCreating.value
                          ? null
                          : controller.groupNameController.value.text
                                  .trim()
                                  .isEmpty
                              ? Fluttertoast.showToast(
                                  msg: "Please Enter the group name")
                              : controller.createGroup();
                    },
                    icon: controller.isCreating.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: Text(controller.isCreating.value
                        ? "Creating..."
                        : "Create Group"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: chatConfigController.config.primaryColor,
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
