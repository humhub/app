import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/app_flavored.dart';
import 'package:humhub/flavored/models/humhub.f.dart';
import 'package:humhub/util/auth_in_app_browser.dart';
import 'package:humhub/models/channel_message.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/notifications/init_from_push.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/push/provider.dart';
import 'package:humhub/util/show_dialog.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:humhub/util/file_handler.dart';
import 'package:open_file_plus/open_file_plus.dart';

class WebViewF extends ConsumerStatefulWidget {
  static const String path = '/web_view_f';
  const WebViewF({super.key});

  @override
  FlavoredWebViewState createState() => FlavoredWebViewState();
}

class FlavoredWebViewState extends ConsumerState<WebViewF> {
  late AuthInAppBrowser _authBrowser;
  HeadlessInAppWebView? headlessWebView;
  late HumHubF instance;

  late PullToRefreshController pullToRefreshController;

  @override
  void initState() {
    instance = ref.read(humHubFProvider).value!;
    _authBrowser = AuthInAppBrowser(
      manifest: ref.read(humHubFProvider).value!.manifest,
      concludeAuth: (URLRequest request) {
        _concludeAuth(request);
      },
    );
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: HexColor(instance.manifest.themeColor),
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          WebViewGlobalController.value?.reload();
        } else if (Platform.isIOS) {
          WebViewGlobalController.value?.loadUrl(
              urlRequest:
                  URLRequest(url: await WebViewGlobalController.value?.getUrl(), headers: instance.customHeaders));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () => exitApp(context, ref),
      child: Scaffold(
        backgroundColor: HexColor(instance.manifest.themeColor),
        body: SafeArea(
          bottom: false,
          child: InAppWebView(
            initialUrlRequest: _initialRequest,
            initialSettings: _settings,
            pullToRefreshController: pullToRefreshController,
            shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
            shouldInterceptFetchRequest: _shouldInterceptFetchRequest,
            onWebViewCreated: _onWebViewCreated,
            onCreateWindow: _onCreateWindow,
            onLoadStop: _onLoadStop,
            onLoadStart: _onLoadStart,
            onReceivedError: _onLoadError,
            onProgressChanged: _onProgressChanged,
            onDownloadStartRequest: _onDownloadStartRequest,
          ),
        ),
      ),
    );
  }

  URLRequest get _initialRequest {
    var payload = ModalRoute.of(context)!.settings.arguments;
    String? url = instance.manifest.startUrl;
    String? payloadForInitFromPush = InitFromPush.usePayload();
    String? payloadFromPush;
    if (payload is String) payloadFromPush = payload;
    if (payloadForInitFromPush != null) url = payloadForInitFromPush;
    if (payloadFromPush != null) url = payloadFromPush;
    return URLRequest(url: WebUri(url), headers: instance.customHeaders);
  }

  InAppWebViewSettings get _settings => InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        useShouldInterceptFetchRequest: true,
        javaScriptEnabled: true,
        supportZoom: false,
        javaScriptCanOpenWindowsAutomatically: true,
        supportMultipleWindows: true,
        useHybridComposition: true,
        allowsInlineMediaPlayback: true,
      );

  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction action) async {
    // 1st check if url is not def. app url and open it in a browser or inApp.
    WebViewGlobalController.ajaxSetHeaders(headers: instance.customHeaders);
    final url = action.request.url!.origin;
    if (!url.startsWith(instance.manifest.baseUrl) && action.isForMainFrame) {
      _authBrowser.launchUrl(action.request);
      return NavigationActionPolicy.CANCEL;
    }
    // 2nd Append customHeader if url is in app redirect and CANCEL the requests without custom headers
    if (Platform.isAndroid ||
        action.navigationType == NavigationType.LINK_ACTIVATED ||
        action.navigationType == NavigationType.FORM_SUBMITTED) {
      Map<String, String> mergedMap = {...instance.customHeaders, ...?action.request.headers};
      URLRequest newRequest = action.request.copyWith(headers: mergedMap);
      controller.loadUrl(urlRequest: newRequest);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    LoadingProvider.of(ref).showLoading();
    headlessWebView = HeadlessInAppWebView();
    headlessWebView!.run();
    await controller.addWebMessageListener(
      WebMessageListener(
        jsObjectName: "flutterChannel",
        onPostMessage: (inMessage, sourceOrigin, isMainFrame, replyProxy) async {
          ChannelMessage message = ChannelMessage.fromJson(inMessage!.data);
          await _handleJSMessage(message, headlessWebView!);
        },
      ),
    );
    WebViewGlobalController.setValue(controller);
  }

  Future<FetchRequest?> _shouldInterceptFetchRequest(InAppWebViewController controller, FetchRequest request) async {
    request.headers!.addAll(_initialRequest.headers!);
    return request;
  }

  Future<bool> _onCreateWindow(InAppWebViewController controller, CreateWindowAction createWindowAction) async {
    logDebug("onCreateWindow");
    final urlToOpen = createWindowAction.request.url;
    if (urlToOpen == null) return Future.value(false);
    if (WebViewGlobalController.openCreateWindowInWebView(ref, urlToOpen.rawValue)) {
      controller.loadUrl(urlRequest: createWindowAction.request);
      return Future.value(false);
    }
    if (await canLaunchUrl(urlToOpen)) {
      await launchUrl(urlToOpen, mode: LaunchMode.externalApplication);
    } else {
      logError('Could not launch $urlToOpen');
    }
    return Future.value(true); // Allow creating a new window.
  }

  Future<void> _onLoadStop(InAppWebViewController controller, Uri? url) async {
    // Disable remember me checkbox on login and set def. value to true: check if the page is actually login page, if it is inject JS that hides element
    if (url!.path.contains('/user/auth/login')) {
      WebViewGlobalController.value!
          .evaluateJavascript(source: "document.querySelector('#login-rememberme').checked=true");
      WebViewGlobalController.value!.evaluateJavascript(
          source:
              "document.querySelector('#account-login-form > div.form-group.field-login-rememberme').style.display='none';");
    }
    WebViewGlobalController.ajaxSetHeaders(headers: instance.customHeaders);
    LoadingProvider.of(ref).dismissAll();
  }

  void _onLoadStart(InAppWebViewController controller, Uri? url) async {
    WebViewGlobalController.ajaxSetHeaders(headers: instance.customHeaders);
  }

  void _onLoadError(InAppWebViewController controller, WebResourceRequest request, WebResourceError error) async {
    logError(error);
    if (error.description == 'net::ERR_INTERNET_DISCONNECTED') ShowDialog.of(context).noInternetPopup();
    pullToRefreshController.endRefreshing();
  }

  void _onProgressChanged(controller, progress) async {
    if (progress == 100) {
      pullToRefreshController.endRefreshing();
    }
  }

  void _concludeAuth(URLRequest request) {
    _authBrowser.close();
    WebViewGlobalController.value!.loadUrl(urlRequest: request);
  }

  Future<void> _handleJSMessage(ChannelMessage message, HeadlessInAppWebView headlessWebView) async {
    switch (message.action) {
      case ChannelAction.registerFcmDevice:
        String? token = ref.read(pushTokenProvider).value ?? await FirebaseMessaging.instance.getToken();
        if (token != null) {
          WebViewGlobalController.ajaxPost(
            url: message.url!,
            data: '{ token: \'$token\' }',
            headers: instance.customHeaders,
          );
        }
        var status = await Permission.notification.status;
        // status.isDenied: The user has previously denied the notification permission
        // !status.isGranted: The user has never been asked for the notification permission
        bool wasAskedBefore = await NotificationPlugin.hasAskedPermissionBefore();
        // ignore: use_build_context_synchronously
        if (status != PermissionStatus.granted && !wasAskedBefore) ShowDialog.of(context).notificationPermission();
        break;
      case ChannelAction.updateNotificationCount:
        if (message.count != null) FlutterAppBadger.updateBadgeCount(message.count!);
        break;
      case ChannelAction.unregisterFcmDevice:
        String? token = ref.read(pushTokenProvider).value;
        if (token != null) {
          WebViewGlobalController.ajaxPost(
            url: message.url!,
            data: '{ token: \'$token\' }',
            headers: instance.customHeaders,
          );
        }
        break;
      default:
        break;
    }
  }

  Future<bool> exitApp(context, ref) async {
    bool canGoBack = await WebViewGlobalController.value!.canGoBack();
    if (canGoBack) {
      WebViewGlobalController.value!.goBack();
      return Future.value(false);
    } else {
      final exitConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: Text(AppLocalizations.of(context)!.web_view_exit_popup_title),
          content: Text(AppLocalizations.of(context)!.web_view_exit_popup_content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        ),
      );
      return exitConfirmed ?? false;
    }
  }

  void _onDownloadStartRequest(InAppWebViewController controller, DownloadStartRequest downloadStartRequest) async {
    FileHandler(
        downloadStartRequest: downloadStartRequest,
        controller: controller,
        onSuccess: (File file, String filename) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File downloaded: $filename'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  // Open the downloaded file
                  OpenFile.open(file.path);
                },
              ),
            ),
          );
        },
        onError: (er) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong'),
            ),
          );
        }).download();
  }

  @override
  void dispose() {
    super.dispose();
    if (headlessWebView != null) {
      headlessWebView!.dispose();
    }
  }
}
