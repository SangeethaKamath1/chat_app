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
    int? unreadCount;
    String? type;
    final RxString status = "offline".obs;
    final RxBool isTyping =false.obs;
    User? peerUser;
    String? groupName;
    User? owner;

    Item({
         this.id,
         this.unreadCount,
         this.type,
         this.peerUser,
         this.groupName,
         this.owner
    });

    factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json["id"],
        unreadCount: json["unreadCount"],
        type: json["type"],
        peerUser:json['peerUser'] != null? User.fromJson(json["peerUser"]):null,
        owner:json['owner'] != null? User.fromJson(json["owner"]):null,
        groupName: json['groupName']
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "unreadCount": unreadCount,
        "type": type,
        "peerUser":peerUser != null? peerUser?.toJson():User(),
        "owner":owner!=null?owner?.toJson():User(),
        "groupName":groupName
    };
}

