import 'package:dio/dio.dart';
import 'package:loggy/loggy.dart';

class UrlProviderHandler {
  static Future<Uri?> handleUniversalLink(Uri url) async {
    if (_isHumHubUrl(url)) {
      return _handleHumHubUrl(url);
    } else if (_isBrevoUrl(url)) {
      return await _handleUniversalLinkBrevo(url);
    }
    return null;
  }

  static bool _isHumHubUrl(Uri url) {
    return url.toString().contains('go.humhub.com');
  }

  static bool _isBrevoUrl(Uri url) {
    return url.toString().contains('r.mail.inforisque.fr');
  }

  static Uri? _handleHumHubUrl(Uri url) {
    try {
      final urlParam = url.queryParameters['url'];
      if (urlParam != null) {
        return Uri.parse(Uri.decodeComponent(urlParam));
      }
      return null;
    } catch (e) {
      logError('Error while handling HumHub URL: $e');
      return null;
    }
  }

  static Future<Uri?> _handleUniversalLinkBrevo(Uri url) async {
    try {
      final response = await Dio().get(
        url.toString(),
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return Uri.parse(data['url']);
      } else {
        logError('Failed to retrieve deep link. Status code: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        logError('DioError: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        logError('DioError: ${e.message}');
      }
      return null;
    } catch (e) {
      logError('Unexpected error while handling universal link: $e');
      return null;
    }
  }
}
