import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/service/dio_service.dart';

import 'package:dio/dio.dart';

import '../../chat_app.dart';
import '../../constants/app_constant.dart';
import '../../model/search_model.dart';

class SearchRepository{
static  Future<SearchListResponse> searchUser(String username,String page)async{
  late final Response response;
  final String token = chatConfigController.config.prefs.getString(chatConfigController.config.token)??"";
  try{
    
    response = await chatConfigController.config.dioService.get(ApiConstants.searchUser,
    options: Options(headers:{"Authorization":"Bearer $token"}),
    queryParameters:{
      "username":username,
      "page":page,
      "size":20

    });
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