import 'dart:io';
import 'package:chat_app/view_members/controller/view_members_controller.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../add_members/controller/add_members_controller.dart';
import '../../../chat_app.dart';
import '../../../constants/app_constant.dart';
import '../../../model/create_group_response.dart';

import '../../repository/group_chat_repository.dart';

class CreateGroupController extends GetxController {
   GroupDetails  groupDetails = GroupDetails();
  final groupNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final members = <String>[].obs; // Example: you can use user IDs or usernames
  final groupIcon = Rx<File?>(null);
  final isCreating = false.obs;
  late final   AddMembersController membersController;
  late final ViewMembersController viewMembersController;

  final ImagePicker picker = ImagePicker();

  @override
  onInit(){
    membersController = Get.isRegistered<AddMembersController>()?Get.find<AddMembersController>():Get.put(AddMembersController());
    viewMembersController=Get.isRegistered<ViewMembersController>()?Get.find<ViewMembersController>():Get.put(ViewMembersController());
    

    super.onInit();
  

  }

  Future<void> pickGroupIcon() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      groupIcon.value = File(picked.path);
    }
  }

  void addMember(String username) {
    if (!members.contains(username)) {
      members.add(username);
    }
  }

  void removeMember(String username) {
    members.remove(username);
  }

   Future<void> createGroup() async {
    isCreating.value =true;
    final List<int> selectedUsers = [];
    selectedUsers.insert(0,int.parse(chatConfigController.config.prefs.getString(constant.userId)??""),);
    for(var ele in membersController.selectedUsers){
      selectedUsers.add(ele.id??0);
    }
   try{
    await GroupChatRepository.createGroup(groupNameController.text, selectedUsers, descriptionController.value.text).then((response){
      groupDetails = response.groupDetails??GroupDetails();
      isCreating.value =false;
     Fluttertoast.showToast(msg: "Group created successfully");
     Get.back();
    });
   }catch(e){
    isCreating.value =false;
    debugPrint("something went wrong:$e");
     Get.back();
   }
  }
}