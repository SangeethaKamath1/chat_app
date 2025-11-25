

// import 'dart:convert';

// import 'package:chat_app/constants/api_constants.dart';
// import 'package:chat_app/constants/app_constant.dart';
// import 'package:chat_app/service/dio_service.dart';

// import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';

// import '../../chat_app.dart';
// import '../../model/login_model.dart';
// import '../../model/status_model.dart';

// class AuthRepository {
//   static Future<StatusModel> register({required String username,required String password})async{
//     late final Response response;
//       try{
//          response = await DioService().dio.post(ApiConstants.register,data:jsonEncode({
//            "username":username,
//             "password":password
//          }));
           
       
//         if(response.statusCode ==200){
//             return StatusModel.fromJson(response.data);
          
//         }
//         throw Exception("Something went wrong");
//       }on DioException catch(e){
//        throw Exception("Something went wrong:$e");
//       }
//   }

//    static Future<LoginModel> login({required String username,required String password})async{
//     late final Response response;
//       try{
//          response = await DioService().dio.post(ApiConstants.login,data:jsonEncode({
//            "username":username,
//             "password":password
//          }));
           
       
//         if(response.statusCode ==200){
//             final loginData = LoginModel.fromJson(response.data);

//             final decodedToken = JWT.tryDecode(loginData.token??"");
//           final userId = decodedToken?.payload["jti"];
//           chatConfigController.config.prefs.setString(chatConfigController.config.constant.userId,userId);
//           debugPrint("user id:${chatConfigController.config.prefs.getString(chatConfigController.config.constant.userId)}");
//           return loginData;
          
//         }
//         throw Exception("Something went wrong");
//       }on DioException catch(e){
//        throw Exception("Something went wrong:$e");
//       }
//   }
// }