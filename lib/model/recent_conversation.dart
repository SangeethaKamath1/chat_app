import 'package:chat_app/model/user.dart';
import 'package:get/get.dart';

class RecentConversation {
    List<Item> items;
    int totalItems;
    int pageNumber;
    int pageSize;
    int totalPages;
    bool isLastPage;

    RecentConversation({
        required this.items,
        required this.totalItems,
        required this.pageNumber,
        required this.pageSize,
        required this.totalPages,
        required this.isLastPage,
    });

    factory RecentConversation.fromJson(Map<String, dynamic> json) => RecentConversation(
        items:json['items'] != null? List<Item>.from(json["items"].map((x) => Item.fromJson(x))):<Item>[],
        totalItems: json["totalItems"],
        pageNumber: json["pageNumber"],
        pageSize: json["pageSize"],
        totalPages: json["totalPages"],
        isLastPage: json["isLastPage"],
    );

    Map<String, dynamic> toJson() => {
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
        "totalItems": totalItems,
        "pageNumber": pageNumber,
        "pageSize": pageSize,
        "totalPages": totalPages,
        "isLastPage": isLastPage,
    };
}

class Item {
    int? id;
    RxInt unreadCount;
    LastMessage? lastMessage;
    String? type;
    final RxString status = "offline".obs;
    final RxBool isTyping =false.obs;
    User? peerUser;
    String? groupName;
    String? icon;
    User? owner;

    Item({
         this.id,
         int? unreadCount,
         this.type,
        this.lastMessage,
         this.peerUser,
         this.icon,
         this.groupName,
         this.owner
    }):unreadCount = RxInt(unreadCount??0);

    factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json["id"],
       unreadCount: (json["unreadCount"] as int?)??0,
        type: json["type"],
        icon : json['icon'],
        peerUser:json['peerUser'] != null? User.fromJson(json["peerUser"]):null,
        owner:json['owner'] != null? User.fromJson(json["owner"]):null,
        groupName: json['groupName'],
        lastMessage : json['lastMessage'] != null
        ?  LastMessage.fromJson(json['lastMessage'])
        : null

    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "unreadCount": unreadCount.value,
        "type": type,
        'icon':icon,
        "peerUser":peerUser != null? peerUser?.toJson():User(),
        "owner":owner!=null?owner?.toJson():User(),
        "groupName":groupName
    };
}

class LastMessage {
  String? message;
  int? createdAt;
  String? senderUUID;

  LastMessage({this.senderUUID,this.message, this.createdAt});

  LastMessage.fromJson(Map<String, dynamic> json) {
    senderUUID = json['senderUUID'];
    message = json['message'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['senderUUID'] = this.senderUUID;
    data['message'] = this.message;
    data['createdAt'] = this.createdAt;
    return data;
  }
}