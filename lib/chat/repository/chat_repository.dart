import 'dart:convert';
import 'dart:developer';

import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/model/conversation_list.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../chat_app.dart';
import '../../model/create_conversation_model.dart';
import '../../model/reaction_list_response.dart';
import '../../model/send_media_data_response.dart';
import '../../model/user.dart';
import '../../service/dio_service.dart';

class ChatRepository {
  static Future<CreateConversationModel> createConversation(
      String conversationId) async {
    late final Response response;
    final token = chatConfigController.config.prefs
        .getString(chatConfigController.config.token);
    try {
      response = await chatConfigController.config.dioService.post(
          "${ApiConstants.createConversation}/$conversationId",
          options: Options(headers: {"Authorization": "Bearer $token"}));

      if (response.statusCode == 200) {
        return CreateConversationModel.fromJson(response.data);
      }
      throw Exception("Something went wrong");
    } on DioException {
      throw Exception("Something went wrong");
    }
  }

  static Future<SendMediaDataResponse> sendMedia(
    List<XFile> mediaFiles,
    Map<String, dynamic> requestData,
  ) async {
    final token = chatConfigController.config.prefs
        .getString(chatConfigController.config.token);

    

    // ✅ request as FIELD (not MultipartFile)
    // formData.fields.add(
    //   MapEntry("request", jsonEncode(requestData)),
    // );

  List<MultipartFile> files = await Future.wait(mediaFiles.map((file) async {
      // Read the file as bytes
      final fileBytes = await file.readAsBytes();

      // Create MultipartFile object
      return MultipartFile.fromBytes(
        fileBytes,
        filename: file.name,
      );
    }));
    final request = {
     "conversationId":requestData["conversationId"],
    //  "replyTo":requestData["replyTo"],
     "messageId":requestData["messageId"]
    };
    log('Encoded JSON: $requestData');

    // logFormData(formData);

 final formData = FormData.fromMap({
      'request': MultipartFile.fromString(
        json.encode(request),
        contentType: MediaType('application', 'json'),
      ),
      'files': files,
    });
    final response = await chatConfigController.config.dioService.post(
      ApiConstants.sendMedia,
      data: formData,
      options: Options(
        // contentType: 'multipart/form-data',
        headers: {
          "Authorization": "Bearer $token",
         
        },
      ),
    );

    if (response.statusCode == 200) {
      return SendMediaDataResponse.fromJson(response.data);
    }

    throw Exception("Something went wrong");
  }

  static void logFormData(FormData formData) {
    debugPrint("━━━━━━━━━━━━━━━━ FORM DATA START ━━━━━━━━━━━━━━━━");

    /// Fields (including request JSON)
    debugPrint("📦 FIELDS:");
    for (var field in formData.fields) {
      if (field.key == "request") {
        try {
          final decoded = jsonDecode(field.value);
          debugPrint("➡️ request (decoded):");
          debugPrint(const JsonEncoder.withIndent("  ").convert(decoded));
        } catch (_) {
          debugPrint("➡️ request (raw): ${field.value}");
        }
      } else {
        debugPrint("➡️ ${field.key}: ${field.value}");
      }
    }

    /// Files metadata
    debugPrint("📎 FILES:");
    for (var file in formData.files) {
      final f = file.value;
      debugPrint(
        "➡️ ${file.key}: "
        "filename=${f.filename}, "
        "contentType=${f.contentType}, "
        "length=${f.length}",
      );
    }

    debugPrint("━━━━━━━━━━━━━━━━ FORM DATA END ━━━━━━━━━━━━━━━━");
  }

  static Future<ConversationListResponse> getConversationsList(
      String conversationId, int page) async {
    late final Response response;
    final token = chatConfigController.config.prefs
        .getString(chatConfigController.config.token);
    try {
      response = await chatConfigController.config.dioService.get(
          "${ApiConstants.chatHistory}/$conversationId",
          queryParameters: {"page": page, "size": 20},
          options: Options(headers: {"Authorization": "Bearer $token"}));

      if (response.statusCode == 200) {
        return ConversationListResponse.fromJson(response.data);
      }
      throw Exception("Something went wrong");
    } on DioException {
      throw Exception("Something went wrong");
    }
  }

  static Future<User> getCurrentUserDetails(int conversationId) async {
    late final Response response;
    final token = chatConfigController.config.prefs
        .getString(chatConfigController.config.token);
    try {
      response = await chatConfigController.config.dioService.get(
          "${ApiConstants.currentUserDetails}/$conversationId",
          options: Options(headers: {"Authorization": "Bearer $token"}));

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      throw Exception("Something went wrong");
    } on DioException {
      throw Exception("Something went wrong");
    }
  }

  static Future<ReactionListResponse> getReactions(
      String messageId, int page) async {
    late final Response response;
    final token = chatConfigController.config.prefs
        .getString(chatConfigController.config.token);
    try {
      response = await chatConfigController.config.dioService.get(
          "${ApiConstants.emojiList}/$messageId",
          queryParameters: {"page": page, "size": 20},
          options: Options(headers: {"Authorization": "Bearer $token"}));

      if (response.statusCode == 200) {
        return ReactionListResponse.fromJson(response.data);
      }
      throw Exception("Something went wrong");
    } on DioException {
      throw Exception("Something went wrong");
    }
  }
}
