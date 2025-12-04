import 'dart:async';
import 'package:chat_app/helpers.dart';
import 'package:chat_app/recent_conversation/repository/recent_conversation_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../chat/chat_websocket/chat_web_socket_service.dart';
import '../../chat/chat_websocket/subscribe_web_socket.dart';
import '../../chat/helpers/encryption_helper.dart';
import '../../model/recent_conversation.dart';

class RecentConversationController extends FullLifeCycleController
    with FullLifeCycleMixin {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode(); 
  final RxBool isRefreshing =false.obs;
  final RxList<Item> results = <Item>[].obs;
  final List<LastMessage> lastMessageList = <LastMessage>[].obs;
  RxBool isLoading = false.obs;
  bool isLastPage = false;
late   SubscribeWebSocketService conversationService ;
     

  int page = 0;
  Timer? debounce;

  @override
  onInit() {
    
     conversationService = Get.put(SubscribeWebSocketService(this));
    
      search();
       super.onInit();
  }

  @override
  void onResumed() {
   Get.delete<SubscribeWebSocketService>();
    conversationService = Get.put(SubscribeWebSocketService(this));


//   debugPrint("🟢 RecentConversationController resumed — refreshing list");
//   page = 0;
//   isLastPage = false;
//      conversationService = Get.put(SubscribeWebSocketService());
   search();
  }

//   @override
//   onClose(){
// conversationService.unsubscribeAll();
//   }
  Future<void> search() async {
  debugPrint("user status:${conversationService.userStatus}");
  if (isLastPage || isLoading.value) {  // ✅ Prevent multiple simultaneous calls
    return;
  }

  try {
    isLoading.value = true;

    final response = await RecentConversationRepository.recentConversationList(
        searchController.text, page);  // ✅ Use await instead of .then()

    if (response.items.isNotEmpty == true) {
      if (page == 0) {
        results.clear();
        lastMessageList.clear();

        for (var item in response.items) {
          if (item.peerUser?.id != null &&
              conversationService.userStatus.containsKey(item.peerUser?.id)) {
            item.status.value =
                conversationService.userStatus[item.peerUser?.id]!;
          }
          results.add(item);
          
        lastMessageList.add(LastMessage(message:EncryptionHelper.decryptText(item.lastMessage?.message??""),createdAt: item.lastMessage?.createdAt??0,senderUUID: item.lastMessage?.senderUUID));
      
         
          if (item.type == "PRIVATE_CHAT") {
            conversationService.subscribe(
                item.id ?? 0, item.peerUser?.id ?? 0, item);
          }
        }
      } else {
        for (var item in response.items) {
          if (item.peerUser?.id != null &&
              conversationService.userStatus.containsKey(item.peerUser?.id)) {
            item.status.value =
                conversationService.userStatus[item.peerUser?.id]!;
          }
          results.add(item); 
         
           lastMessageList.add(LastMessage(message:EncryptionHelper.decryptText(item.lastMessage?.message??""),createdAt: item.lastMessage?.createdAt??0,senderUUID: item.lastMessage?.senderUUID)); 
        
          if (item.type == "PRIVATE_CHAT") {
            conversationService.subscribe(
                item.id ?? 0, item.peerUser?.id ?? 0, item);
          }
        }
      }
      
      if (response.isLastPage == true) {
        isLastPage = true;
      } else {
        page++;
      }
    }
  } on DioException catch (e) {
    results.clear();
    debugPrint("❌ Search error: ${e.message}");
  } finally {
    isLoading.value = false; 
    isRefreshing.value=false; // ✅ This now runs after response is received
  }
}

  void onSearchTextChanged(String query) {
  // Cancel existing timer if active
  if (debounce?.isActive ?? false) {
    debounce!.cancel();
  }
  
  // Reset pagination and create new timer
  debounce = Timer(const Duration(milliseconds: 500), () {
    page = 0;
    isLastPage = false;
    search();
  });


    /// Call API to search users
  }

  @override
  void onClose() {
    debugPrint("unsubscribe all called onClose");
    conversationService.unsubscribeAll();
   Get.delete<SubscribeWebSocketService>();
  //Get.delete<RecentConversationController>();
    // TODO: implement onClose
    super.onClose();
    //conversationService.unsubscribeAll();
  }

  @override
  void onDetached() {
    debugPrint("unsubscribe all called onDetached");
    //conversationService.unsubscribeAll();
    // TODO: implement onDetached
  }

  @override
  void onHidden() {
    debugPrint("unsubscribe all called onHidden");
    //conversationService.unsubscribeAll();
    // TODO: implement onHidden
  }

  @override
  void onInactive() {
    // TODO: implement onInactive
  }

  @override
  void onPaused() {
    
  }
}
