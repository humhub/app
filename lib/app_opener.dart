import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/components/connectivity_wrapper.dart';
import 'package:humhub/util/app_theme.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/intent/intent_plugin.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/override_locale.dart';
import 'package:humhub/util/push/push_plugin.dart';
import 'package:humhub/util/quick_actions/quick_action_handler.dart';
import 'package:humhub/util/router.dart';
import 'package:humhub/util/storage_service.dart';
import 'package:humhub/l10n/generated/app_localizations.dart';

class OpenerApp extends ConsumerWidget {
  const OpenerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SecureStorageService.clearSecureStorageOnReinstall();

    return LoadingProvider(
      child: QuickActionsHandler(
        child: IntentPlugin(
          child: NotificationPlugin(
            child: PushPlugin(
              child: OverrideLocale(
                builder: (overrideLocale) => MaterialApp(
                  navigatorKey: Keys.navigatorKey,
                  scaffoldMessengerKey: Keys.scaffoldMessengerStateKey,
                  debugShowCheckedModeBanner: false,
                  initialRoute: AppRouter.initRoute,
                  routes: AppRouter.routes,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: overrideLocale,
                  builder: (context, child) => ConnectivityWrapper(child: child!),
                  theme: appTheme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
