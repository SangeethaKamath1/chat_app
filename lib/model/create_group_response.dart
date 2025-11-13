class CreateGroupResponse {
  GroupDetails? groupDetails;

  CreateGroupResponse({this.groupDetails});

  CreateGroupResponse.fromJson(Map<String, dynamic> json) {
    groupDetails = json['groupDetails'] != null
        ? new GroupDetails.fromJson(json['groupDetails'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.groupDetails != null) {
      data['groupDetails'] = this.groupDetails!.toJson();
    }
    return data;
  }
}

class GroupDetails {
  int? id;
  Owner? owner;
  String? groupName;
  String? type;
  int? createdAt;

  GroupDetails(
      {this.id, this.owner, this.groupName, this.type, this.createdAt});

  GroupDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    owner = json['owner'] != null ? new Owner.fromJson(json['owner']) : null;
    groupName = json['groupName'];
    type = json['type'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    if (this.owner != null) {
      data['owner'] = this.owner!.toJson();
    }
    data['groupName'] = this.groupName;
    data['type'] = this.type;
    data['createdAt'] = this.createdAt;
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
