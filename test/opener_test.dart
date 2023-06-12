import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/pages/opener.dart';
import 'package:mockito/mockito.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

Future<void> main() async {
  setUp(() {
    HttpOverrides.global = MyHttpOverrides();
  });

  testWidgets('Test opener URL parsing', (WidgetTester tester) async {
    // Key value map of URLs with bool that represent the expected value
    Map<String, bool> urlsAndValuesIn = {
      "https://community.humhub.com": true,
      "https://demo.cuzy.app/": true,
      "https://sometestproject12345.humhub.com/": true,
      "https://sometestproject12345.humhub.com/some/path": true,
      "https://sometestproject123456.humhub.com/": false,
      "https://sometestproject123456.humhubb.com": false,
      "sometestproject12345.humhub.com": true,
      "//demo.cuzy.app/": false,
    };

    Map<String, bool> urlsAndValuesOut = {};
    Key openerKey = const Key('opener');

    for (var urlEntry in urlsAndValuesIn.entries) {
      String url = urlEntry.key;
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: Scaffold(body: Opener(key: openerKey)),
          ),
        ),
      );
      final state = tester.state<OpenerState>(find.byKey(openerKey));
      state.controlLer.helper.model[state.controlLer.formUrlKey] = url;
      bool isBreaking = false;

      await tester.runAsync(() async {
        try {
          await state.controlLer.findManifest(url);
        } catch (er) {
          isBreaking = true;
        }
      });
      isBreaking ? urlsAndValuesOut[url] = !isBreaking : urlsAndValuesOut[url] = !state.controlLer.asyncData!.hasError;
    }

    expect(urlsAndValuesOut, urlsAndValuesIn);
  });
}
