import 'package:chat_app/chat_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CallEventChannel {
  static const _channel = MethodChannel('call_events');

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'call_action') {
        debugPrint("call action is received:${call}");
        final action = call.arguments['action'];
        final callId = call.arguments['callId'];

        if (action == 'accept') {
           Get.delete<PingWebSocketService>(force: true);
                            Get.put(PingWebSocketService()).connect();
                            final ChatController chatController =  Get.isRegistered<ChatController>()?
        Get.find<ChatController>():Get.put(ChatController());
        //chatController.userId = data['sender'];
        debugPrint("user id ping socket:${chatController.userId}");
        chatController.createConversation();
       // final roomId = data["callID"];
      //final callerName = data["senderUsername"] ?? "Unknown";
    //   debugPrint("📞 Incoming call from $callerName - Room: $roomId");
    // final webRTCService = Get.find<WebRTCService>();
   
    //    chatController.chatWebSocket!.callAccepted(roomId);
    //                   webRTCService.speakerphoneService.stopRingtone();
    //                   chatController.roomId =roomId;
    //                   chatController.callStatus.value = "Connecting...";

                      // ✅ FIX: Only navigate to call screen
                      // The WebRTC answer will be created when we receive the offer
                      Get.offNamed(ChatAppRoutes.callScreen);
        } else {
           Get.delete<PingWebSocketService>(force: true);
                            Get.put(PingWebSocketService()).connect();
                            final ChatController chatController = Get.isRegistered<ChatController>()?
        Get.find<ChatController>():Get.put(ChatController());
         debugPrint("user id ping socket:${chatController.userId}");
        chatController.createConversation();
        final webRTCService = Get.find<WebRTCService>();
        // chatController.chatWebSocket!.callRejected(widget.roomId);
                       webRTCService.speakerphoneService.stopRingtone();
        }
      }
    });
  }
}