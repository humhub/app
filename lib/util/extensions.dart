import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/theme_data.dart';
import 'package:loggy/loggy.dart';

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
      return HumhubTheme.primaryColor.value;
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

extension URLRequestExtension on URLRequest {
  URLRequest copyWith({
    WebUri? url,
    String? method,
    Uint8List? body,
    Map<String, String>? headers,
    bool? iosAllowsCellularAccess,
    bool? iosAllowsConstrainedNetworkAccess,
    bool? iosAllowsExpensiveNetworkAccess,
    URLRequestCachePolicy? iosCachePolicy,
    bool? iosHttpShouldHandleCookies,
    bool? iosHttpShouldUsePipelining,
    URLRequestNetworkServiceType? iosNetworkServiceType,
    double? iosTimeoutInterval,
    WebUri? iosMainDocumentURL,
  }) {
    return URLRequest(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      allowsCellularAccess: iosAllowsCellularAccess ?? allowsCellularAccess,
      allowsConstrainedNetworkAccess: iosAllowsConstrainedNetworkAccess ?? allowsConstrainedNetworkAccess,
      allowsExpensiveNetworkAccess: iosAllowsExpensiveNetworkAccess ?? allowsExpensiveNetworkAccess,
      cachePolicy: iosCachePolicy,
      httpShouldHandleCookies: iosHttpShouldHandleCookies ?? httpShouldHandleCookies,
      httpShouldUsePipelining: iosHttpShouldUsePipelining ?? httpShouldUsePipelining,
      networkServiceType: iosNetworkServiceType,
      timeoutInterval: iosTimeoutInterval,
      mainDocumentURL: iosMainDocumentURL,
    );
  }
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
