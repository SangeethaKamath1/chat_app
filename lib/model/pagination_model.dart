
class Pageable {
    Sort? sort;
    int? pageNumber;
    int? pageSize;
    int? offset;
    bool? paged;
    bool? unpaged;

    Pageable({
      this.sort,
      this.pageNumber,
      this.pageSize,
      this.offset,
      this.paged,
      this.unpaged,
    });

    factory Pageable.fromJson(Map<String, dynamic> json) => Pageable(
        sort: Sort.fromJson(json["sort"]),
        pageNumber: json["pageNumber"],
        pageSize: json["pageSize"],
        offset: json["offset"],
        paged: json["paged"],
        unpaged: json["unpaged"],
    );

    Map<String, dynamic> toJson() => {
        "sort": sort?.toJson(),
        "pageNumber": pageNumber,
        "pageSize": pageSize,
        "offset": offset,
        "paged": paged,
        "unpaged": unpaged,
    };
}

class Sort {
    bool? sorted;
    bool? empty;
    bool? unsorted;

    Sort({
      this.sorted,
      this.empty,
      this.unsorted,
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
