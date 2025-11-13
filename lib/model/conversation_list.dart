import 'package:get/get.dart';

class ConversationListResponse {
  RxList<Conversations>? items;
  int? pageNumber;
  int? pageSize;
  int? totalPages;
  bool? isLastPage;

  ConversationListResponse(
      {this.items,
      this.pageNumber,
      this.pageSize,
      this.totalPages,
      this.isLastPage});

  ConversationListResponse.fromJson(Map<String, dynamic> json) {
    if (json['items'] != null) {
      items = <Conversations>[].obs;
      json['items'].forEach((v) {
        items!.add(new Conversations.fromJson(v));
      });
    }
    pageNumber = json['pageNumber'];
    pageSize = json['pageSize'];
    totalPages = json['totalPages'];
    isLastPage = json['isLastPage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    data['pageNumber'] = pageNumber;
    data['pageSize'] = pageSize;
    data['totalPages'] = totalPages;
    data['isLastPage'] = isLastPage;
    return data;
  }
}

class Conversations {
  String? id;
  String? senderUUID;
  String? senderUsername;
  String? message;
  String? status;
  bool? isReacted;
  String? reaction;
  Conversations? replayTo;
   RxList<String>? reactions = <String>[].obs;
  int? createdAt;
  int? reactionCount;

  Conversations(
      {this.id,
      this.senderUUID,
      this.senderUsername,
      this.isReacted,
      this.message,
      this.status,
      this.replayTo,
      this.reaction,
      this.reactionCount,
     RxList<String>? reactions,
      this.createdAt}){
    if (reactions != null) this.reactions = reactions;
  }
      

factory   Conversations.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'];
   return Conversations( id : json['id'],
    senderUUID : json['senderUUID'],
    senderUsername : json['senderUsername'],
    message : json['message'],
    status :json['status'],
     reaction :json['reaction'],
    replayTo : json['replayTo'] != null
        ?  Conversations.fromJson(json['replayTo'])
        : null,
    isReacted: json['isReacted'],
    reactionCount:json['reactionCount'],
   reactions: json['reactions'] != null
        ? List<String>.from(json['reactions']).obs
        : <String>[].obs,
    createdAt : json['createdAt']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['senderUUID'] = this.senderUUID;
    data['senderUsername'] = this.senderUsername;
    data['message'] = this.message;
    data['status'] = this.status;
     data['reaction'] = this.reaction;
    data['isReacted']=this.isReacted;
    if (data["replayTo"] != null) {
      data['replayTo'] = this.replayTo!.toJson();
    }
    data['reactions'] = reactions?.toList();
    data['createdAt'] = this.createdAt;
    data['reactionCount']=this.reactionCount;
    return data;
  }
}

