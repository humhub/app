import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:humhub/models/env_config.dart';
import 'package:loggy/loggy.dart';

abstract class UniversalLinkHandler {
  bool canHandle(Uri url);
  Future<Uri?> handle(Uri url);
}

class HumHubLinkHandler implements UniversalLinkHandler {
  final RegExp urlPattern;

  HumHubLinkHandler(this.urlPattern);

  @override
  bool canHandle(Uri url) => urlPattern.hasMatch(url.toString());

  @override
  Future<Uri?> handle(Uri url) async {
    try {
      final urlParam = url.queryParameters['url'];
      return urlParam != null ? Uri.parse(Uri.decodeComponent(urlParam)) : null;
    } catch (e) {
      logError('Error handling HumHub URL: $e');
      return null;
    }
  }
}

class BrevoLinkHandler implements UniversalLinkHandler {
  final RegExp urlPattern;

  BrevoLinkHandler(this.urlPattern);

  @override
  bool canHandle(Uri url) => urlPattern.hasMatch(url.toString());

  @override
  Future<Uri?> handle(Uri url) async {
    try {
      final response = await Dio().get(
        url.toString(),
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200) {
        logError('Failed to retrieve deep link. Status: ${response.statusCode}');
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.data);
      return Uri.parse(data['url']);
    } catch (e) {
      logError('Error handling Brevo universal link: $e');
      return null;
    }
  }
}

class UrlProviderHandler {
  final List<UniversalLinkHandler> _handlers = EnvConfig.instance!.intentProviders!.map((provider) {
    switch (provider.type) {
      case 'HumHubLinkHandler':
        return HumHubLinkHandler(RegExp(provider.shouldHandleRegex));
      case 'BrevoLinkHandler':
        return BrevoLinkHandler(RegExp(provider.shouldHandleRegex));
      default:
        throw Exception('Unknown handler type: ${provider.type}');
    }
  }).toList();

  Future<Uri?> handleUniversalLink(Uri url) async {
    for (final handler in _handlers) {
      if (handler.canHandle(url)) {
        return await handler.handle(url);
      }
    }
    return null;
  }
}
