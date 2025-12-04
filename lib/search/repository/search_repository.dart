import 'package:chat_app/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../chat_app.dart';
import '../../model/search_model.dart';

class SearchRepository{
static  Future<SearchListResponse> searchUser(String username,String page)async{
  late final Response response;
  final String token = chatConfigController.config.prefs.getString(chatConfigController.config.token)??"";
  try{
    Dio dio = Dio();
 final parameters = {"userUid": chatConfigController.config.prefs.getString(chatConfigController.config.userId)??"", "pageNumber": page ?? 0, "keyword": username ?? '', "pageSize": 15};
 debugPrint("parameters:${parameters}");
    response = await dio.get(ApiConstants.searchUser,
    options: Options(headers:{"Authorization":"Bearer $token"}),
    queryParameters:parameters);
    //final uri = Uri.parse(ApiConstants.searchUser).replace(queryParameters: parameters);

//print("➡️ FINAL URL: $uri");
    if(response.statusCode == 200){
     return SearchListResponse.fromJson(response.data);
    }else{
      throw Exception("Something went wrong");
    }
  }on DioException catch(e){
    throw Exception("something went wrong:$e");
  }


}


}