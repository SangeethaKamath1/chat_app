class User {
  int? id;
  String? username;
  String? profilePicture;
bool? isOwner;
 DateTime? updatedAt;
  bool? isAdmin;
  User({this.id, this.username});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
     isOwner = json['isOwner'];
     profilePicture = json['profilePicture'];
    isAdmin = json['isAdmin'];
     updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['id'] = id;
    data['username'] = username;
    data['isOwner'] = isOwner;
    data['profilePicture']=profilePicture;
    data['isAdmin'] = isAdmin;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
