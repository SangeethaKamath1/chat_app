import 'dart:async';
import 'package:chat_app/constants/app_constant.dart';
// import 'package:chat_app/model/group_member.dart';

import 'package:chat_app/view_members/controller/view_members_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';


import '../../chat_app.dart';
import '../../group/group_detail/repository/group_detail_repository.dart';
import '../../model/search_model.dart';
import '../../search/repository/search_repository.dart';
import 'package:chat_app/model/group_member.dart';

class ChatAddMembersController extends GetxController {
  final searchController = TextEditingController();
  final isLoading = false.obs;
   final RxList<ChatUsers> results = <ChatUsers>[].obs; // Replace with your User model later
  final selectedUsers = <Member>[].obs;
  final tempUsers = <Member>[].obs;
  Timer? debounce;
   bool isLastPage =false;
     int page=0;
     bool fromCreateGroup = false;
     

  
  bool isFetching = false; // prevents multi-calls
  

  late ScrollController scrollController;
    
     

  @override
  void onInit()   {
      if(Get.arguments!=null &&Get.arguments['fromCreateGroup']!=null){
fromCreateGroup=Get.arguments['fromCreateGroup'];
debugPrint("from create group inside the controller:$fromCreateGroup");
    }
       scrollController = ScrollController();
    scrollController.addListener(_onScroll);
    resetPagination();
     searchUsers();
    super.onInit();
     }
   @override
  void onReady() async {

    // Handle async operations here
   final ViewMembersController viewMembersController = Get.find<ViewMembersController>();
    viewMembersController.memberPageNumber = 0;

    final members = await viewMembersController.viewMembers();
    for(var ele in members) {
      selectedUsers.add(Member(username:ele.username,id: ele.id));
      tempUsers.add(Member(username:ele.username,id: ele.id));
    }

        //resetPagination();
   // await searchUsers();
    
    super.onReady();
  }

    void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isFetching &&
        !isLastPage &&
        !isLoading.value) {
      searchUsers();
    }
  }

  void resetPagination() {
    page = 0;
    isLastPage = false;
    results.clear();
  }

   Future<void> addMembers() async {
    Get.back();
    Get.back();

    List<int> ids = tempUsers.map((e) => e.id ?? 0).toList();

    final response = await GroupDetailRepository.addMembers(
      chatConfigController.config.prefs
          .getInt(chatConfigController.config.conversationId) ??
          0,
      ids,
    );

    if (response.message == ResponseMessage.memberAddSuccess) {
      Fluttertoast.showToast(msg: "Member added successfully");
      selectedUsers.assignAll(tempUsers);
      tempUsers.refresh();
    }
  }




  void onSearchTextChanged(String query) {
    if (debounce?.isActive ?? false) debounce!.cancel();

    debounce = Timer(const Duration(milliseconds: 300), () {
      resetPagination();
      searchUsers();
    });
  }

  Future<void> searchUsers() async {
    if (isLastPage || isFetching) return;

    isFetching = true;
    isLoading.value = true;

    try {
      final response =
          await SearchRepository.searchUser(searchController.text, page.toString());

      final newUsers = response.data?.content ?? [];

      if (newUsers.isEmpty) {
        isLastPage = true;
      } else {
        results.addAll(newUsers);
      }

      if (response.data?.last == true) {
        isLastPage = true;
      } else {
        page++;
      }
    } catch (e) {
      print("Search error: $e");
    } finally {
      isLoading.value = false;
      isFetching = false;
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
    selectedUsers.remove(user);
  }

  void finishSelection() {
    selectedUsers.assignAll(tempUsers);
    Get.back(result: selectedUsers.toList());
  }
}