import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/pages/opener.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/providers.dart';

class Redirector extends ConsumerStatefulWidget {
  const Redirector({Key? key}) : super(key: key);

  @override
  RedirectorState createState() => RedirectorState();
}

class RedirectorState extends ConsumerState<Redirector> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<HumHub>(
        future: ref.read(humHubProvider).getInstance(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FutureBuilder<RedirectAction>(
              future: snapshot.data!.action(ref),
              builder: (context, action) {
                if (action.hasData) {
                  switch (action.data!) {
                    case RedirectAction.opener:
                      return const Opener();
                    case RedirectAction.webView:
                      return WebViewApp(manifest: snapshot.data!.manifest!);
                  }
                }
                return progress;
              },
            );
          }
          return progress;
        },
      ),
    );
  }
}
