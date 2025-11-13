import 'package:chat_app/model/group_member.dart';
import 'package:chat_app/model/user.dart';

class ViewMembersDataResponse {
  GroupDetails? groupDetails;
  Members? members;

  ViewMembersDataResponse({this.groupDetails, this.members});

  ViewMembersDataResponse.fromJson(Map<String, dynamic> json) {
    groupDetails = json['groupDetails'] != null
        ? new GroupDetails.fromJson(json['groupDetails'])
        : null;
    members =
        json['members'] != null ? new Members.fromJson(json['members']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.groupDetails != null) {
      data['groupDetails'] = this.groupDetails!.toJson();
    }
    if (this.members != null) {
      data['members'] = this.members!.toJson();
    }
    return data;
  }
}

class GroupDetails {
  int? id;
  Owner? owner;
    User? currentUser;
  String? groupName;
  String? type;

  GroupDetails({this.id, this.owner, this.groupName, this.type});

  GroupDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    owner = json['owner'] != null ? new Owner.fromJson(json['owner']) : null;
    groupName = json['groupName'];
      currentUser = json['currentUser'] != null
        ? new User.fromJson(json['currentUser'])
        : null;
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    if (this.owner != null) {
      data['owner'] = owner!.toJson();
    }
    data['groupName'] = groupName;
    if (currentUser != null) {
      data['currentUser'] = currentUser!.toJson();
    }
    data['type'] = type;
    return data;
  }
}

class Owner {
  int? id;
  String? username;

  Owner({this.id, this.username});

  Owner.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    return data;
  }
}

class Members {
  List<Member>? items;
  int? totalItems;
  int? pageNumber;
  int? pageSize;
  int? totalPages;

  Members(
      {this.items,
      this.totalItems,
      this.pageNumber,
      this.pageSize,
      this.totalPages});

  Members.fromJson(Map<String, dynamic> json) {
    if (json['items'] != null) {
      items = <Member>[];
      json['items'].forEach((v) {
        items!.add(new Member.fromJson(v));
      });
    }
    totalItems = json['totalItems'];
    pageNumber = json['pageNumber'];
    pageSize = json['pageSize'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.items != null) {
      data['items'] = this.items!.map((v) => v.toJson()).toList();
    }
    data['totalItems'] = totalItems;
    data['pageNumber'] = this.pageNumber;
    data['pageSize'] = this.pageSize;
    data['totalPages'] = this.totalPages;
    return data;
  }
}


