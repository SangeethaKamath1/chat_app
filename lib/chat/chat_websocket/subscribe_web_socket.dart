import 'dart:convert';

import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import '../../chat_app.dart';
import '../../model/recent_conversation.dart';

import 'package:web_socket_channel/status.dart' as status;

class SubscribeWebSocketService extends GetxService{
 
final Map<int, IOWebSocketChannel> _sockets = {};
final Map<int,String> userStatus ={};

void subscribe(int conversationId, int userId,Item item){
  debugPrint("subscribe socket:${_sockets[userId]?.protocol}");
 if (_sockets.containsKey(userId)) {
      debugPrint("⚠️ Socket already exists for user $userId");
      return;
    }


  try{
    
    final subscribeChannnel=IOWebSocketChannel.connect(Uri.parse("${ApiConstants.subscriptionWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token)??""}&type=subscribe&target=${userId.toString()}&convoId=${conversationId.toString()}"));
    _sockets[userId]=subscribeChannnel;
   debugPrint("✅ subscribe WebSocket connected for user $userId");

    subscribeChannnel.stream.listen((event){
      try{
                // debugPrint("📡 [Convo $conversationId] User $userId is ${item.status.value}");
      final data =jsonDecode(event);
      debugPrint("gggvgv:$data");
      if(data["type"]=="status"){
          final isOnline = data["online"] == true;
          item.status.value = isOnline ? "online" : "offline";
          userStatus[userId]= isOnline ? "online" : "offline";
          debugPrint("📡 [Convo $conversationId] User $userId is ${item.status.value}");
      }
          if(data["type"]=="typing"){
            item.isTyping.value =data["isTyping"]=="true"?true:false;
          }
        
      }catch(e){
       debugPrint("✅ subscribe WebSocket connection closed");
      }
    },
    onError: (e) {
        debugPrint("✅ subscribe WebSocket connection closed");

        },
        onDone: () {
          debugPrint("✅ subscribe WebSocket connection closed");
          //_sockets.remove(conversationId);
        },
         cancelOnError: false,
    );
  } catch(e){
    debugPrint("❌ Failed to subscribe to convo $conversationId: $e");
  }
}

// void unsubscribe(int userId){
//   if(_sockets.containsKey(userId)){
//     _sockets[userId]?.sink.close();
//     _sockets.remove(userId);
   

//   }
// }
  void unsubscribeAll() {
  for (final id in _sockets.keys.toList()) {
    _sockets[id]?.sink.close(status.normalClosure);
    _sockets.remove(id);
  }
  _sockets.clear();
}







}
