import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/model/conversation_list.dart';
import 'package:dio/dio.dart';



import '../../model/create_conversation_model.dart';
import '../../model/reaction_list_response.dart';
import '../../model/user.dart';
import '../../service/dio_service.dart';
import '../../service/shared_preference.dart';

class ChatRepository {

static   Future<CreateConversationModel> createConversation(String conversationId)async{
  late final Response response;
  final token = SharedPreference().getString(AppConstant.token);
  try{
response = await DioService().dio.post("${ApiConstants.createConversation}/$conversationId",
options: Options(headers: {"Authorization":"Bearer $token"}));

if(response.statusCode==200){
return  CreateConversationModel.fromJson(response.data);
}
throw Exception("Something went wrong");
  }on DioException {
    throw Exception("Something went wrong");
  }

  }

  static   Future<ConversationListResponse> getConversationsList(String conversationId,int page)async{
  late final Response response;
  final token = SharedPreference().getString(AppConstant.token);
  try{
response = await DioService().dio.get("${ApiConstants.chatHistory}/$conversationId",
queryParameters: {
  "page":page,
  "size":20
},
options: Options(headers: {"Authorization":"Bearer $token"}));

if(response.statusCode==200){
return  ConversationListResponse.fromJson(response.data);
}
throw Exception("Something went wrong");
  }on DioException {
    throw Exception("Something went wrong");
  }

  }

  static   Future<User> getCurrentUserDetails(int conversationId)async{
  late final Response response;
  final token = SharedPreference().getString(AppConstant.token);
  try{
response = await DioService().dio.get("${ApiConstants.currentUserDetails}/$conversationId",

options: Options(headers: {"Authorization":"Bearer $token"}));

if(response.statusCode==200){
return  User.fromJson(response.data);
}
throw Exception("Something went wrong");
  }on DioException {
    throw Exception("Something went wrong");
  }

  }


    static   Future<ReactionListResponse> getReactions(String messageId,int page)async{
  late final Response response;
  final token = SharedPreference().getString(AppConstant.token);
  try{
response = await DioService().dio.get("${ApiConstants.emojiList}/$messageId",
queryParameters: {
  "page":page,
  "size":20
},
options: Options(headers: {"Authorization":"Bearer $token"}));

if(response.statusCode==200){
return  ReactionListResponse.fromJson(response.data);
}
throw Exception("Something went wrong");
  }on DioException {
    throw Exception("Something went wrong");
  }

  }

  
}
