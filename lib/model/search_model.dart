import 'package:chat_app/model/group_member.dart';

class SearchListResponse{
  List<Member>? content;
  Pageable pageable;
    bool last;
    int totalElements;
    int totalPages;
    bool first;
    int size;
    int number;
    Sort sort;
    int numberOfElements;
    bool empty;
SearchListResponse({this.content,
   required this.pageable,
        required this.last,
        required this.totalElements,
        required this.totalPages,
        required this.first,
        required this.size,
        required this.number,
        required this.sort,
        required this.numberOfElements,
        required this.empty,});


factory SearchListResponse.fromJson(Map<String, dynamic> json){
return SearchListResponse(content: List<Member>.from(json["content"].map((x) => Member.fromJson(x))),
  pageable: Pageable.fromJson(json["pageable"]),
        last: json["last"],
        totalElements: json["totalElements"],
        totalPages: json["totalPages"],
        first: json["first"],
        size: json["size"],
        number: json["number"],
        sort: Sort.fromJson(json["sort"]),
        numberOfElements: json["numberOfElements"],
        empty: json["empty"],);

}

Map<String, dynamic> toJson()=>{
  "content":List<dynamic>.from(content!.map((x)=>x.toJson())),
   "pageable": pageable.toJson(),
        "last": last,
        "totalElements": totalElements,
        "totalPages": totalPages,
        "first": first,
        "size": size,
        "number": number,
        "sort": sort.toJson(),
        "numberOfElements": numberOfElements,
        "empty": empty,
};


}



class Pageable {
    int pageNumber;
    int pageSize;
    Sort sort;
    int offset;
    bool paged;
    bool unpaged;

    Pageable({
        required this.pageNumber,
        required this.pageSize,
        required this.sort,
        required this.offset,
        required this.paged,
        required this.unpaged,
    });

    factory Pageable.fromJson(Map<String, dynamic> json) => Pageable(
        pageNumber: json["pageNumber"],
        pageSize: json["pageSize"],
        sort: Sort.fromJson(json["sort"]),
        offset: json["offset"],
        paged: json["paged"],
        unpaged: json["unpaged"],
    );

    Map<String, dynamic> toJson() => {
        "pageNumber": pageNumber,
        "pageSize": pageSize,
        "sort": sort.toJson(),
        "offset": offset,
        "paged": paged,
        "unpaged": unpaged,
    };
}

class Sort {
    bool sorted;
    bool empty;
    bool unsorted;

    Sort({
        required this.sorted,
        required this.empty,
        required this.unsorted,
    });

    factory Sort.fromJson(Map<String, dynamic> json) => Sort(
        sorted: json["sorted"],
        empty: json["empty"],
        unsorted: json["unsorted"],
    );

    Map<String, dynamic> toJson() => {
        "sorted": sorted,
        "empty": empty,
        "unsorted": unsorted,
    };
   
}