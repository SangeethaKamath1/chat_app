import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../repository/chat_info_repository.dart';

class ChatInfoController extends GetxController{
  String useruid= "";
  RxBool isBlocked = false.obs;
  RxBool isBlockedBy=false.obs;
    RxBool isMuted = false.obs;

  @override
  void onInit(){
    debugPrint("user id inside chat info:${Get.arguments["useruid"]}");
      useruid = Get.arguments["useruid"];
      isBlocked.value = Get.arguments['isBlocked'];
      isBlockedBy.value = Get.arguments['isBlockedBy'];
      isMuted.value = Get.arguments["isMuted"];

      super.onInit();
  }
  Future<void> bloackUser()async{
    final response= await ChatInfoRepository.blockUser(blockUuid: useruid);
    if(response == "User blocked successfully"){
      isBlocked.value =true;
    }
    debugPrint("block user response:${response}");

  }
    Future<void> unblockUser()async{
    final response= await ChatInfoRepository.unblockUser(blockUuid: useruid);
    debugPrint("unblock response:${response}");
    if(response == "User unblocked successfully"){
      isBlocked.value =false;
    }
    debugPrint("block user response:${response}");

  }
   Future<void> muteUser()async{
    final response= await ChatInfoRepository.muteUser(targetedUserId: useruid);
    debugPrint("mute user response:${response}");
    if(response == "User muted successfully"){
      isMuted.value =false;
    }
    debugPrint("mute user response:${response}");

  }
  Future<void> unmuteUser()async{
    final response= await ChatInfoRepository.unmuteUser(targetedUserId: useruid);
    debugPrint("User unmuted response:${response}");
    if(response == "User unmuted successfully"){
      isMuted.value =false;
    }
    debugPrint("unmute user response:${response}");

  }
}