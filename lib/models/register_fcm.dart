import 'package:dio/dio.dart';

class RegisterFcm {
  final String type;
  final String url;

  RegisterFcm(this.type, this.url);

  factory RegisterFcm.fromJson(Map<String, dynamic> json) {
    return RegisterFcm(
      json['type'] as String,
      json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
      };

  Future<Response> Function(Dio dio) post(token) => (dio) async {
        return await dio.post(url, data: {'token': token});
      };
}
