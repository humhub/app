import 'dart:async';
import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/auth_in_app_browser.dart';
import 'package:humhub/models/channel_message.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/pages/opener/opener.dart';
import 'package:humhub/util/black_list_rules.dart';
import 'package:humhub/util/connectivity_plugin.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/crypt.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/file_download_manager.dart';
import 'package:humhub/util/file_upload_manager.dart';
import 'package:humhub/util/init_from_url.dart';
import 'package:humhub/util/intent/intent_state.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:humhub/util/push/provider.dart';
import 'package:humhub/util/router.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:humhub/util/router.dart' as m;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'console.dart';

class WebView extends ConsumerStatefulWidget {
  const WebView({super.key});
  static const String path = '/web_view';

  @override
  WebViewAppState createState() => WebViewAppState();
}

class WebViewAppState extends ConsumerState<WebView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AuthInAppBrowser _authBrowser;
  late Manifest _manifest;
  late URLRequest _initialRequest;
  late PullToRefreshController _pullToRefreshController;
  HeadlessInAppWebView? _headlessWebView;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to the provider's state changes
    if (!_isInit) {
      _initialRequest = _initRequest;
      _pullToRefreshController = PullToRefreshController(
        settings: PullToRefreshSettings(
          color: HexColor(_manifest.themeColor),
        ),
        onRefresh: () async {
          if (Platform.isAndroid) {
            WebViewGlobalController.value?.reload();
          } else if (Platform.isIOS) {
            WebViewGlobalController.value
                ?.loadUrl(urlRequest: URLRequest(url: await WebViewGlobalController.value?.getUrl(), headers: ref.read(humHubProvider).customHeaders));
          }
        },
      );
      _authBrowser = AuthInAppBrowser(
        manifest: _manifest,
        concludeAuth: (URLRequest request) {
          _concludeAuth(request);
        },
      );
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: HexColor(_manifest.themeColor),
      body: SafeArea(
          bottom: false,
          // ignore: deprecated_member_use
          child: WillPopScope(
            onWillPop: () => exitApp(context, ref),
            child: FileUploadManagerWidget(
              child: InAppWebView(
                  initialUrlRequest: _initialRequest,
                  initialSettings: WebViewGlobalController.settings(),
                  pullToRefreshController: _pullToRefreshController,
                  shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
                  onWebViewCreated: _onWebViewCreated,
                  shouldInterceptFetchRequest: _shouldInterceptFetchRequest,
                  onCreateWindow: _onCreateWindow,
                  onLoadStop: _onLoadStop,
                  onLoadStart: _onLoadStart,
                  onProgressChanged: _onProgressChanged,
                  onReceivedError: _onReceivedError,
                  onDownloadStartRequest: _onDownloadStartRequest,
                  onLongPressHitTestResult: WebViewGlobalController.onLongPressHitTestResult,
                  onReceivedHttpError: (controller, request, errorResponse) {
                    logError(errorResponse);
                  }),
            ),
          )),
    );
  }

  URLRequest get _initRequest {
    final args = ModalRoute.of(context)!.settings.arguments;
    String? url;
    if (args is Manifest) {
      _manifest = args;
    }
    if (args is UniversalOpenerController) {
      UniversalOpenerController controller = args;
      ref.read(humHubProvider).setInstance(controller.humhub);
      _manifest = controller.humhub.manifest!;
      url = controller.url;
    }
    if (args == null) {
      _manifest = m.MyRouter.initParams;
    }
    if (args is ManifestWithRemoteMsg) {
      ManifestWithRemoteMsg manifestPush = args;
      _manifest = manifestPush.manifest;
      url = manifestPush.remoteMessage.data['url'];
    }
    String? payloadFromPush = InitFromUrl.usePayload();
    if (payloadFromPush != null) url = payloadFromPush;
    return URLRequest(url: WebUri(url ?? _manifest.startUrl), headers: ref.read(humHubProvider).customHeaders);
  }

  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(InAppWebViewController controller, NavigationAction action) async {
    WebViewGlobalController.ajaxSetHeaders(headers: ref.read(humHubProvider).customHeaders);
    WebViewGlobalController.listenToImageOpen();
    WebViewGlobalController.appendViewportFitCover();

    final url = action.request.url!.rawValue;

    /// First BLOCK everything that rules out as blocked.
    if (BlackListRules.check(url)) {
      return NavigationActionPolicy.CANCEL;
    }
    // For SSO
    if (!url.startsWith(_manifest.baseUrl) && action.isForMainFrame) {
      _authBrowser.launchUrl(action.request);
      return NavigationActionPolicy.CANCEL;
    }
    // For all other external links
    if (!url.startsWith(_manifest.baseUrl) && !action.isForMainFrame && action.navigationType == NavigationType.LINK_ACTIVATED) {
      await launchUrl(action.request.url!.uriValue, mode: LaunchMode.externalApplication);
      return NavigationActionPolicy.CANCEL;
    }
    // 2nd Append customHeader if url is in app redirect and CANCEL the requests without custom headers
    if (Platform.isAndroid || action.navigationType == NavigationType.LINK_ACTIVATED || action.navigationType == NavigationType.FORM_SUBMITTED) {
      Map<String, String> mergedMap = {...?_initialRequest.headers, ...?action.request.headers};
      URLRequest newRequest = action.request.copyWith(headers: mergedMap);
      controller.loadUrl(urlRequest: newRequest);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  _onWebViewCreated(InAppWebViewController controller) async {
    LoadingProvider.of(ref).showLoading();
    _headlessWebView = HeadlessInAppWebView();
    _headlessWebView!.run();
    await controller.addWebMessageListener(
      WebMessageListener(
        jsObjectName: "flutterChannel",
        onPostMessage: (inMessage, sourceOrigin, isMainFrame, replyProxy) async {
          logInfo(inMessage);
          ChannelMessage message = ChannelMessage.fromJson(inMessage!.data);
          await _handleJSMessage(message, _headlessWebView!);
          logDebug('flutterChannel triggered: ${message.type}');
        },
      ),
    );
    WebViewGlobalController.setValue(controller);
  }

  Future<FetchRequest?> _shouldInterceptFetchRequest(InAppWebViewController controller, FetchRequest request) async {
    logDebug("_shouldInterceptFetchRequest");
    request.headers?.addAll(_initialRequest.headers!);
    return request;
  }

  Future<bool?> _onCreateWindow(InAppWebViewController controller, CreateWindowAction createWindowAction) async {
    WebUri? urlToOpen = createWindowAction.request.url;

    if (urlToOpen == null) return Future.value(false);
    if (WebViewGlobalController.openCreateWindowInWebView(
      url: urlToOpen.rawValue,
      manifest: ref.read(humHubProvider).manifest!,
    )) {
      controller.loadUrl(urlRequest: createWindowAction.request);
      return Future.value(false);
    }

    if (await canLaunchUrl(urlToOpen)) {
      await launchUrl(urlToOpen, mode: LaunchMode.externalApplication);
    } else {
      logError('Could not launch $urlToOpen');
    }

    return Future.value(true);
  }

  _onLoadStop(InAppWebViewController controller, Uri? url) {
    // Disable remember me checkbox on login and set def. value to true: check if the page is actually login page, if it is inject JS that hides element
    if (url!.path.contains('/user/auth/login')) {
      WebViewGlobalController.value!.evaluateJavascript(source: "document.querySelector('#login-rememberme').checked=true");
      WebViewGlobalController.value!
          .evaluateJavascript(source: "document.querySelector('#account-login-form > div.form-group.field-login-rememberme').style.display='none';");
    }
    WebViewGlobalController.ajaxSetHeaders(headers: ref.read(humHubProvider).customHeaders);
    WebViewGlobalController.listenToImageOpen();
    WebViewGlobalController.appendViewportFitCover();
    LoadingProvider.of(ref).dismissAll();
  }

  void _onLoadStart(InAppWebViewController controller, Uri? url) async {
    WebViewGlobalController.ajaxSetHeaders(headers: ref.read(humHubProvider).customHeaders);
    WebViewGlobalController.listenToImageOpen();
    WebViewGlobalController.appendViewportFitCover();
  }

  _onProgressChanged(InAppWebViewController controller, int progress) {
    if (progress == 100) {
      _pullToRefreshController.endRefreshing();
    }
  }

  void _onReceivedError(InAppWebViewController controller, WebResourceRequest request, WebResourceError error) {
    if (error.description == 'net::ERR_INTERNET_DISCONNECTED') {
      NoConnectionDialog.show(context);
    }
  }

  _concludeAuth(URLRequest request) {
    _authBrowser.close();
    WebViewGlobalController.value!.loadUrl(urlRequest: request);
  }

  Future<void> _handleJSMessage(ChannelMessage message, HeadlessInAppWebView headlessWebView) async {
    switch (message.action) {
      case ChannelAction.showOpener:
        ref.read(humHubProvider).setOpenerState(OpenerState.shown);
        Navigator.of(context).pushNamedAndRemoveUntil(OpenerPage.path, (Route<dynamic> route) => false);
        break;
      case ChannelAction.hideOpener:
        ref.read(humHubProvider).setOpenerState(OpenerState.hidden);
        ref.read(humHubProvider).setHash(
              Crypt.generateRandomString(32),
            );
        break;
      case ChannelAction.registerFcmDevice:
        String? token = ref.read(pushTokenProvider).value ?? await FirebaseMessaging.instance.getToken();
        if (token != null) {
          WebViewGlobalController.ajaxPost(
            url: message.url!,
            data: '{ token: \'$token\' }',
            headers: ref.read(humHubProvider).customHeaders,
          );
        }
        break;
      case ChannelAction.updateNotificationCount:
        UpdateNotificationCountChannelData data = message.data as UpdateNotificationCountChannelData;
        AppBadgePlus.updateBadge(data.count);
        break;
      case ChannelAction.nativeConsole:
        Navigator.of(context).pushNamed(ConsolePage.routeName);
        break;
      case ChannelAction.unregisterFcmDevice:
        String? token = ref.read(pushTokenProvider).value ?? await FirebaseMessaging.instance.getToken();
        if (token != null) {
          WebViewGlobalController.ajaxPost(
            url: message.url!,
            data: '{ token: \'$token\' }',
            headers: ref.read(humHubProvider).customHeaders,
          );
        }
        break;
      case ChannelAction.fileUploadSettings:
        FileUploadSettingsChannelData data = message.data as FileUploadSettingsChannelData;
        ref.read(humHubProvider.notifier).setFileUploadSettings(data.settings);
        FileUploadManager(
                webViewController: WebViewGlobalController.value!,
                intentNotifier: ref.read(intentProvider.notifier),
                fileUploadSettings: ref.read(humHubProvider).fileUploadSettings,
                context: context)
            .upload();
        break;
      case ChannelAction.none:
        break;
    }
  }

  Future<bool> exitApp(BuildContext context, WidgetRef ref) async {
    bool canGoBack = await WebViewGlobalController.value!.canGoBack();
    if (canGoBack) {
      WebViewGlobalController.value!.goBack();
      return Future.value(false);
    } else {
      final exitConfirmed = await showDialog<bool>(
        // ignore: use_build_context_synchronously
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
                ref.read(humHubProvider).openerState.isShown
                    ? Navigator.of(context).pushNamedAndRemoveUntil(OpenerPage.path, (Route<dynamic> route) => false)
                    : SystemNavigator.pop();
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
    PersistentBottomSheetController? persistentController;
    //bool isBottomSheetVisible = false;

    // Initialize the download progress
    double downloadProgress = 0;

    // Timer to control when to show the bottom sheet
    Timer? downloadTimer;
    bool isDone = false;

    FileDownloadManager(
      downloadStartRequest: downloadStartRequest,
      controller: controller,
      onSuccess: (File file, String filename) async {
        // Hide the bottom sheet if it is visible
        Navigator.popUntil(context, ModalRoute.withName(WebView.path));
        isDone = true;
        Keys.scaffoldMessengerStateKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.file_download}: $filename'),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.open,
              onPressed: () {
                //file.open();
                OpenFile.open(file.path);
              },
            ),
          ),
        );
      },
      onStart: () async {
        downloadProgress = 0;
        // Start the timer for 1 second
        downloadTimer = Timer(const Duration(seconds: 1), () {
          // Show the persistent bottom sheet if not already shown
          if (!isDone) {
            persistentController = _scaffoldKey.currentState!.showBottomSheet((context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                height: 100,
                color: const Color(0xff313033),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.downloading}...",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: downloadProgress / 100,
                            backgroundColor: Colors.grey,
                            color: Colors.green,
                          ),
                          downloadProgress.toStringAsFixed(0) == "100"
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 25,
                                )
                              : Text(
                                  downloadProgress.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            });
          }
        });
      },
      onProgress: (progress) async {
        downloadProgress = progress;
        if (persistentController != null) {
          persistentController!.setState!(() {});
        }
      },
      onError: (er) {
        downloadTimer?.cancel();
        if (persistentController != null) {
          Navigator.popUntil(context, ModalRoute.withName(WebView.path));
        }
        Keys.scaffoldMessengerStateKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.generic_error),
          ),
        );
      },
    ).download();

    // Ensure to cancel the timer if download finishes before 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (downloadProgress >= 100) {
        downloadTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    if (_headlessWebView != null) _headlessWebView!.dispose();
    _pullToRefreshController.dispose();
    super.dispose();
  }
}
