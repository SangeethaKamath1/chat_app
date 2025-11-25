import 'package:chat_app/chat/chat_websocket/ping_web_socket.dart';
import 'package:chat_app/register/repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import '../../chat_app.dart';
import '../../constants/app_constant.dart';
import '../../routes/app_routes.dart';



class AuthController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var loggedInUser = ''.obs;
  

  // For toggling password visibility
  var isPasswordHidden = true.obs;



  /// Register a new user
  Future<void> register() async {
    
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;

    // Save user credentials globally
    
    

    isLoading.value = false;
try{
   AuthRepository.register(username: username, password: password).then((response){
    if(response.message == "User registered"){
Get.snackbar("Success", "Registered Successfully",
          snackPosition: SnackPosition.BOTTOM);
            usernameController.clear();
    passwordController.clear();
    isPasswordHidden.value = true;
    chatConfigController.config.prefs.setString(constant.username, username);
    //chatConfigController.config.prefs.setString(constant.userId,response.)
     Get.offNamed(AppRoutes.login); 
     }else{
      debugPrint("Something went wrong");
      }// reset password visibility
   });
}catch(e){
  Fluttertoast.showToast(msg: "$e");
}


  }

  /// Login user
  Future<void> login() async {
   try{

    
     AuthRepository.login(username: usernameController.text,password: passwordController.text).then((response){
if(response.token!=null){
  Get.snackbar("Success", "Login Success",
          snackPosition: SnackPosition.BOTTOM);
chatConfigController.config.prefs.setString(constant.token, response.token??"");
chatConfigController.config.prefs.setBool(constant.isLoggedIn, true);
chatConfigController.config.prefs.setString(constant.username,usernameController.text);
Get.put(PingWebSocketService(),permanent: true).connect();
Get.toNamed(AppRoutes.recentConversation);
}
     });
   }catch(e){
    Fluttertoast.showToast(msg:"$e");
   }
   
  }

  /// Logout user
  Future<void> logout() async {
    chatConfigController.config.prefs.clear();
    loggedInUser.value = '';
    Get.offAllNamed(AppRoutes.login);
  }
}
