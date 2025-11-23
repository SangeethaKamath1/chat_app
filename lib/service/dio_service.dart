import 'package:chat_module/constants/api_constants.dart';
import 'package:dio/dio.dart';

class DioService{
  static final DioService _instance =DioService._internal();
  factory DioService()=>_instance;
  DioService._internal();
  late final Dio dio;
  Future<void>  init() async{
     dio = Dio(BaseOptions(baseUrl:ApiConstants.baseUrl,
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type':"application/json",
        'Accept':"application/json"
      }
      
    ))..interceptors.add(LogInterceptor(
    request: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
  ));
  }

}