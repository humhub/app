import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/util/opener_controllers/opener_controller.dart';

void main() {
  void testGroupOfURIs(Map<String, String> uriMap) {
    List<String> failedExpectations = [];

    uriMap.forEach((key, value) {
      List<String> generatedUrls = OpenerController.generatePossibleManifestsUrls(key);
      if (!generatedUrls.contains(value)) {
        failedExpectations.add(
            "🐛 Opener URL $key generated:\n ${generatedUrls.toString()} list \n the expected value $value was not found");
      }
    });

    if (failedExpectations.isNotEmpty) {
      fail(failedExpectations.join("\n\n"));
    }
  }

  group('Generate possible Manifests.json URLs and check if exists', () {
    /// [key] represents the opener dialog input string
    /// [value] represents the actual manifest.json location

    test('Check HumHub Community URLs', () {
      Map<String, String> map = {
        "https://community.humhub.com/": "https://community.humhub.com/manifest.json",
        "https://community.humhub.com": "https://community.humhub.com/manifest.json",
        "community.humhub.com/": "https://community.humhub.com/manifest.json",
        "community.humhub.com": "https://community.humhub.com/manifest.json",
        "community.humhub.com/some/more": "https://community.humhub.com/manifest.json",
        "https://community.humhub.com/and/more": "https://community.humhub.com/manifest.json",
      };
      testGroupOfURIs(map);
    });

    test('Check sometestproject12345 URLs', () {
      Map<String, String> map = {
        "https://sometestproject12345.humhub.com/": "https://sometestproject12345.humhub.com/manifest.json",
        "https://sometestproject12345.humhub.com": "https://sometestproject12345.humhub.com/manifest.json",
        "sometestproject12345.humhub.com/": "https://sometestproject12345.humhub.com/manifest.json",
        "sometestproject12345.humhub.com": "https://sometestproject12345.humhub.com/manifest.json",
        "https://sometestproject12345.humhub.com/some/more": "https://sometestproject12345.humhub.com/manifest.json",
        "https://sometestproject12345.humhub.com/manifest.json":
            "https://sometestproject12345.humhub.com/manifest.json",
      };
      testGroupOfURIs(map);
    });

    test('Check some test.cuzy.app URLs', () {
      Map<String, String> map = {
        "https://test.cuzy.app/humhub": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
        "test.cuzy.app/humhub/": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
        "test.cuzy.app/humhub/some": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
        "test.cuzy.app/humhub": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
        "https://test.cuzy.app/humhub/some": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
        "https://test.cuzy.app/humhub/index.php?r=dashboard%2Fdashboard" : "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex"
      };
      testGroupOfURIs(map);
    });

    /// TEMPLATE: copy this and change it for your use case
    /*test('Check some HumHum instance URLs', () {
      /// [key] represents the opener dialog input string
      /// [value] represents the actual manifest.json location
      Map<String, String> map = {
        "https://test.cuzy.app/humhub": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
        "test.cuzy.app/humhub": "https://test.cuzy.app/humhub/index.php?r=web%2Fpwa-manifest%2Findex",
      };
      testGroupOfURIs(map);
    });*/
  });
}
