import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/providers.dart';

class WebViewGlobalController {
  static InAppWebViewController? _value;

  static InAppWebViewController? get value => _value;

  /// [openCreateWindowInWebView]
  ///
  /// Determines if a URL should open in a new browser window or within the current web view.
  ///
  /// - Opens in a new window if:
  ///   - The URL is for file downloads ('file/download').
  ///   - The URL is a user profile redirect (`/u` after base URL).
  ///   - The URL is a space redirect (`/s` after base URL).
  ///
  /// [ref] is reference to the app state.
  /// [url] is the URL to evaluate.
  /// @return `true` if the URL should open in a new window, `false` otherwise.
  static bool openCreateWindowInWebView(WidgetRef ref, String url) {
    String? baseUrl = ref.read(humHubProvider).manifest?.baseUrl;
    // When app wants to open new window for file downloads
    if (url.startsWith('$baseUrl/file/file/download')) return true;
    // When app wants to open new window tag redirects (@username)
    if (url.startsWith('$baseUrl/u')) return true;
    // When app wants to open new window tag redirects (@space)
    if (url.startsWith('$baseUrl/s')) return true;
    return false;
  }

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
          });
    """;
    value?.evaluateJavascript(source: jsCode4);
  }

  static void ajaxSetHeaders({Map<String, String>? headers}) {
    String jsCode = "\$.ajaxSetup({headers: ${jsonEncode(headers).toString()}});";
    value?.evaluateJavascript(source: jsCode);
  }
}
