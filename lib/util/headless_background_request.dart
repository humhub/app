import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:loggy/loggy.dart';

class HeadlessBackgroundRequest {
  final String targetUrl;
  final String postUrl;
  final Map<String, dynamic>? postData;
  final Map<String, String>? headers;
  final Duration timeout;

  HeadlessBackgroundRequest({
    required this.targetUrl,
    required this.postUrl,
    this.postData,
    this.headers,
    this.timeout = const Duration(seconds: 30),
  });

  Future<void> execute() async {
    final completer = Completer<void>();
    HeadlessInAppWebView? headlessWebView;

    try {
      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(targetUrl)), headers: headers),
        onWebViewCreated: (controller) async {
          await _setupJavaScriptHandlers(controller, completer, headlessWebView);
        },
        onLoadStop: (controller, url) async {
          await _executePostRequest(controller);
        },
        onReceivedError: (controller, request, error) {
          if (!completer.isCompleted) {
            completer.complete();
            logError({'error': 'Exception: ${error.toString()}', 'request': request.toString()}, error, StackTrace.current);
          }
          headlessWebView?.dispose();
        },
      );

      await headlessWebView.run();

      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          headlessWebView?.dispose();
          logError('Request timeout after ${timeout.inSeconds} seconds');
        },
      );
    } catch (error, stackTrace) {
      headlessWebView?.dispose();
      logError('Exception: ${error.toString()}', error, stackTrace);
    }
  }

  Future<void> _setupJavaScriptHandlers(
    InAppWebViewController controller,
    Completer<void> completer,
    HeadlessInAppWebView? headlessWebView,
  ) async {
    controller.addJavaScriptHandler(
      handlerName: 'onPostSuccess',
      callback: (args) {
        if (!completer.isCompleted) {
          completer.complete(args.isNotEmpty ? args[0] : {});
        }
        headlessWebView?.dispose();
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onPostError',
      callback: (args) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        headlessWebView?.dispose();
      },
    );
  }

  Future<void> _executePostRequest(InAppWebViewController controller) async {
    String jsonData = jsonEncode(postData ?? {});
    String jsonHeaders = jsonEncode(headers ?? {});

    String jsCode = """
    (function() {
      try {
        var postData = $jsonData;
        var headers = $jsonHeaders;
    
        // Wait for page to be fully loaded
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', performRequest);
        } else {
          performRequest();
        }
    
        function performRequest() {
          if (typeof \$ === 'undefined') {
            window.flutter_inappwebview.callHandler('onPostError', 'jQuery is not loaded');
            return;
          }
          \$.ajax({
            url: '$postUrl',
            type: 'POST',
            data: JSON.stringify(postData),
            contentType: 'application/json',
            headers: headers,
            success: function(data) {
              window.flutter_inappwebview.callHandler('onPostSuccess', data);
            },
            error: function(jqXHR, textStatus, errorThrown) {
              var errorMsg = 'AJAX Error: ' + textStatus + ' ' + errorThrown + ' ' + jqXHR.responseText;
              window.flutter_inappwebview.callHandler('onPostError', errorMsg);
            }
          });
        }
      } catch (e) {
        window.flutter_inappwebview.callHandler('onPostError', e.message);
      }
    })();
    """;

    await controller.evaluateJavascript(source: jsCode);
  }
}
