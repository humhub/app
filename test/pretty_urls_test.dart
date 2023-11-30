import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/util/extensions.dart';

Future<void> main() async {
  group("Testing pretty urls", () {
    test("Community url", () {
      Uri uri = Uri.parse("https://community.humhub.com/dashboard");
      expect(uri.isUriPretty(), true);
    });
    test("Lado", () {
      Uri uri = Uri.parse("https://labo-sphere.fr/index.php?r=user%2Fauth%2Flogin");
      expect(uri.isUriPretty(), false);
    });
    test("Test12345", () {
      Uri uri = Uri.parse("https://sometestproject12345.humhub.com/dashboard");
      expect(uri.isUriPretty(), true);
    });
    test("Local", () {
      Uri uri = Uri.parse("http://192.168.64.3/humhub/index.php?r=user%2Fauth%2Flogin");
      expect(uri.isUriPretty(), false);
    });
  });
}
