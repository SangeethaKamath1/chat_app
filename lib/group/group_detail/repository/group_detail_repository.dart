


import 'dart:convert';
import 'dart:io';

import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/model/group_details.dart';
import 'package:chat_app/model/view_members_data_response.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../chat_app.dart';
import '../../../constants/api_constants.dart';
import '../../../model/status_model.dart';
import '../../../service/dio_service.dart';

class GroupDetailRepository{
  static Future<StatusModel> setGroupIcon(File icon, int groupId)async{
    late final Response response;
    final token =chatConfigController.config.prefs.getString(constant.token);
    try{
       final FormData formData = FormData();
      formData.files.add(
        MapEntry(
          "file",
          await MultipartFile.fromFile(
            icon.path,
          ),
        ),
      );
    response = await DioService().dio.post("${ApiConstants.setGroupIcon}$groupId",data:formData,
    options:Options(headers: {"Authorization":"Bearer $token"})
    

    );
    if(response.statusCode==200){
      return StatusModel.fromJson(response.data);
    }
throw Exception("something went wrong");

  }on DioException catch(e){
    throw Exception("Something went wrong:$e");

  }
}


  static Future<ViewMembersDataResponse> viewMembers(int groupId,int page)async{
    late final Response response;
    final token =chatConfigController.config.prefs.getString(constant.token);
    try{
       
    response = await DioService().dio.get("${ApiConstants.viewMembers}$groupId",
    queryParameters: {
      "page":page,
      "size":20
    },
    options:Options(headers: {"Authorization":"Bearer $token"})
    

    );
    if(response.statusCode==200){
      return ViewMembersDataResponse.fromJson(response.data);
    }
throw Exception("something went wrong");

  }on DioException catch(e){
    throw Exception("Something went wrong:$e");

  }
}
static Future<StatusModel> addMembers(int groupId,List<int> users)async{
    late final Response response;
    final token =chatConfigController.config.prefs.getString(constant.token);
    try{
       
    response = await DioService().dio.post(ApiConstants.addMember,
    data:jsonEncode({
      "conversationId":groupId,
      "users":users
    }),
    options:Options(headers: {"Authorization":"Bearer $token"})
    

    );
    if(response.statusCode==200){
     if (response.data is String) {
        return StatusModel(message: response.data);
      } else if (response.data is Map<String, dynamic>) {
        return StatusModel.fromJson(response.data);
      }
    }
throw Exception("something went wrong");

  }on DioException catch(e){
    throw Exception("Something went wrong:$e");

  }
}

static Future<StatusModel> removeMember(int conversationId,int memberId)async{
    late final Response response;
    final token =chatConfigController.config.prefs.getString(constant.token);
    try{
       
    response = await DioService().dio.post(ApiConstants.removeMember,
    queryParameters:{
      "conversationId":conversationId,
      "memberId":memberId
    },
    options:Options(headers: {"Authorization":"Bearer $token"})
    

    );
    if(response.statusCode==200){
     if (response.data is String) {
        return StatusModel(message: response.data);
      } 
        return StatusModel.fromJson(response.data);
      
    }
throw Exception("something went wrong");

  }on DioException catch(e){
    throw Exception("Something went wrong:$e");

  }
}


static Future<StatusModel> groupUpdate(int conversationId, String groupName,String description)async{
    late final Response response;
    final token =chatConfigController.config.prefs.getString(constant.token);
    try{
       debugPrint("group data:${jsonEncode({
      "groupName":groupName,
      "conversationId":conversationId,
      "description":description
    })}");
    response = await DioService().dio.post(ApiConstants.updateGroup,
    data:jsonEncode({
      "groupName":groupName,
      "conversationId":conversationId,
      "description":description
    }),
    options:Options(headers: {"Authorization":"Bearer $token"})
    

    );
    if(response.statusCode==200){
     if (response.data is String) {
        return StatusModel(message: response.data);
      } 
        return StatusModel.fromJson(response.data);
      
    }
throw Exception("something went wrong");

  }on DioException catch(e){
    throw Exception("Something went wrong:$e");

  }
}


static Future<StatusModel> exitGroup(int conversationId)async{
    late final Response response;
    final token =chatConfigController.config.prefs.getString(constant.token);
    try{
       
    response = await DioService().dio.post("${ApiConstants.exitGroup}/$conversationId",
    
    options:Options(headers: {"Authorization":"Bearer $token"})
    

    );
    if(response.statusCode==200){
     if (response.data is String) {
        return StatusModel(message: response.data);
      } 
        return StatusModel.fromJson(response.data);
      
    }
throw Exception("something went wrong");

  }on DioException catch(e){
    throw Exception("Something went wrong:$e");

  }
}
static Future<GroupDetailsResponse> groupDetails(int conversationId)async{
    late final Response response;
    final token =chatConfigController.config.prefs.getString(constant.token);
    try{
       
    response = await DioService().dio.get("${ApiConstants.currentGroupDetails}/$conversationId",
    
    options:Options(headers: {"Authorization":"Bearer $token"})
    

    );
    if(response.statusCode==200){
    
        return GroupDetailsResponse.fromJson(response.data);
      
    }
throw Exception("something went wrong");

  }on DioException catch(e){
    throw Exception("Something went wrong:$e");

  }
}

static Future<StatusModel> memberPromote(int conversationId, int memberId,bool isAdmin)async{
    late final Response response;
    final token =chatConfigController.config.prefs.getString(constant.token);
    try{
       
    response = await DioService().dio.post(ApiConstants.memberPromote,
    queryParameters:{
      
      "conversationId":conversationId,
      "memberId":memberId,
      "isAdmin":isAdmin
    },
    options:Options(headers: {"Authorization":"Bearer $token"})
    

    );
    if(response.statusCode==200){
     if (response.data is String) {
        return StatusModel(message: response.data);
      } 
        return StatusModel.fromJson(response.data);
      
    }
throw Exception("something went wrong");

  }on DioException catch(e){
    throw Exception("Something went wrong:$e");

  }
}
}