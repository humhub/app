import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/pages/opener/components/last_login.dart';
import 'package:humhub/util/unread_counts.dart';

void main() {
  final manifest = Manifest(
    display: 'standalone',
    startUrl: 'https://community.example.com/',
    shortName: 'Community',
    name: 'Community',
    backgroundColor: '#ffffff',
    themeColor: '#21a1b3',
    icons: null,
  );

  Future<void> pumpTile(WidgetTester tester) => tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InstanceTile(manifest: manifest, onSelectNetwork: (_) {}, onDeleteNetwork: (_) {}),
        ),
      ));

  tearDown(() => UnreadCounts.counts.value = const {});

  testWidgets('shows the unread count of the instance', (tester) async {
    UnreadCounts.counts.value = {manifest.startUrl: 3, 'https://other.example.com/': 7};

    await pumpTile(tester);

    expect(find.text('3'), findsOneWidget);
    expect(find.text('7'), findsNothing);
  });

  testWidgets('shows no count without unread items', (tester) async {
    UnreadCounts.counts.value = {manifest.startUrl: 0};

    await pumpTile(tester);

    expect(find.text('0'), findsNothing);
  });

  testWidgets('follows changes of the count', (tester) async {
    await pumpTile(tester);
    expect(find.text('2'), findsNothing);

    UnreadCounts.counts.value = {manifest.startUrl: 2};
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
  });
}
