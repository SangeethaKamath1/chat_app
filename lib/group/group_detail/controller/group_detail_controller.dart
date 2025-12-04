import 'dart:io';

import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/group/group_detail/repository/group_detail_repository.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../chat_app.dart';
import '../../../model/user.dart';

class GroupDetailController extends FullLifeCycleController with FullLifeCycleMixin {
  //String groupName ="";
  RxBool isEditing =false.obs;
  //  RxString groupDescription = "".obs;
  //  RxString groupName="".obs;
  TextEditingController descriptionController = TextEditingController();
    TextEditingController nameController = TextEditingController();
 Rx<User> currentUser=User().obs;
  String groupImage = "";
  final groupIcon = Rx<File?>(null);
   final ImagePicker picker = ImagePicker();
  @override
  void onInit() {
    // TODO: implement onInit
   
   nameController.text=Get.arguments['groupName'];
   groupImage = Get.arguments['icon'];
   descriptionController.text = Get.arguments['description'];
    debugPrint("convo id:${chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId)??0}");
  getGroupDetails();
    super.onInit();
  }

  Future<void> getGroupDetails()async{
    isEditing.value=false;
    try{
      await GroupDetailRepository.groupDetails(chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId)??0).then((response){
        if(response.id!=null){                   
          currentUser.value=response.currentUser??User();
          descriptionController.text=response.description??"";
          groupImage = response.icon??"";
          }
      });
    }catch(e){
      debugPrint("group update error:$e");
    }
  }

  Future<void> saveGroupDetails()async{
    isEditing.value=false;
    try{
      await GroupDetailRepository.groupUpdate(chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId)??0,nameController.value.text, descriptionController.value.text).then((response){
        if(response.message==ResponseMessage.groupUpdateSuccess){
            Fluttertoast.showToast(msg:"group updated successfully");
        }
      });
    }catch(e){
      debugPrint("group update error:$e");
    }
  }
Future<void> pickGroupIcon() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      groupIcon.value = File(picked.path);
      GroupDetailRepository.setGroupIcon(groupIcon.value??File(""), chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId)??0);

    }
  }
Future<void> exitGroup()async{
  try{
    await GroupDetailRepository.exitGroup(chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId)??0).then((response){
debugPrint("group exited successfully");
 Get.back();
  Get.back();
    });
  }catch(e){
    debugPrint("something went wrong");
  }
}
  @override
  void onDetached() {
    // TODO: implement onDetached
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  @override
  void onInactive() {
    // TODO: implement onInactive
  }

  @override
  void onPaused() {
    // TODO: implement onPaused
  }

  @override
  void onResumed() {
    // TODO: implement onResumed
  }
  
}