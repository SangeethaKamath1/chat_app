class JoinGroupCallDataResponse {
  String? url;
  String? token;

  JoinGroupCallDataResponse({this.url, this.token});

  JoinGroupCallDataResponse.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['token'] = this.token;
    return data;
  }
}