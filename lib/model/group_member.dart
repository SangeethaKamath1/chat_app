import 'package:get/get.dart';

class Member {
  int? id;
  bool? isOwner;
  RxBool isAdmin;        // store non-nullable RxBool
  String? username;
  String? password;
  int? conversationId;

  // Accept a plain bool in constructor for convenience, convert to RxBool internally
  Member({
    this.conversationId,
    this.id,
    this.isOwner,
    this.password,
    this.username,
    bool? isAdmin,
  }) : isAdmin = RxBool(isAdmin ?? false);

  // Factory: read plain bool from JSON and wrap with RxBool
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      conversationId: json["conversationId"] as int?,
      id: json["id"] as int?,
      username: json["username"] as String?,
      password: json["password"] as String?,
      isOwner: json["isOwner"] as bool?,
      isAdmin: (json["isAdmin"] as bool?) ?? false,
    );
  }

  // toJson: extract .value from RxBool
  Map<String, dynamic> toJson() => {
        "conversationId": conversationId,
        "id": id,
        "isOwner": isOwner,
        "isAdmin": isAdmin.value,
        "password": password,
        "username": username,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
