
import 'package:chat_app/chat/chat_websocket/chat_web_socket_service.dart';
import 'package:chat_app/group/create_group/controller/create_group_binding.dart';
import 'package:chat_app/group/group_detail/controller/group_detail_controller.dart';
import 'package:chat_app/login/login_screen.dart';

import 'package:chat_app/recent_conversation/recent_conversation_screen.dart';

import 'package:chat_app/service/dio_service.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'audio_call/service/webrtc_service.dart';
import 'binding/global_binding.dart';
import 'chat/chat_websocket/ping_web_socket.dart';
import 'chat_app.dart';
import 'constants/app_constant.dart';
import 'login/controllers/auth_controller.dart';
import 'recent_conversation/controller/recent_conversation_controller.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();


 


  runApp(const MyApp());
}

class MyApp extends StatefulWidget{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{
   

 @override
  void initState() {
     super.initState();
    WidgetsBinding.instance.addObserver(this);

    // final isLoggedIn = chatConfigController.config.prefs.getBool(constant.isLoggedIn) ?? false;

  // if (isLoggedIn) {
    // Register socket service on app start only if user is logged in
  
  // }
    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return GetMaterialApp(
     
    );
  }

@override
  void didChangeAppLifecycleState(AppLifecycleState state) {
   
  
    
  }
}

