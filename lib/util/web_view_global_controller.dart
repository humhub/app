import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/models/manifest.dart';

class WebViewGlobalController {
  static InAppWebViewController? _value;

  static InAppWebViewController? get value => _value;

  /// [openCreateWindowInWebView]
  ///
  /// Determines if a URL should open in a new browser window or within the current web view.
  ///
  /// - Opens in a new window if:
  ///   - The URL is for file downloads (`file/file/download` after base URL).
  ///   - The URL is a @username profile redirect (`/u` after base URL).
  ///   - The URL is a @space redirect (`/s` after base URL).
  ///
  /// [ref] is reference to the app state.
  /// [url] is the URL to evaluate.
  /// @return `true` if the URL should open in a new window, `false` otherwise.
  static bool openCreateWindowInWebView({required String url, required Manifest manifest}) {
    String? baseUrl = manifest.baseUrl;
    if (url.startsWith('$baseUrl/file/file/download')) return true;
    if (url.startsWith('$baseUrl/u')) return true;
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
              async: false, // IMPORTANT: it needs to be sync
          });
    """;
    value?.evaluateJavascript(source: jsCode4);
  }

  static void ajaxSetHeaders({Map<String, String>? headers}) {
    String jsCode = "\$.ajaxSetup({headers: ${jsonEncode(headers).toString()}});";
    value?.evaluateJavascript(source: jsCode);
  }

  static void onLongPressHitTestResult(InAppWebViewController controller, InAppWebViewHitTestResult hitResult) async {
    if (hitResult.extra != null &&
        ([InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE, InAppWebViewHitTestResultType.EMAIL_TYPE]
            .contains(hitResult.type))) {
      Clipboard.setData(
        ClipboardData(text: hitResult.extra!),
      );
    }
  }

  static Future<void> listenToImageOpen() async {
    // Inject JavaScript to monitor changes to the blueimp-gallery element
    bool opened = false;
    await _value?.evaluateJavascript(source: """
            // Create a MutationObserver to monitor changes in the #blueimp-gallery element's attributes
            var observer = new MutationObserver(function(mutations) {
              mutations.forEach(function(mutation) {
                var galleryElement = document.getElementById('blueimp-gallery');
                
                // Check if the gallery is opened (display: block)
                if (galleryElement && galleryElement.style.display === 'block') {
                  // Send message to Flutter when the image gallery is opened
                  window.flutter_inappwebview.callHandler('onImageOpened');
                }
                
                // Check if the gallery is closed (display: none)
                if (galleryElement && galleryElement.style.display === 'none') {
                  // Send message to Flutter when the image gallery is closed
                  window.flutter_inappwebview.callHandler('onImageClosed');
                }
              });
            });

            // Observe changes in the style attribute of the #blueimp-gallery element
            var target = document.getElementById('blueimp-gallery');
            if (target) {
              observer.observe(target, { attributes: true, attributeFilter: ['style'] });
            }
          """);

    // Set up JavaScript handlers in Flutter to respond to image opening and closing events
    _value?.addJavaScriptHandler(
      handlerName: 'onImageOpened',
      callback: (args) {
        if (opened) return;
        opened = true;
        _value?.setSettings(settings: settings(zoom: opened));
      },
    );

    _value?.addJavaScriptHandler(
      handlerName: 'onImageClosed',
      callback: (args) {
        if (!opened) return;
        opened = false;
        _value?.setSettings(settings: settings(zoom: opened));
      },
    );
  }

  static void addMobileBottomPadding() {
    String jsCode = """
    (function() {
      var element = document.querySelector('#topbar > .container #top-menu-nav');
      if (element) {
          var bottomValue = window.getComputedStyle(element).getPropertyValue('bottom');
          if (bottomValue === '0px') {
              element.style.paddingBottom = '20px';
              console.log('Padding applied');
          } else {
              console.log('Padding not applied, bottom is not 0');
          }
      } else {
          console.log('Element not found');
      }
    })();
  """;
    value?.evaluateJavascript(source: jsCode);
  }

  /*static void addMobileBottomPadding() {
    String jsCode = """
    (function() {
      if (window.innerWidth <= 570) {
          // Check if the browser supports env(safe-area-inset-bottom)
          if (CSS.supports('padding-bottom', 'env(safe-area-inset-bottom)')) {
              document.getElementById('top-menu-nav').style.paddingBottom = 'env(safe-area-inset-bottom)';
          } else {
              // Fallback padding for unsupported browsers
              document.getElementById('top-menu-nav').style.paddingBottom = '20px';
          }
      }
    })();
  """;
    value?.evaluateJavascript(source: jsCode);
  }*/

  static InAppWebViewSettings settings({bool zoom = false}) {
    return InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      useShouldInterceptFetchRequest: true,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      supportMultipleWindows: true,
      useHybridComposition: true,
      allowsInlineMediaPlayback: true,
      mediaPlaybackRequiresUserGesture: false,
      supportZoom: zoom ? true : false,
    );
  }
}
