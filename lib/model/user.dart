class User {
  int? id;
  String? username;
bool? isOwner;
 DateTime? updatedAt;
  bool? isAdmin;
  User({this.id, this.username});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
     isOwner = json['isOwner'];
    isAdmin = json['isAdmin'];
     updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['id'] = id;
    data['username'] = username;
    data['isOwner'] = isOwner;
    data['isAdmin'] = isAdmin;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
