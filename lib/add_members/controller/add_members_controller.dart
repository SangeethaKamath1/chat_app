import 'dart:async';
import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/model/group_member.dart';
import 'package:chat_app/service/shared_preference.dart';
import 'package:chat_app/view_members/controller/view_members_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';


import '../../group/group_detail/repository/group_detail_repository.dart';
import '../../search/repository/search_repository.dart';

class AddMembersController extends GetxController {
  final searchController = TextEditingController();
  final isLoading = false.obs;
   final RxList<Member> results = <Member>[].obs; // Replace with your User model later
  final selectedUsers = <Member>[].obs;
  final tempUsers = <Member>[].obs;
  Timer? debounce;
   bool isLastPage =false;
     int page=0;
     bool fromCreateGroup = false;
    
     

  @override
  void onInit()   {
      if(Get.arguments!=null &&Get.arguments['fromCreateGroup']!=null){
fromCreateGroup=Get.arguments['fromCreateGroup'];
debugPrint("from create group inside the controller:$fromCreateGroup");
    }
   
    super.onInit();
     }
   @override
  void onReady() async {

    // Handle async operations here
   final ViewMembersController viewMembersController = Get.find<ViewMembersController>();
    viewMembersController.memberPageNumber = 0;

    final members = await viewMembersController.viewMembers();
    for(var ele in members) {
      selectedUsers.add(ele);
      tempUsers.add(ele);
    }
    
    await searchUsers();
    
    super.onReady();
  }

  Future<void> addMembers()async{
    Get.back();
     Get.back();
    List<int> users = [];
    selectedUsers.assignAll(tempUsers);
    for(var ele in selectedUsers){
      users.add(ele.id??0);
    }
    await GroupDetailRepository.addMembers(SharedPreference().getInt(AppConstant.conversationId)??0, users).then((response){
      if(response.message==ResponseMessage.memberAddSuccess){
        Fluttertoast.showToast(msg:"Member added successfully");
        tempUsers.assignAll(selectedUsers);
        tempUsers.refresh();
          
      }
    });

  }



  void onSearchTextChanged(String query) {
    if (debounce?.isActive ?? false) debounce!.cancel();

    debounce = Timer(const Duration(milliseconds: 400), () {
      searchUsers();
    });
  }

  Future<void> searchUsers() async {
     if (isLastPage) {
     
      return;
    }

    try {
      isLoading.value = true;

await SearchRepository.searchUser(searchController.text, page.toString()).then((response){
          if(response.content?.isNotEmpty==true){
            if(page ==0){
              results.clear();
  results.addAll(response.content??[]) ;
            }else{
               results.assignAll(response.content??[]) ;
            }
         if(response.last==true){
          isLastPage=true;
         }else{
          page++;
         }
          }
      });
      
    } on DioException catch (e) {
      results.clear();
      debugPrint("❌ Search error: ${e.message}");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleUser(Member user) {
    if (tempUsers.contains(user)) {
      tempUsers.remove(user);
     
      
       
    } else {
      tempUsers.add(user);
       
     
     
    }
  }
  void removeMember(Member user){
    tempUsers.remove(user);
  }

  void finishSelection() {
    selectedUsers.assignAll(tempUsers);
    Get.back(result: selectedUsers.toList());
  }
}