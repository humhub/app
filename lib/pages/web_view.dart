import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loggy/loggy.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:humhub/models/channel_message.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/models/manifest_with_remote_msg.dart';
import 'package:humhub/pages/opener/opener.dart';
import 'package:humhub/pages/console.dart';
import 'package:humhub/l10n/generated/app_localizations.dart';
import 'package:humhub/util/auth_in_app_browser.dart';
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
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/push/provider.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:humhub/util/router.dart' as m;


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

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  StreamSubscription<bool>? _keyboardSubscription;
  final KeyboardVisibilityController _keyboardVisibilityController = KeyboardVisibilityController();
  EdgeInsets get noKeyboardBottomPadding => MediaQuery.of(context).padding.copyWith(bottom: 0);
  late EdgeInsets initKeyboardPadding = MediaQuery.of(context).padding;
  bool keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        // Internet is back
        WebViewGlobalController.value?.reload();
      }
    });

    _keyboardSubscription = _keyboardVisibilityController.onChange.listen((bool visible) async {
      keyboardVisible = visible;
      await WebViewGlobalController.setWebViewSafeAreaPadding(safeArea: !keyboardVisible ? initKeyboardPadding : noKeyboardBottomPadding);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _initialRequest = _initRequest;
      logInfo('Initializing WebView with manifest: ${_manifest.name}');
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
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => exitApp(context, ref),
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
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT);
              },
            ),
          ),
        ),
      ),
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
      _manifest = m.AppRouter.initParams;
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
    await WebViewGlobalController.setWebViewSafeAreaPadding(safeArea: !keyboardVisible ? initKeyboardPadding : noKeyboardBottomPadding);

    if (WebViewGlobalController.isCommonURIScheme(webUri: action.request.url!)) {
      return WebViewGlobalController.handleCommonURISchemes(webUri: action.request.url!);
    }

    final url = action.request.url!.rawValue;

    logDebug('Navigation attempt: ${action.request.url}');

    /// First BLOCK everything that rules out as blocked.
    if (BlackListRules.check(url)) {
      logInfo('Blocked navigation to $url by blacklist rules');
      return NavigationActionPolicy.CANCEL;
    }
    // For SSO
    bool? isDomainTrusted = ref.read(humHubProvider).remoteConfig?.isTrustedDomain(action.request.url!.uriValue) ?? false;
    if ((!url.startsWith(_manifest.baseUrl) && action.isForMainFrame) && !isDomainTrusted) {
      logInfo('SSO detected, launching AuthInAppBrowser for $url');
      _authBrowser.launchUrl(action.request);
      return NavigationActionPolicy.CANCEL;
    }
    // For all other external links
    if (!url.startsWith(_manifest.baseUrl) && !action.isForMainFrame && action.navigationType == NavigationType.LINK_ACTIVATED) {
      logInfo('External link detected, launching external application for $url');
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

  _onLoadStop(InAppWebViewController controller, Uri? url) async {
    logDebug('Page load stopped: $url');
    // TODO RX
    if (url!.path.contains('/user/auth/login')) WebViewGlobalController.setLoginForm();
    WebViewGlobalController.ajaxSetHeaders(headers: ref.read(humHubProvider).customHeaders);
    WebViewGlobalController.listenToImageOpen();
    WebViewGlobalController.appendViewportFitCover();
    await WebViewGlobalController.setWebViewSafeAreaPadding(safeArea: !keyboardVisible ? initKeyboardPadding : noKeyboardBottomPadding);

    LoadingProvider.of(ref).dismissAll();
  }

  void _onLoadStart(InAppWebViewController controller, Uri? url) async {
    logDebug('Page load started: $url');
    WebViewGlobalController.ajaxSetHeaders(headers: ref.read(humHubProvider).customHeaders);
    WebViewGlobalController.listenToImageOpen();
    WebViewGlobalController.appendViewportFitCover();
    await WebViewGlobalController.setWebViewSafeAreaPadding(safeArea: !keyboardVisible ? initKeyboardPadding : noKeyboardBottomPadding);
  }

  _onProgressChanged(InAppWebViewController controller, int progress) {
    if (progress == 100) {
      _pullToRefreshController.endRefreshing();
      LoadingProvider.of(ref).dismissAll();
    }
  }

  void _onReceivedError(InAppWebViewController controller, WebResourceRequest request, WebResourceError error) {
    if ([WebResourceErrorType.NOT_CONNECTED_TO_INTERNET, WebResourceErrorType.TIMEOUT].contains(error.type)) {
      logWarning('No internet connection detected');
      NoConnectionDialog.show(context);
      LoadingProvider.of(ref).dismissAll();
    }
  }

  _concludeAuth(URLRequest request) {
    _authBrowser.close();
    WebViewGlobalController.value!.loadUrl(urlRequest: request);
  }

  Future<void> _handleJSMessage(ChannelMessage message, HeadlessInAppWebView headlessWebView) async {
    switch (message.action) {
      case ChannelAction.showOpener:
        logInfo('Action: showOpener');
        ref.read(humHubProvider).setOpenerState(OpenerState.shown);
        Navigator.of(context).pushNamedAndRemoveUntil(OpenerPage.path, (Route<dynamic> route) => false);
        break;
      case ChannelAction.hideOpener:
        logInfo('Action: hideOpener');
        ref.read(humHubProvider).setOpenerState(OpenerState.hidden);
        ref.read(humHubProvider).setHash(
              Crypt.generateRandomString(32),
            );
        break;
      case ChannelAction.registerFcmDevice:
        logInfo('Action: registerFcmDevice');
        String? token = ref.read(pushTokenProvider).value ?? await FirebaseMessaging.instance.getTokenSafe();
        if (token != null) {
          WebViewGlobalController.ajaxPost(
            url: message.url!,
            data: '{ token: \'$token\' }',
            headers: ref.read(humHubProvider).customHeaders,
          );
        }
        break;
      case ChannelAction.updateNotificationCount:
        logInfo('Action: updateNotificationCount');
        UpdateNotificationCountChannelData data = message.data as UpdateNotificationCountChannelData;
        AppBadgePlus.updateBadge(data.count);
        break;
      case ChannelAction.nativeConsole:
        logInfo('Action: nativeConsole');
        Navigator.of(context).pushNamed(ConsolePage.routeName);
        break;
      case ChannelAction.unregisterFcmDevice:
        logInfo('Action: unregisterFcmDevice');
        String? token = ref.read(pushTokenProvider).value ?? await FirebaseMessaging.instance.getTokenSafe();
        if (token != null) {
          WebViewGlobalController.ajaxPost(
            url: message.url!,
            data: '{ token: \'$token\' }',
            headers: ref.read(humHubProvider).customHeaders,
          );
        }
        break;
      case ChannelAction.fileUploadSettings:
        logInfo('Action: fileUploadSettings');
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
        logInfo('Action: none');
        break;
    }
  }

  Future<bool> exitApp(BuildContext context, WidgetRef ref) async {
    logInfo('Attempting to exit app');
    bool canGoBack = await WebViewGlobalController.value!.canGoBack();
    if (canGoBack) {
      logDebug('WebView can go back, navigating back');
      WebViewGlobalController.value!.goBack();
      return Future.value(false);
    } else {
      logDebug('Showing exit confirmation dialog');
      bool? exitConfirmed;
      if (context.mounted) {
        exitConfirmed = await showDialog<bool>(
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
      }
      return exitConfirmed ?? false;
    }
  }

  void _onDownloadStartRequest(InAppWebViewController controller, DownloadStartRequest downloadStartRequest) async {
    logInfo('Download started: ${downloadStartRequest.url}');
    PersistentBottomSheetController? persistentController;

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
        logInfo('Download succeeded: $filename at ${file.path}');
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
        logError('Download failed: $er');
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
    logInfo('Disposing WebView and controllers');
    if (_headlessWebView != null) _headlessWebView!.dispose();
    _subscription?.cancel();
    _keyboardSubscription?.cancel();
    super.dispose();
  }
}
