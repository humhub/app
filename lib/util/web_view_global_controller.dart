import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewGlobalController {
  static InAppWebViewController? _value;

  static InAppWebViewController? get value => _value;

  static void setValue(InAppWebViewController newValue) {
    _value = newValue;
  }

  static void ajaxPost({required String url, required String data, Map<String, String>? headers}) {
    String jsonHeaders = jsonEncode(headers);
    String jsCode4 = """
          \$.ajax({
              url: '$url',
              type: 'POST',
              data: $data,
              headers: $jsonHeaders,
              async: false, // IMPORTANT: it needs to be async
              success: function(data) {
                  console.log('MD-1222');
              },
              error: function(xhr, status, error) {
                  console.log('MD-1333');
                  console.log(error);
                  console.log(status);
                  console.log(xhr);
              }
          });
    """;
    value?.evaluateJavascript(source: jsCode4);
  }

  static void ajaxSetHeaders({Map<String, String>? headers}) {
    String jsCode = "\$.ajaxSetup({headers: ${jsonEncode(headers).toString()}});";
    value?.evaluateJavascript(source: jsCode);
  }
}
