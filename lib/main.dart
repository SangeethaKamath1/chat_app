

import 'package:chat_app/audio_call/controller/jitsi_call_controller.dart';
import 'package:chat_app/chat/chat_websocket/chat_web_socket_service.dart';
import 'package:chat_app/group/create_group/controller/create_group_binding.dart';
import 'package:chat_app/group/group_detail/controller/group_detail_controller.dart';
import 'package:chat_app/login/login_screen.dart';

import 'package:chat_app/recent_conversation/recent_conversation_screen.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/service/dio_service.dart';
import 'package:chat_app/service/shared_preference.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'audio_call/service/webrtc_service.dart';
import 'binding/global_binding.dart';
import 'chat/chat_websocket/ping_web_socket.dart';
import 'constants/app_constant.dart';
import 'login/controllers/auth_controller.dart';
import 'recent_conversation/controller/recent_conversation_controller.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
 await DioService().init();

 
  Get.lazyPut(()=>AuthController());
  Get.lazyPut(()=>RecentConversationController());
  Get.lazyPut(()=>CreateGroupBinding());
  Get.lazyPut(()=>GroupDetailController());
  Get.put(WebRTCService());
  // Get.lazyPut(()=>JitsiVoiceCallController());
//   Get.put(()=>ViewMembersController(),permanent:true);
//  Get.lazyPut(() => AddMembersController(), fenix: true);

  await SharedPreference().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{
   late final ws;

 @override
  void initState() {
     super.initState();
    WidgetsBinding.instance.addObserver(this);

    final isLoggedIn = SharedPreference().getBool(AppConstant.isLoggedIn) ?? false;

  if (isLoggedIn) {
    // Register socket service on app start only if user is logged in
   ws= Get.isRegistered<PingWebSocketService>()?Get.find<PingWebSocketService>():
   Get.put(PingWebSocketService(), permanent: true);

    // Optionally auto-connect
    //  ws = Get.find<ChatWebSocketService>();
    ws.connect();
  }
    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
     debugPrint("SharedPreference().getBool(AppConstant.isLoggedIn)==true:${SharedPreference().getBool(AppConstant.isLoggedIn)}");
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      initialBinding: GlobalBinding(),
      
      initialRoute:SharedPreference().getBool(AppConstant.isLoggedIn)==true?AppRoutes.recentConversation: AppRoutes.login,
      getPages: AppRoutes.pages,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SharedPreference().getBool(AppConstant.isLoggedIn)==true?
const RecentConversationScreen():
const LoginScreen()
    );
  }

@override
  void didChangeAppLifecycleState(AppLifecycleState state) {
   
  
    if (state == AppLifecycleState.resumed) {
      if(SharedPreference().getBool(AppConstant.isLoggedIn)==true){
      ws.connect();
      }
    }
    // else if(state ==AppLifecycleState.paused){
    //    ws.disconnect();
    // }
     else if (state == AppLifecycleState.detached) {
      debugPrint("ping websocket closed on detached");
      ws.disconnect();
      Get.find<ChatWebSocketService>().disconnect();
      Get.delete<PingWebSocketService>(force: true);
    }
  //  else if(state ==AppLifecycleState.paused){
  //         ws.disconnect();
  //        Get.find<ChatWebSocketService>().disconnect();
  //   }
  }
}

