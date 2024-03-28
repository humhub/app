import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/flavored/flavored_web_view.dart';
import 'package:humhub/util/intent/intent_plugin.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/override_locale.dart';
import 'package:humhub/util/push/push_plugin.dart';
import 'package:humhub/util/router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'models/hum_hub.dart';

class FlavoredApp extends ConsumerStatefulWidget {
  final HumHub instance;
  const FlavoredApp({super.key, required this.instance});

  @override
  FlavoredAppState createState() => FlavoredAppState();
}

class FlavoredAppState extends ConsumerState<FlavoredApp> {
  @override
  Widget build(BuildContext context) {
    return IntentPlugin(
      child: NotificationPlugin(
        child: PushPlugin(
          child: OverrideLocale(
            builder: (overrideLocale) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: overrideLocale,
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const FlavoredWebView(),
                    settings: RouteSettings(arguments: widget.instance),
                  );
                },
                navigatorKey: navigatorKey,
                theme: ThemeData(
                  fontFamily: 'OpenSans',
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}
