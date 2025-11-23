import 'package:chat_module/model/user.dart';

class GroupDetailsResponse {
  int? id;
  User? currentUser;
  String? groupName;
  String? description;
  String? type;

  GroupDetailsResponse(
      {this.id, this.currentUser, this.groupName, this.description, this.type});

  GroupDetailsResponse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    currentUser = json['currentUser'] != null
        ? new User.fromJson(json['currentUser'])
        : null;
    groupName = json['groupName'];
    description = json['description'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    if (this.currentUser != null) {
      data['currentUser'] = this.currentUser!.toJson();
    }
    data['groupName'] = this.groupName;
    data['description'] = this.description;
    data['type'] = this.type;
    return data;
  }
}

