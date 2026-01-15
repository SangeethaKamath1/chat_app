import 'package:chat_app/model/join_group_call_data_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';


import '../../chat_app.dart';
import '../../constants/api_constants.dart';

class GroupCallRepository {
  static Future<JoinGroupCallDataResponse> joinGroupCall(
      String callId) async {
        debugPrint("call id inside join group call:${callId}");
    late final Response response;
    final token = chatConfigController.config.prefs
        .getString(chatConfigController.config.token);
        debugPrint("token inside group repository:${token}");
    try {
      response = await chatConfigController.config.dioService.get(
          "${ApiConstants.joinGroupCall}$callId/join",
          options: Options(headers: {"Authorization": "Bearer $token"}));

      if (response.statusCode == 200) {
        return JoinGroupCallDataResponse.fromJson(response.data);
      }
      throw Exception("Something went wrong");
    } on DioException {
      throw Exception("Something went wrong");
    }
  }
}