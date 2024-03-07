import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/util/opener_controller.dart';
import 'package:mockito/mockito.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('generatePossibleManifestsUrls', () {
    Map<String, String> uriMap = {
      "https://test.cuzy.app/humhub": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
      "test.cuzy.app/humhub/": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
      "test.cuzy.app/": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
      "sometestproject12345.humhub.com": "https://sometestproject12345.humhub.com/manifest.json",
      "sometestproject12345.humhub.com/humhub": "https://sometestproject12345.humhub.com/manifest.json",
      "sometestproject12345.humhub.com/acc": "https://sometestproject12345.humhub.com/z/manifest.json",
      "sometestproject12345.humhub.com/login": "https://sometestproject12345.humhub.com/a/manifest.json",
    };

    test('Check URLs', () {
      List<String> failedExpectations = [];

      uriMap.forEach((key, value) {
        List<String> generatedUrls = OpenerController.generatePossibleManifestsUrls(key);
        if (!generatedUrls.contains(value)) {
          failedExpectations.add("🐛 Opener URL $key generated:\n ${generatedUrls.toString()} list \n the expected value $value was not found");
        }
      });

      if (failedExpectations.isNotEmpty) {
        fail(failedExpectations.join("\n\n"));
      }
    });
  });
}
