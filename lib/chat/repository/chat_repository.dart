import 'dart:convert';
import 'dart:developer';

import 'package:amu_alumni/amu_alumni.dart';
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
import '../components/compress_media.dart';

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

  static  Future<ProfileDetailsModel> getProfile(String username)async{
  late final Response response;
  final String token = chatConfigController.config.prefs.getString(chatConfigController.config.token)??"";
  debugPrint("getprofile token:${token}");
  try{
    Dio dio = Dio();
 final parameters = { "field": "username",
  "value":username
 };
 debugPrint("parameters:${parameters}");
    response = await dio.get(ApiConstants.getUserProfile,
    options: Options(headers:{"Authorization":"Bearer $token"}),
    queryParameters:parameters);
    //final uri = Uri.parse(ApiConstants.searchUser).replace(queryParameters: parameters);

//print("➡️ FINAL URL: $uri");
    if(response.statusCode == 200){
      
     return ProfileDetailsModel.fromJson(response.data);
    }else{
      throw Exception("Something went wrong");
    }
  }on DioException catch(e){
    throw Exception("something went wrong:$e");
  }


}

  static Future<SendMediaDataResponse> sendMedia(
    List<XFile> images,
    Map<String, dynamic> data,
    
  ) async {
    final token = chatConfigController.config.prefs
        .getString(chatConfigController.config.token);


  

  // List<MultipartFile> files = await Future.wait(images.map((file) async {
  //     // Read the file as bytes
  //     final fileBytes = await file.readAsBytes();

  //     // Create MultipartFile object
  //     return MultipartFile.fromBytes(
  //       fileBytes,
  //       filename: file.name,
  //     );
  //   }));
List<MultipartFile> files = await Future.wait(
  images.map((file) async {
    XFile finalFile = file;

    /// 🔹 Compress first
    try {
      if (isVideo(file)) {
        final compressedVideo = await compressVideo(file);
        if (compressedVideo != null) {
          finalFile = XFile(compressedVideo.path);
        }
      } else {
        final compressedImage = await compressImage(file);
        if (compressedImage != null) {
          finalFile = compressedImage;
        }
      }
    } catch (_) {
      // fallback to original file
      finalFile = file;
    }

    /// 🔹 Then read bytes (same as before)
    final fileBytes = await finalFile.readAsBytes();

    return MultipartFile.fromBytes(
      fileBytes,
      filename: finalFile.name,
    );
  }),
);

    final requestData = {
     "conversationId":data["conversationId"],
    "replyTo":data["replyTo"],
     "messageId":data["messageId"],
     "urls":data["urls"]
    };
    log('Encoded JSON: $requestData');

    // logFormData(formData);

 final formData = FormData.fromMap({
      'request': MultipartFile.fromString(
        json.encode(requestData),
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
      debugPrint("media response:${response.data}");
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

    static Future<SendMediaDataResponse> sendMediaWithProgress(
    List<XFile> images,
    Map<String, dynamic> data, {
    required Function(double progress) onProgress,
  }) async {
    final token = chatConfigController.config.prefs
        .getString(chatConfigController.config.token);

    // Compress and prepare files
    List<MultipartFile> files = await Future.wait(
      images.map((file) async {
        XFile finalFile = file;

        /// 🔹 Compress first
        try {
          if (isVideo(file)) {
            final compressedVideo = await compressVideo(file);
            if (compressedVideo != null) {
              finalFile = XFile(compressedVideo.path);
            }
          } else {
            final compressedImage = await compressImage(file);
            if (compressedImage != null) {
              finalFile = compressedImage;
            }
          }
        } catch (_) {
          // fallback to original file
          finalFile = file;
        }

        /// 🔹 Then read bytes
        final fileBytes = await finalFile.readAsBytes();

        return MultipartFile.fromBytes(
          fileBytes,
          filename: finalFile.name,
        );
      }),
    );

    final requestData = {
      "conversationId": data["conversationId"],
      "replyTo": data["replyTo"],
      "messageId": data["messageId"],
      "urls": data["urls"],
      "receiverUsername":data["receiverUsername"],
      "receiver":data["receiver"]

    };
    
    log('Encoded JSON: $requestData');

    final formData = FormData.fromMap({
      'request': MultipartFile.fromString(
        json.encode(requestData),
        contentType: MediaType('application', 'json'),
      ),
      'files': files,
    });

    // ✅ Make request with progress tracking
    final response = await chatConfigController.config.dioService.post(
      ApiConstants.sendMedia,
      data: formData,
      onSendProgress: (sent, total) {
        if (total != -1) {
          final progress = sent / total;
          onProgress(progress);
          log('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      },
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
    );
debugPrint("media response:${response.statusCode}");
    if (response.statusCode == 200) {
      return SendMediaDataResponse.fromJson(response.data);
    }

    throw Exception("Something went wrong");
  }

  static Future<String> clearChat(
   int conversationId
) async {
  late final Response response;

  final token = chatConfigController.config.prefs
      .getString(chatConfigController.config.token);
  try {
    response = await chatConfigController.config.dioService.post(
      "${ApiConstants.clearChat}$conversationId",
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
    );

    debugPrint("✅ STATUS CODE: ${response.statusCode}");
    debugPrint("✅ RESPONSE DATA: ${response.data}");

    if (response.statusCode == 200) {
      debugPrint("clear chat response:${response.data["message"]}");
      return response.data["message"];
    }

    throw Exception("Something went wrong");
  } on DioException catch (e) {
    debugPrint("❌ DIO ERROR: ${e.message}");
    debugPrint("❌ ERROR RESPONSE: ${e.response?.data}");
    throw Exception("Something went wrong");
  }
}
}
