import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/service/dio_service.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../chat_app.dart';
import '../../constants/app_constant.dart';
import '../../model/recent_conversation.dart';

class RecentConversationRepository{

static Future<RecentConversation> recentConversationList(
    String searchQuery,
    int page,
) async {
  late final Response response;

  final token = chatConfigController.config.prefs
      .getString(chatConfigController.config.token);

  debugPrint("➡️ API CALL: ${ApiConstants.recentConversationList}");
  debugPrint("➡️ Token: $token");
  debugPrint("➡️ Params: searchQuery=$searchQuery, page=$page, size=20");

  try {
    response = await chatConfigController.config.dioService.get(
      ApiConstants.recentConversationList,
      queryParameters: {
        "searchQuery": searchQuery,
        "page": page,
        "size": 20,
      },
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
    );

    debugPrint("✅ STATUS CODE: ${response.statusCode}");
    debugPrint("✅ RESPONSE DATA: ${response.data}");

    if (response.statusCode == 200) {
      return RecentConversation.fromJson(response.data);
    }

    throw Exception("Something went wrong");
  } on DioException catch (e) {
    debugPrint("❌ DIO ERROR: ${e.message}");
    debugPrint("❌ ERROR RESPONSE: ${e.response?.data}");
    throw Exception("Something went wrong");
  }
}


}