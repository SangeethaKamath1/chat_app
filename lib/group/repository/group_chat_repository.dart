import 'dart:convert';

import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/model/create_group_response.dart';
import 'package:chat_app/model/group_message_status.dart';
import 'package:chat_app/service/dio_service.dart';
import 'package:dio/dio.dart';

import '../../chat_app.dart';


class GroupChatRepository {

 static Future<CreateGroupResponse> createGroup(String groupName,List<int> users,String description)async{
  late final Response response;
  final token =chatConfigController.config.prefs.getString(chatConfigController.config.token);
  try{
  response =await chatConfigController.config.dioService.post(ApiConstants.createGroup,
  options: Options(headers: {"authorization":"Bearer $token"}),
  data:
jsonEncode({
  "userId":chatConfigController.config.prefs.getString(chatConfigController.config.userId),
  "groupName":groupName,
  "description":description,
  "users":users

}),



  );
  if(response.statusCode==200){
  return CreateGroupResponse.fromJson(response.data);
}
throw Exception("something went wrong");
 }
  on DioException catch(e){
    throw Exception("Something went wrong:$e");

 }
}


static Future<GroupMessageStatus> fetchMessageStatus(String messageId)async{
  late final Response response;
  final token =chatConfigController.config.prefs.getString(chatConfigController.config.token);
  try{
  response =await chatConfigController.config.dioService.get("${ApiConstants.messageStatus}/$messageId",
  options: Options(headers: {"authorization":"Bearer $token"}),
  );
  if(response.statusCode==200){
  return GroupMessageStatus.fromJson(response.data);
}
throw Exception("something went wrong");
 }
  on DioException catch(e){
    throw Exception("Something went wrong:$e");

 }
}



}