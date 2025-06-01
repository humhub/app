import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HeadlessBackgroundRequest {
  final String targetUrl;
  final Map<String, dynamic> postData;
  final Map<String, String>? headers;
  final Duration timeout;

  HeadlessBackgroundRequest({
    required this.targetUrl,
    required this.postData,
    this.headers,
    this.timeout = const Duration(seconds: 30),
  });

  Future<Map<String, dynamic>?> execute() async {
    final completer = Completer<Map<String, dynamic>?>();
    HeadlessInAppWebView? headlessWebView;

    try {
      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(targetUrl))),
        onWebViewCreated: (controller) async {
          await _setupJavaScriptHandlers(controller, completer, headlessWebView);
        },
        onLoadStop: (controller, url) async {
          await _executePostRequest(controller);
        },
        onReceivedError: (controller, request, error) {
          if (!completer.isCompleted) {
            completer.complete({'error': 'Load error: ${error.description}'});
          }
          headlessWebView?.dispose();
        },
      );

      await headlessWebView.run();

      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          headlessWebView?.dispose();
          return {'error': 'Request timeout after ${timeout.inSeconds} seconds'};
        },
      );
    } catch (e) {
      headlessWebView?.dispose();
      return {'error': 'Exception: ${e.toString()}'};
    }
  }

  Future<void> _setupJavaScriptHandlers(
    InAppWebViewController controller,
    Completer<Map<String, dynamic>?> completer,
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
          completer.complete({'error': args.isNotEmpty ? args[0] : 'Unknown error'});
        }
        headlessWebView?.dispose();
      },
    );
  }

  Future<void> _executePostRequest(InAppWebViewController controller) async {
    String jsonData = jsonEncode(postData);
    String jsonHeaders = jsonEncode(headers ?? {});

    String jsCode = """
      (function() {
        try {
          const postData = JSON.parse('$jsonData');
          const headers = JSON.parse('$jsonHeaders');
          
          // Wait for page to be fully loaded
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', performRequest);
          } else {
            performRequest();
          }
          
          function performRequest() {
            fetch('$targetUrl', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                ...headers
              },
              body: JSON.stringify(postData)
            })
            .then(response => {
              if (!response.ok) {
                throw new Error(`HTTP \${response.status}: \${response.statusText}`);
              }
              return response.json();
            })
            .then(data => {
              window.flutter_inappwebview.callHandler('onPostSuccess', data);
            })
            .catch(error => {
              window.flutter_inappwebview.callHandler('onPostError', error.message);
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
