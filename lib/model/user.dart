class User {
  int? id;
  String? username;
  String? profilePicture;
bool? isOwner;
String? useruid;
  bool? isBlockedBy;
 DateTime? updatedAt;
  bool? isAdmin;
  User({this.id, this.username,this.useruid, this.isBlockedBy,});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
     isOwner = json['isOwner'];
     useruid = json['useruid'];
    isBlockedBy = json['isBlockedBy'];
     profilePicture = json['profilePicture'];
    isAdmin = json['isAdmin'];
     updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['id'] = id;
    data['username'] = username;
    data['isOwner'] = isOwner;data['useruid'] = this.useruid;
    data['isBlockedBy'] = this.isBlockedBy;
    data['profilePicture']=profilePicture;
    data['isAdmin'] = isAdmin;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
