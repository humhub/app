import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/flavored/util/router.f.dart';
import 'package:humhub/util/intent/intent_plugin.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/override_locale.dart';
import 'package:humhub/util/push/push_plugin.dart';
import 'package:humhub/util/storage_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FlavoredApp extends ConsumerStatefulWidget {
  const FlavoredApp({super.key});

  @override
  FlavoredAppState createState() => FlavoredAppState();
}

class FlavoredAppState extends ConsumerState<FlavoredApp> {
  @override
  Widget build(BuildContext context) {
    SecureStorageService.clearSecureStorageOnReinstall();
    return IntentPlugin(
      child: NotificationPlugin(
        child: PushPlugin(
          child: OverrideLocale(
            builder: (overrideLocale) => Builder(
              builder: (context) => MaterialApp(
                debugShowCheckedModeBanner: false,
                initialRoute: RouterF.initRoute,
                routes: RouterF.routes,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                navigatorKey: navigatorKeyF,
                builder: (context, child) => LoadingProvider(
                  child: child!,
                ),
                theme: ThemeData(
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
