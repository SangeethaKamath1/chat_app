import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:amu_alumni/routes/app_routes.dart';
import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../audio_call/screens/incoming_call_screen.dart';
import '../../chat_app.dart';
import 'group_chat_web_socket_service.dart';

class PingWebSocketService extends FullLifeCycleController
    with FullLifeCycleMixin {
  late IOWebSocketChannel channel;
  final webRTCService = Get.isRegistered<WebRTCService>()
      ? Get.find<WebRTCService>()
      : Get.put(WebRTCService());
  //  late WebSocketChannel statusCheckChannel;
  static int _extractConversationIdFromCallId(String callId) {
    final first = callId.split("_").first;
    return int.tryParse(first) ?? 0;
  }

  static Future<void> _ensureSignalingConnected(String callId) async {
    final signaling = Get.isRegistered<ChatWebSocketService>()
        ? Get.find<ChatWebSocketService>()
        : Get.put(ChatWebSocketService(), permanent: true);

    signaling.setRoom(callId);

    final conversationId = _extractConversationIdFromCallId(callId);
    debugPrint("🧩 conversationId(from callId)=$conversationId");

    if (conversationId == 0) {
      debugPrint("⚠️ conversationId=0, signaling connect skipped");
      return;
    }

    signaling.connect(conversationId);
  }

  void connect() async {
    try {
      debugPrint(
          "fff:${Uri.parse("${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping")}");
      channel = IOWebSocketChannel.connect(
        Uri.parse(
            "${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping"),
      );
      debugPrint(
          "✅ ping WebSocket connection established:${chatConfigController.config.prefs.getString(chatConfigController.config.userId)}");
      debugPrint("connection success:");
      channel.stream.listen((event) async {
        final data = jsonDecode(event);
        log("ping is connected:${data}");
        if (data["connectionStatus"] == "CONNECTED") {
          debugPrint("ping is connected:${data}");
        } else if (data["type"] == "call") {
          _ensureSignalingConnected(data["callID"]);
          final roomId = data["callID"];
          final callerName = data["senderUsername"] ?? "Unknown";
          final offerData = data["offer"];
          final isVideo = data['isVideo'];
          debugPrint("📞 Incoming call from $callerName - Room: $roomId");

          Get.toNamed(ChatAppRoutes.incomingCallScreen, arguments: {
            "roomId": roomId,
            "callerName": callerName,
            "sdp": offerData['sdp'],
            "offerType": offerData['type'],
            "fromNotification": false,
            "isVideo":isVideo
          });
        } else if (data["type"] == "candidate") {
          final candidateData = data["candidate"];
          final callId = data["callID"]?.toString() ?? "";
          debugPrint("❄️ Received ICE candidate for call: $callId");

          await webRTCService.addIceCandidate(
            RTCIceCandidate(
              candidateData['candidate'],
              candidateData['sdpMid'] ?? '0',
              candidateData['sdpMLineIndex'] is int
                  ? candidateData['sdpMLineIndex']
                  : int.tryParse(candidateData['sdpMLineIndex']?.toString() ?? '0') ?? 0,
            ),
          );
        }
        else if (data["type"] == "call_rejected") {
          final callId = data["callID"]?.toString() ?? "";
          final callerName = data["senderUsername"] ?? "Unknown";
          debugPrint("📞 Call rejected by $callerName - callId=$callId");

          webRTCService.speakerphoneService.stopRingtone();
          await webRTCService.endCall();
            Platform.isIOS ? CallKitBridge.dismissIncoming(callId) : null;
          if (Get.currentRoute.contains('call')) {
            Get.back();
          }
        }
         else if (data["type"] == "call_cancelled") {
          final roomId = data["callID"];
          debugPrint("📞 Call ended - Room: $roomId");
          final webRTCService = Get.isRegistered<WebRTCService>()
              ? Get.find<WebRTCService>()
              : Get.put(WebRTCService());
          webRTCService.speakerphoneService.stopRingtone();
          await webRTCService.endCall();

          // Navigate back only if we're on a call screen
          if (Get.currentRoute.contains('incomingCall')) {
            debugPrint("true");
            Get.offNamed(AppRoutes.home);
          }
        } else if (data["type"] == "answer") {
          final answerData = data["answer"];
          final callId = data["callID"]?.toString() ?? "";
          debugPrint("📥 Received ANSWER for call: $callId");

          webRTCService.isCallAccepted.value = true;
          webRTCService.speakerphoneService.stopRingtone();
          await webRTCService.handleAnswer(
            RTCSessionDescription(answerData['sdp'], answerData['type']),
          );
        } else if (data["type"] == "call_accepted") {
          final callId = data["callID"]?.toString() ?? "";
          final username = data["senderUsername"] ?? "Unknown";
          debugPrint("✅ Call accepted by $username - callId=$callId");

          webRTCService.speakerphoneService.stopRingtone();
        } else if (data["type"] == "call_ended") {
          final callId = data["callID"]?.toString() ?? "";
          debugPrint("📞 Call ended - callId=$callId");
          Platform.isIOS ? CallKitBridge.dismissIncoming(callId) : null;
          webRTCService.speakerphoneService.stopRingtone();
          await webRTCService.endCall();

          final nav = Get.key.currentState; // GetMaterialApp navigatorKey
          final canGoBack = nav?.canPop() ?? false;

          if (canGoBack) {
            Get.back();
          } else {
            Get.offAllNamed(AppRoutes.home);
          }
        }else if(data["type"]=="group_call_started"){
            final signaling = Get.isRegistered<GroupChatWebSocketService>()
        ? Get.find<GroupChatWebSocketService>()
        : Get.put(GroupChatWebSocketService(), permanent: true);
                   final callId = data["callID"];
                   
                     


  Get.toNamed(
    ChatAppRoutes.groupIncomingCallScreen,
    arguments: {
      "callId": callId,
      "callerId": data["callerId"],       // if you send it
      "callerName": data["callerName"],   // if you send it
      "isVideo": data["isVideo"] ?? false,
      "fromNotification": false,
    },
  );
        }
      }, onDone: () {
        debugPrint("✅ ping WebSocket connection closed onDone");
      }, onError: (e) {
        debugPrint("✅ ping WebSocket connection closed onError:$e");
        channel = IOWebSocketChannel.connect(
          Uri.parse(
              "${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping"),
        );
      });
    } catch (e) {
      channel = IOWebSocketChannel.connect(
        Uri.parse(
            "${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping"),
      );

      debugPrint("✅ ping WebSocket connection closed on catch");
    }
  }

  void sendFcmToken(String token) {
    debugPrint("send fcm token called");
    final payload = {"type": "fcmToken", "token": token};
    channel?.sink.add(jsonEncode(payload));
    debugPrint("fcm token payload :${payload}");
  }

  void sendVoipToken(String token) {
    debugPrint("send voip token called");
    final payload = {"type": "VoIP", "token": token};
    channel?.sink.add(jsonEncode(payload));
    debugPrint("voip token payload :${payload}");
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
