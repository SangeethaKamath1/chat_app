import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/service/dio_service.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../chat_app.dart';
import '../../constants/app_constant.dart';
import '../../model/recent_conversation.dart';

class RecentConversationRepository{

static   Future<RecentConversation> recentConversationList(String searchQuery,int page)async{
  late final Response response;
  final token = chatConfigController.config.prefs.getString(chatConfigController.config.token);
  debugPrint("token:$token");
  try{
response = await chatConfigController.config.dioService.get(ApiConstants.recentConversationList,queryParameters: {
  "searchQuery":searchQuery,
  "page":page,
  "size":20
},
options: Options(headers: {"Authorization":"Bearer $token"}));


if(response.statusCode==200){
return  RecentConversation.fromJson(response.data);
}
throw Exception("Something went wrong");
  }on DioException {
    throw Exception("Something went wrong");
  }

  }


}