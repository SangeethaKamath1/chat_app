class CreateConversationModel{
  int? conversationId;

  CreateConversationModel({this.conversationId});
factory  CreateConversationModel.fromJson(Map<String, dynamic> json){
return CreateConversationModel(conversationId: json["conversationId"]);
  }

  Map<String,dynamic> toJson()=>{
"conversationId":conversationId
  };
}