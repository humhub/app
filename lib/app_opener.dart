import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/intent/intent_plugin.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/override_locale.dart';
import 'package:humhub/util/push/push_plugin.dart';
import 'package:humhub/util/quick_actions/quick_action_handler.dart';
import 'package:humhub/util/router.dart';
import 'package:humhub/util/storage_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OpenerApp extends ConsumerStatefulWidget {
  const OpenerApp({super.key});

  @override
  OpenerAppState createState() => OpenerAppState();
}

class OpenerAppState extends ConsumerState<OpenerApp> {
  @override
  Widget build(BuildContext context) {
    SecureStorageService.clearSecureStorageOnReinstall();
    return LoadingProvider(
      child: QuickActionsHandler(
        child: IntentPlugin(
          child: NotificationPlugin(
            child: PushPlugin(
              child: OverrideLocale(
                builder: (overrideLocale) => Builder(
                  builder: (context) => FutureBuilder<String>(
                    future: MyRouter.getInitialRoute(ref),
                    builder: (context, snap) {
                      if (snap.hasData) {
                        return MaterialApp(
                          navigatorKey: navigatorKey,
                          scaffoldMessengerKey: scaffoldMessengerStateKey,
                          debugShowCheckedModeBanner: false,
                          initialRoute: snap.data,
                          routes: MyRouter.routes,
                          localizationsDelegates: AppLocalizations.localizationsDelegates,
                          supportedLocales: AppLocalizations.supportedLocales,
                          locale: overrideLocale,
                          builder: (context, child) => child!,
                          theme: ThemeData(
                            fontFamily: 'OpenSans',
                          ),
                        );
                      }
                      return Container(color: Colors.white);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
