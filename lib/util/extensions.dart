import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/pages/opener.dart';
import 'package:humhub/util/providers.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore_for_file: use_build_context_synchronously
extension MyCookies on WebViewCookieManager {
  Future<void> setMyCookies(Manifest manifest) async {
    await setCookie(
      WebViewCookie(
        name: 'is_mobile_app',
        value: 'true',
        domain: manifest.baseUrl,
      ),
    );
  }
}

extension MyWebViewController on InAppWebViewController {
  Future<bool> exitApp(BuildContext context, ref) async {
    bool canGoBack = await this.canGoBack();
    if (canGoBack) {
      goBack();
      return Future.value(false);
    } else {
      final exitConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to exit an App'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                closeOrOpenDialog(context, ref);
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      return exitConfirmed ?? false;
    }
  }

  closeOrOpenDialog(BuildContext context, WidgetRef ref) {
    var isHide = ref.read(humHubProvider).isHideDialog;
    isHide
        ? SystemNavigator.pop()
        : Navigator.of(context).pushNamedAndRemoveUntil(
            Opener.path, (Route<dynamic> route) => false);
  }
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

extension AsyncValueX<T> on AsyncValue<T> {
  bool get isLoading => asData == null;

  bool get isLoaded => asData != null;

  bool get isError => this is AsyncError;

  AsyncError get asError => this as AsyncError;

  T? get valueOrNull => asData?.value;
}

extension FutureAsyncValueX<T> on Future<AsyncValue<T>> {
  Future<T?> get valueOrNull => then(
        (asyncValue) => asyncValue.asData?.value,
  );
}

