import 'dart:async';

import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/group/group_detail/repository/group_detail_repository.dart';
import 'package:chat_app/model/group_member.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../chat_app.dart';
import '../../model/user.dart';


class ViewMembersController extends FullLifeCycleController with FullLifeCycleMixin{

  final searchController = TextEditingController();
  final isLoading = false.obs;
final  Rx<User> currentUserDetails=User().obs;
   final RxList<Member> results = <Member>[].obs; // Replace with your User model later

  Timer? debounce;
  RxList<Member> groupMembers = <Member>[].obs;
   bool isLastPage =false;
     int page=0;

      bool isMembersLastPage =false;
      RxBool isLoadingMembers=false.obs;
      int memberPageNumber =0;
      

  @override
  void onInit() {
   

    
   // viewMembers();
    super.onInit();


    // Load preselected users from arguments
    // final args = Get.arguments as Map<String, dynamic>?;
    // if (args?["selected"] != null) {
    //   selectedUsers.assignAll(args!["selected"] as List<String>);
    // }
  }
  Future<List<Member>> viewMembers() async {
  if (isLoadingMembers.value) return [];

  try {
    isLoadingMembers.value = true;

    if (memberPageNumber == 0) {
      groupMembers.clear();
      isMembersLastPage = false;
    }

    if (isMembersLastPage) {
      isLoadingMembers.value = false;
      return [];
    }

    final conversationId =
        chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId) ?? 0;

    final response = await GroupDetailRepository.viewMembers(
      searchController.text,
      conversationId,
      memberPageNumber,
    );

    currentUserDetails.value = response.groupDetails?.currentUser ?? User();

    final items = response.members?.items ?? [];

    groupMembers.addAll(items);

    final totalPages = response.members?.totalPages ?? 1;

    if (memberPageNumber >= totalPages - 1) {
      isMembersLastPage = true;
    } else {
      memberPageNumber++;
    }

    isLoadingMembers.value = false;
    return groupMembers;

  } catch (e) {
    isLoadingMembers.value = false;
    debugPrint("something went wrong: $e");
    return [];
  }
}

Future<void> promoteToAdmin(int index,int memberId,bool isAdmin)async{
  try{
    await GroupDetailRepository.memberPromote(chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId)??0,memberId, isAdmin).then((response){
        Fluttertoast.showToast(msg: response.message??"");
       groupMembers[index].isAdmin.value=!groupMembers[index].isAdmin.value;
    });
  }catch(e){
    debugPrint("promote member error:$e");
  }
}


void onSearchTextChanged(String query) {
  if (debounce?.isActive ?? false) debounce!.cancel();

  debounce = Timer(const Duration(milliseconds: 400), () {

    // IMPORTANT FIXES:
    memberPageNumber = 0;
    isMembersLastPage = false;
    groupMembers.clear();

    viewMembers();
  });
}


  Future<void> removeMember(int memberId)async{
    try{
await GroupDetailRepository.removeMember(chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId)??0, memberId).then((response){
  if(response.message==ResponseMessage.removeMemberSuccess){
Fluttertoast.showToast(msg:"member removed successfully");
groupMembers.removeWhere((ele)=>ele.id==memberId);
groupMembers.refresh();
Get.back();
// Get.back();
  }
});
    }catch(e){
      debugPrint("error:$e");

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