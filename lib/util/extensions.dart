import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/pages/opener.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/providers.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension MyWebViewController on InAppWebViewController {

  Future<bool> exitApp(context, ref) async {
    bool canGoBack = await this.canGoBack();
    if (canGoBack) {
      goBack();
      return Future.value(false);
    } else {
      final exitConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.web_view_exit_popup_title),
          content: Text(AppLocalizations.of(context)!.web_view_exit_popup_content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                closeOrOpenDialog(context, ref);
              },
              child: Text(AppLocalizations.of(context)!.yes),
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
        : Navigator.of(context).pushNamedAndRemoveUntil(Opener.path, (Route<dynamic> route) => false);
  }
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor";
      }
      return int.parse(hexColor, radix: 16);
    } catch (e) {
      logError("Color from manifest is not valid use primary color");
      return primaryColor.value;
    }
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

extension IterableX<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }

  void forEachIndexed(void Function(E e, int i) f) {
    var i = 0;
    forEach((e) => f(e, i++));
  }

  Map<Y, List<E>> groupBy<Y>(Y Function(E e) fn) {
    return Map.fromIterable(
      map(fn).toSet(),
      value: (i) => where((v) => fn(v) == i).toList(),
    );
  }

  Iterable<E> distinctBy<Key>(Key Function(E element) by) {
    final keys = <dynamic>{};
    return where((item) {
      final key = by(item);
      if (!keys.contains(key)) {
        keys.add(key);
        return true;
      } else {
        return false;
      }
    });
  }
}

extension URLRequestExtension on URLRequest {
  URLRequest copyWith({
    Uri? url,
    String? method,
    Uint8List? body,
    Map<String, String>? headers,
    bool? iosAllowsCellularAccess,
    bool? iosAllowsConstrainedNetworkAccess,
    bool? iosAllowsExpensiveNetworkAccess,
    IOSURLRequestCachePolicy? iosCachePolicy,
    bool? iosHttpShouldHandleCookies,
    bool? iosHttpShouldUsePipelining,
    IOSURLRequestNetworkServiceType? iosNetworkServiceType,
    double? iosTimeoutInterval,
    Uri? iosMainDocumentURL,
  }) {
    return URLRequest(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      iosAllowsCellularAccess: iosAllowsCellularAccess ?? this.iosAllowsCellularAccess,
      iosAllowsConstrainedNetworkAccess: iosAllowsConstrainedNetworkAccess ?? this.iosAllowsConstrainedNetworkAccess,
      iosAllowsExpensiveNetworkAccess: iosAllowsExpensiveNetworkAccess ?? this.iosAllowsExpensiveNetworkAccess,
      iosCachePolicy: iosCachePolicy ?? this.iosCachePolicy,
      iosHttpShouldHandleCookies: iosHttpShouldHandleCookies ?? this.iosHttpShouldHandleCookies,
      iosHttpShouldUsePipelining: iosHttpShouldUsePipelining ?? this.iosHttpShouldUsePipelining,
      iosNetworkServiceType: iosNetworkServiceType ?? this.iosNetworkServiceType,
      iosTimeoutInterval: iosTimeoutInterval ?? this.iosTimeoutInterval,
      iosMainDocumentURL: iosMainDocumentURL ?? this.iosMainDocumentURL,
    );
  }
}
