class SendMediaDataResponse {
  int? conversationId;
  int? totalFiles;
  int? successfulUploads;
  int? failedUploads;
  List<Files>? files;

  SendMediaDataResponse(
      {this.conversationId,
      this.totalFiles,
      this.successfulUploads,
      this.failedUploads,
      this.files});

  SendMediaDataResponse.fromJson(Map<String, dynamic> json) {
    conversationId = json['conversationId'];
    totalFiles = json['totalFiles'];
    successfulUploads = json['successfulUploads'];
    failedUploads = json['failedUploads'];
    if (json['files'] != null) {
      files = <Files>[];
      json['files'].forEach((v) {
        files!.add(new Files.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['conversationId'] = this.conversationId;
    data['totalFiles'] = this.totalFiles;
    data['successfulUploads'] = this.successfulUploads;
    data['failedUploads'] = this.failedUploads;
    if (this.files != null) {
      data['files'] = this.files!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Files {
  String? filename;
  String? url;
  String? messageId;
  bool? success;

  Files({this.filename, this.url, this.messageId, this.success});

  Files.fromJson(Map<String, dynamic> json) {
    filename = json['filename'];
    url = json['url'];
    messageId = json['messageId'];
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['filename'] = this.filename;
    data['url'] = this.url;
    data['messageId'] = this.messageId;
    data['success'] = this.success;
    return data;
  }
}
