import 'pagination_model.dart';

class SearchListResponse {
  String? code;
  String? status;
  SearchListData? data;

  SearchListResponse({
    this.code,
    this.status,
    this.data,
  });

  factory SearchListResponse.fromJson(Map<String, dynamic> json) => SearchListResponse(
        code: json["code"],
        status: json["status"],
        data: SearchListData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "status": status,
        "data": data?.toJson(),
      };
}

class SearchListData {
  List<ChatUsers>? content;
  Pageable? pageable;
  int? totalElements;
  int? totalPages;
  bool? last;
  int? size;
  int? number;
  Sort? sort;
  int? numberOfElements;
  bool? first;
  bool? empty;
  bool? isFollowing;
  bool? isPrivate;
  String? followStatus;
  String? accountType;

  SearchListData({
    this.content,
    this.pageable,
    this.totalElements,
    this.totalPages,
    this.last,
    this.size,
    this.number,
    this.sort,
    this.numberOfElements,
    this.first,
    this.isFollowing,
    this.isPrivate,
    this.followStatus,
    this.accountType,
    this.empty,
  });

  factory SearchListData.fromJson(Map<String, dynamic> json) => SearchListData(
      last: json["last"],
      size: json["size"],
      number: json["number"],
      first: json["first"],
      empty: json["empty"],
      isPrivate: json["isPrivate"],
      totalPages: json["totalPages"],
      isFollowing: json["isFollowing"],
      sort: Sort.fromJson(json["sort"]),
      followStatus: json["followStatus"],
      totalElements: json["totalElements"],
      numberOfElements: json["numberOfElements"],
      pageable: Pageable.fromJson(json["pageable"]),
      content: List<ChatUsers>.from(json["content"].map((x) => ChatUsers.fromJson(x))),
      accountType: json["accountType"]);

  Map<String, dynamic> toJson() => {
        "last": last,
        "size": size,
        "first": first,
        "empty": empty,
        "number": number,
        "isPrivate": isPrivate,
        "sort": sort?.toJson(),
        "totalPages": totalPages,
        "isFollowing": isFollowing,
        "followStatus": followStatus,
        "pageable": pageable?.toJson(),
        "totalElements": totalElements,
        "numberOfElements": numberOfElements,
        "content": List<dynamic>.from(content!.map((x) => x.toJson())),
        "accountType": accountType
      };
}

class ChatUsers {
  int? id;
  String? email;
  String? mobile;
  String? userUid;
  bool? isPrivate;
  bool? isRequested;
  String? username;
  bool? isVerified;
  String? fullName;
  bool? isFollowing;
  String? accountType;
  String? customBadge;
  String? followStatus;
  String? verificationType;
  String? profilePictureUrl;

  ChatUsers(
      {this.username,
      this.id,
     this.fullName,
      this.email,
      this.mobile,
      this.profilePictureUrl,
      this.customBadge,
      this.isVerified,
      this.isRequested,
      this.verificationType,
      this.isFollowing,
      this.isPrivate,
      this.followStatus,
      this.userUid,
      this.accountType});

  factory ChatUsers.fromJson(Map<String, dynamic> json) => ChatUsers(
      username: json["username"],
      id: json["id"],
      fullName: json["fullName"],
     
      email: json["email"],
      mobile: json["mobile"],
      profilePictureUrl: json["profilePictureUrl"],
      userUid: json["userUid"],
      customBadge: json["customBadge"],
      isVerified: json["isVerified"],
      isFollowing: json["isFollowing"],
      isRequested: json["isRequested"],
      isPrivate: json["isPrivate"],
      followStatus: json["followStatus"],
      verificationType: json["verificationType"],
      accountType: json["accountType"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "fullName": fullName,
        "email": email,
        "mobile": mobile,
        "profilePictureUrl": profilePictureUrl,
        "userUid": userUid,
        "customBadge": customBadge,
        "verificationType": verificationType,
        "isVerified": isVerified,
        "isFollowing": isFollowing,
        "isRequested": isRequested,
        "isPrivate": isPrivate,
        "followStatus": followStatus,
        "accountType": accountType
      };
}
