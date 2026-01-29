import 'dart:developer';

import 'package:amu_alumni/amu_alumni.dart';
import 'package:amu_alumni/model/network_exception_model.dart';
import 'package:chat_app/constants/api_constants.dart';
import 'package:dio/dio.dart';

import '../../chat_app.dart';

class ChatInfoRepository {
  static Future<String> blockUser({required String blockUuid}) async {
    final token = chatConfigController.config.prefs
      .getString(chatConfigController.config.token);
    final body = {"blockedUuid": blockUuid};
    try {
      final response = await chatConfigController.config.dioService.post(ApiConstants.blockUser,
          data: body,
          options: Options(
            headers: {"Authorization": "Bearer $token"},
          ));
      if (response.statusCode! >= 200 || response.statusCode! <= 299) {
        final blockResponse = MessageResponseModel.fromJson(response.data);
        return blockResponse.message ?? "";
      }
      return "";
    } on DioException catch (e) {
      final error = e.response?.data;
      throw error["errors"][0]?.toString() ?? "Something went wrong";
    }
  }

  static Future<String> unblockUser({required String blockUuid}) async {
       final token = chatConfigController.config.prefs
      .getString(chatConfigController.config.token);
    final body = {"blockedUuid": blockUuid};
    try {
      final response = await chatConfigController.config.dioService.delete(ApiConstants.unblockAccount,
          data: body,
          options: Options(
            headers: {"Authorization": "Bearer $token"},
          ));
      if (response.statusCode! >= 200 || response.statusCode! <= 299) {
        final unblockResponse = MessageResponseModel.fromJson(response.data);
        return unblockResponse.message ?? "";
      }
      return "";
    } on DioException catch (e) {
      final error = e.response?.data;
      throw error["errors"][0]?.toString() ?? "Something went wrong";
    }
  }

    static Future<String> muteUser({
    required String targetedUserId,
  }) async {
    try {
        final token = chatConfigController.config.prefs
      .getString(chatConfigController.config.token);
      final headers = {"Authorization": "Bearer $token"};
      final body = {
        "targetedUser": targetedUserId,
        "status": "mute",
      };
      log("mute post data=> $body");
      final response = await dio.post(ApiConstants.muteUser,
          data: body, options: Options(headers: headers));
      if (response.statusCode! >= 200 || response.statusCode! <= 299) {
        final muteResponse = MessageResponseModel.fromJson(response.data);
        return muteResponse.message ?? "";
      }
      return "";
    } on DioException catch (e) {
      throw NetworkExceptionModel(
          error: e.response?.statusMessage?.toString() ?? "",
          statusCode: e.response?.statusCode?.toString() ?? "");
    }
  }

  //unmute
  static Future<String> unmuteUser({
    required String targetedUserId,
  }) async {
    try {
      final token = chatConfigController.config.prefs
      .getString(chatConfigController.config.token);
      final headers = {"Authorization": "Bearer $token"};
      final body = {
        "targetedUser": targetedUserId,
        "status": "un_mute",
      };
      log("unmute=> $body");
      final response = await dio.post(ApiConstants.muteUser,
          data: body, options: Options(headers: headers));
      if (response.statusCode! >= 200 || response.statusCode! <= 299) {
        final unmuteResponse = MessageResponseModel.fromJson(response.data);
        return unmuteResponse.message ?? "";
      }
      return "";
    } on DioException catch (e) {
      throw NetworkExceptionModel(
          error: e.response?.statusMessage?.toString() ?? "",
          statusCode: e.response?.statusCode?.toString() ?? "");
    }
  }
}
