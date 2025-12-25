import 'dart:convert';
import 'dart:developer';

import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../audio_call/screens/incoming_call_screen.dart';
import '../../chat_app.dart';


class PingWebSocketService extends FullLifeCycleController
    with FullLifeCycleMixin {
   late IOWebSocketChannel channel;
  //  late WebSocketChannel statusCheckChannel;

  void connect() async {
  try {
    debugPrint("fff:${Uri.parse("${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping")}");
    channel = IOWebSocketChannel.connect(
      Uri.parse("${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping"),
    );
    debugPrint("✅ ping WebSocket connection established:${chatConfigController.config.prefs.getString(chatConfigController.config.userId)}");
    debugPrint("connection success:");
    channel.stream.listen((event) async {
        final data = jsonDecode(event);
         log("ping is connected:${data}");
      if(data["connectionStatus"] =="CONNECTED" ){
        debugPrint("ping is connected:${data}");

      }else if(data["type"]=="call"){
         final ChatController chatController = Get.isRegistered<ChatController>()?
        Get.find<ChatController>():Get.put(ChatController());
        chatController.userId = data['sender'];
        debugPrint("user id ping socket:${chatController.userId}");
        chatController.createConversation();
        final roomId = data["callID"];
      final callerName = data["senderUsername"] ?? "Unknown";
       final offerData = data["offer"];
      debugPrint("📞 Incoming call from $callerName - Room: $roomId");
    final webRTCService = Get.find<WebRTCService>();
    await webRTCService.handleOffer(RTCSessionDescription(offerData['sdp'], offerData['type']));
    webRTCService.speakerphoneService.stopRingtone();
      Get.to(() => IncomingCallScreen(
        roomId: roomId,
        callerName: callerName,
      ));

      }

    },
    onDone: (){
         debugPrint("✅ ping WebSocket connection closed onDone");
  
    },
    onError: (e){
      debugPrint("✅ ping WebSocket connection closed onError:$e");
        channel = IOWebSocketChannel.connect(
      Uri.parse("${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping"),
    );
    });
  } catch (e) {
      channel = IOWebSocketChannel.connect(
      Uri.parse("${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping"),
    );

     debugPrint("✅ ping WebSocket connection closed on catch");

  }
}

void sendFcmToken(String token){
  debugPrint("send fcm token called");
  final payload={
    
"type" : "fcmToken",
"fcmToken" : token

  };
    channel?.sink.add(jsonEncode(payload));
debugPrint("fcm token payload :${payload}");
}

// void statusCheck(int conversationId,int userid,Item item) async{
//   try{
//     statusCheckChannel = WebSocketChannel.connect(Uri.parse("${ApiConstants.websocketUrl}?token=${chatConfigController.config.prefs.getString(constant.token)??""}&type=subscribe&target=${userid.toString()}&convoid=${conversationId.toString()}"));
//     print("✅ WebSocket connection established");
//     debugPrint("connection success:");
//     // item.status.value = 
//     statusCheckChannel.stream.listen((data){
//       item.status.value=data;
//       debugPrint("connection status:${item.status.value}");
//     });
//   } catch (e) {
//     print("❌ Failed to connect: $e");
//    debugPrint("websocket connection failed");
//   }
//   }


  void sendMessage(String message) {
    channel.sink.add(message);
  }

  void disconnect() {
    debugPrint("✅ ping WebSocket connection disconnected on disconnect");
    channel.sink.close(status.normalClosure);
  }
  
  @override
  void onDetached() {
    // TODO: implement onDetached
  }
  
  @override
  void onHidden() {
    disconnect();
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
