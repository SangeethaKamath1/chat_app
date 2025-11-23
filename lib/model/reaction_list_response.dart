import 'package:chat_module/model/user.dart';
import 'package:get/get.dart';

class ReactionListResponse {
  RxList<Reaction>? items;
  int? totalItems;
  int? pageNumber;
  int? pageSize;
  int? totalPages;
  bool? isLastPage;

  ReactionListResponse(
      {this.items,
      this.totalItems,
      this.pageNumber,
      this.pageSize,
      this.totalPages,
      this.isLastPage});

  ReactionListResponse.fromJson(Map<String, dynamic> json) {
    if (json['items'] != null) {
      items = <Reaction>[].obs;
      json['items'].forEach((v) {
        items!.add(new Reaction.fromJson(v));
      });
    }
    totalItems = json['totalItems'];
    pageNumber = json['pageNumber'];
    pageSize = json['pageSize'];
    totalPages = json['totalPages'];
    isLastPage = json['isLastPage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.items != null) {
      data['items'] = this.items!.map((v) => v.toJson()).toList();
    }
    data['totalItems'] = this.totalItems;
    data['pageNumber'] = this.pageNumber;
    data['pageSize'] = this.pageSize;
    data['totalPages'] = this.totalPages;
    data['isLastPage'] = this.isLastPage;
    return data;
  }
}

class Reaction {
  String? reaction;
  User? user;

  Reaction({this.reaction, this.user});

  Reaction.fromJson(Map<String, dynamic> json) {
    reaction = json['reaction'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['reaction'] = this.reaction;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}

