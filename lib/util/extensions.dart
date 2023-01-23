import 'package:flutter/material.dart';
import 'package:humhub/util/manifest.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

extension MyWebViewController on WebViewController {
  Future<bool> exitApp(BuildContext context) async {
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
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      return exitConfirmed ?? false;
    }
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