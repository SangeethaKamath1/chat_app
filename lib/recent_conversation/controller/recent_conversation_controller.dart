import 'dart:async';
import 'package:chat_app/recent_conversation/repository/recent_conversation_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../chat/chat_websocket/chat_web_socket_service.dart';
import '../../chat/chat_websocket/subscribe_web_socket.dart';
import '../../model/recent_conversation.dart';

class RecentConversationController extends FullLifeCycleController
    with FullLifeCycleMixin {
  final TextEditingController searchController = TextEditingController();
  final RxList<Item> results = <Item>[].obs;
  RxBool isLoading = false.obs;
  bool isLastPage = false;
  SubscribeWebSocketService conversationService =
      Get.put(SubscribeWebSocketService());

  int page = 0;
  Timer? debounce;

  @override
  onInit() {
    search();
    super.onInit();
  }

  @override
  void onResumed() {
   Get.delete<SubscribeWebSocketService>();
    conversationService = Get.put(SubscribeWebSocketService());
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
    if (isLastPage) {
      return;
    }

    try {
      isLoading.value = true;

      RecentConversationRepository.recentConversationList(
              searchController.text, page)
          .then((response) {
        if (response.items.isNotEmpty == true) {
          if (page == 0) {
            results.clear();

            for (var item in response.items) {
              if (
                  item.peerUser?.id != null &&
                  conversationService.userStatus
                      .containsKey(item.peerUser?.id)) {
                item.status.value =
                    conversationService.userStatus[item.peerUser?.id]!;
              }
              results.add(item);
              item.type == "PRIVATE_CHAT" ?
              conversationService
                  .subscribe(item.id ?? 0, item.peerUser?.id ?? 0, item):null;
            }
            // for (var item in results) {
            //   if (item.type == "PRIVATE_CHAT") {
            //     conversationService
            //         .subscribe(item.id ?? 0, item.peerUser?.id ?? 0, item);
            //   }
            // }
          } else {
            //  results.assignAll(response.items??[]);
            for (var item in response.items) {
              if (item.peerUser?.id != null &&
                  conversationService.userStatus
                      .containsKey(item.peerUser?.id)) {
                item.status.value =
                    conversationService.userStatus[item.peerUser?.id]!;
              }
              results.assign(item);
             item.type == "PRIVATE_CHAT" ?
             conversationService
                  .subscribe(item.id ?? 0, item.peerUser?.id ?? 0, item):null;
            }
          }
          if (response.isLastPage == true) {
            isLastPage = true;
          } else {
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

  void onSearchTextChanged(String query) {
    if (debounce?.isActive ?? false) {
      debounce!.cancel();
    } else {
      debounce = Timer(const Duration(milliseconds: 500), () {
        search();
      });
    }

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
