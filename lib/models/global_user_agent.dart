import 'dart:io';
import 'dart:ui';

class GlobalUserAgent {
  static const String _ios =
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/131.0.6778.73 Mobile/15E148 Safari/604.1";
  static const String _ipad =
      "Mozilla/5.0 (iPad; CPU OS 17_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/131.0.6778.73 Mobile/15E148 Safari/604.1";
  static const String _android =
      "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6778.81 Mobile Safari/537.36";

  static bool get _isTabletViewport {
    final FlutterView view = PlatformDispatcher.instance.views.first;
    final double shortestSide =
        view.physicalSize.shortestSide / view.devicePixelRatio;
    return shortestSide >= 600;
  }

  static String? get value {
    if (Platform.isIOS) {
      if (_isTabletViewport) {
        return _ipad;
      }
      return _ios;
    } else if (Platform.isAndroid) {
      return _android;
    } else {
      return null;
    }
  }
}
