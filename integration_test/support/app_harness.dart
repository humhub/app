import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/pages/opener/components/search_bar.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/intent/app_link_settings.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/router.dart';
import 'package:humhub/util/storage_service.dart';
import 'package:humhub/util/web_view_global_controller.dart';

import 'e2e_env.dart';

export 'package:humhub/pages/opener/components/search_bar.dart' show openerUrlField, openerConnectButton;

const _loginPath = '/user/auth/login';

/// Boots the real app (as lib/main.dart does) from a clean state and drives
/// it against the e2e backend.
class AppHarness {
  AppHarness._(this.container);

  final ProviderContainer container;

  InAppWebViewController get webViewController => WebViewGlobalController.value!;

  static Future<AppHarness> boot(WidgetTester tester) async {
    E2eEnv.require();

    final app = await HumHub.initApp();
    // App data and cookies can survive between test files on the same
    // device, so every test starts from a fresh install state.
    await SecureStorageService.instance.deleteAll();
    await CookieManager.instance().deleteAllCookies();
    // A previous test's WebView controller would satisfy waitForWebView early.
    WebViewGlobalController.reset();
    // Otherwise the opener pushes the first-launch settings page over itself.
    await SecureStorageService.setVisitedSettings();

    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Same startup sequence as lib/main.dart.
    final instance = await container.read(humHubProvider).getInstance();
    await AppLinkSettings.refresh();
    await AppRouter.initInitialRoute(instance);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: app));
    // The opener's Rive animations never settle, so poll instead of pumpAndSettle.
    await waitUntil(tester, () => find.byKey(openerUrlField).evaluate().isNotEmpty);
    return AppHarness._(container);
  }

  /// Connects to the e2e backend through the opener and waits for the WebView.
  Future<void> connect(WidgetTester tester) async {
    await tester.enterText(find.byKey(openerUrlField), E2eEnv.serverUrl);
    await tester.pump();
    await tester.tap(find.byKey(openerConnectButton));
    await waitForWebView(tester);
  }

  /// Fills in and submits HumHub's login form inside the WebView.
  Future<void> login(WidgetTester tester) async {
    await waitForUrl(tester, (url) => url.path.contains(_loginPath));
    await waitUntil(tester, () async {
      final found = await webViewController.evaluateJavascript(source: "document.querySelector('#login_username') !== null");
      return found == true;
    });
    await webViewController.evaluateJavascript(source: '''
      (function() {
        var form = document.querySelector('#account-login-form');
        form.querySelector('#login_username').value = ${jsonEncode(E2eEnv.username)};
        form.querySelector('#login_password').value = ${jsonEncode(E2eEnv.password)};
        form.submit();
      })();
    ''');
    await waitForUrl(tester, (url) => !url.path.contains(_loginPath));
    // getUrl() switches before the next document replaces the login page; JS run
    // in between (e.g. the share upload) would send the pre-login CSRF token.
    await waitUntil(tester, () async {
      if (await webViewController.isLoading()) return false;
      final loaded = await webViewController.evaluateJavascript(
          source: "document.readyState === 'complete' && !location.pathname.includes(${jsonEncode(_loginPath)})");
      return loaded == true;
    }, timeout: const Duration(seconds: 60));
  }

  Future<void> connectAndLogin(WidgetTester tester) async {
    await connect(tester);
    await login(tester);
  }

  Future<Uri?> currentUrl() async => (await WebViewGlobalController.value?.getUrl())?.uriValue;

  static Future<void> waitForWebView(WidgetTester tester) async {
    await waitUntil(
      tester,
      () => find.byType(WebView).evaluate().isNotEmpty && WebViewGlobalController.value != null,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> waitForUrl(
    WidgetTester tester,
    bool Function(Uri url) matches, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await waitUntil(tester, () async {
      final url = await currentUrl();
      return url != null && matches(url);
    }, timeout: timeout);
  }

  /// Pumps frames until [condition] holds or [timeout] elapses.
  static Future<void> waitUntil(
    WidgetTester tester,
    FutureOr<bool> Function() condition, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 250),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(step);
      if (await condition()) return;
    }
    throw TimeoutException('Condition not met within $timeout');
  }
}
