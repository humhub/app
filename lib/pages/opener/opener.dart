import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/pages/help/help.dart';
import 'package:humhub/pages/opener/components/search_bar.dart';
import 'package:humhub/pages/settings/settings.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/init_from_url.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/openers/opener_controller.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/storage_service.dart';
import 'package:loggy/loggy.dart';
import 'package:rive/rive.dart' as rive;

import 'components/last_login.dart';

class OpenerPage extends ConsumerStatefulWidget {
  const OpenerPage({super.key});
  static const String path = '/';

  @override
  OpenerPageState createState() => OpenerPageState();
}

class OpenerPageState extends ConsumerState<OpenerPage> with SingleTickerProviderStateMixin {
  late OpenerController openerControlLer;

  @override
  void initState() {
    super.initState();
    openerControlLer = OpenerController(ref: ref);
    openerControlLer.setForwardAnimation(rive.SimpleAnimation('animation', autoplay: false));
    openerControlLer.setReverseAnimation(rive.SimpleAnimation('animation', autoplay: true));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasVisited = await SecureStorageService.hasVisitedSettings();
      if (!hasVisited) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pushNamed(SettingsPage.path, arguments: true);
          }
        });
      }
      // Delay before showing text field
      ref.read(visibilityProvider.notifier).setVisibility(true);
      Future.delayed(const Duration(milliseconds: 1000), () {
        ref.read(textFieldVisibilityProvider.notifier).setVisibility(true);
      });

      // Delay before showing language switcher
      Future.delayed(const Duration(milliseconds: 700), () {
        ref.read(languageSwitcherVisibilityProvider.notifier).setVisibility(true);
      });

      String? urlIntent = InitFromUrl.usePayload();
      if (urlIntent != null) {
        logInfo('Intent URL detected: $urlIntent');
        await ref.read(notificationChannelProvider).value!.onTap(urlIntent);
      }

      /// If there is only one item in history that means we can show [SearchBarWidget] that is already prefilled with url or null if count is 0.
      if (ref.read(humHubProvider).history.isEmpty) {
        logDebug('History empty, showing search bar');
        ref.watch(searchBarVisibilityNotifier.notifier).setVisibility(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            rive.RiveAnimation.asset(
              Assets.openerAnimationForward,
              fit: BoxFit.fill,
              controllers: [openerControlLer.animationForwardController],
            ),
            rive.RiveAnimation.asset(
              Assets.openerAnimationReverse,
              fit: BoxFit.fill,
              controllers: [openerControlLer.animationReverseController],
            ),
            Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: Colors.transparent,
              floatingActionButton: ref.watch(searchBarVisibilityNotifier) && ref.watch(humHubProvider.notifier).history.isNotEmpty
                  ? AnimatedOpacity(
                      opacity: ref.watch(languageSwitcherVisibilityProvider) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: FloatingActionButton(
                        onPressed: () {
                          logInfo('FAB pressed: toggling search bar visibility');
                          ref.watch(searchBarVisibilityNotifier.notifier).toggleVisibility();
                        },
                        tooltip: 'Increment',
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
                      ),
                    )
                  : null,
              body: SafeArea(
                bottom: false,
                top: false,
                child: Form(
                  key: openerControlLer.helper.key,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      // Language Switcher visibility
                      Padding(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                        child: AnimatedOpacity(
                          opacity: ref.watch(languageSwitcherVisibilityProvider) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Padding(
                            padding: EdgeInsets.only(top: 10, right: 16),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pushNamed(SettingsPage.path),
                                style: ButtonStyle(
                                  overlayColor: WidgetStateProperty.all(Color(0xFFF5F5F5)),
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                icon: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: SvgPicture.asset(
                                    Assets.settings,
                                    width: 26,
                                    height: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 100,
                          width: 230,
                          child: Image.asset(Assets.logo),
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: ref.watch(searchBarVisibilityNotifier)
                            ? SearchBarWidget(openerControlLer: openerControlLer)
                            : AnimatedOpacity(
                                opacity: ref.watch(textFieldVisibilityProvider) ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: LastLoginWidget(
                                    history: ref.watch(humHubProvider).history,
                                    onAddNetwork: () {
                                      logInfo('User tapped Add Network');
                                      ref.watch(searchBarVisibilityNotifier.notifier).toggleVisibility();
                                    },
                                    onSelectNetwork: (Manifest manifest) async {
                                      logInfo('User selected network: ${manifest.name}');
                                      UniversalOpenerController uniOpen = UniversalOpenerController(url: manifest.startUrl);
                                      await uniOpen.initHumHub();
                                      // Always pop the current instance and init the new one.
                                      LoadingProvider.of(ref).dismissAll();

                                      openerControlLer.animationNavigationWrapper(
                                        navigate: () => Keys.navigatorKey.currentState!.pushNamed(WebView.path, arguments: uniOpen),
                                      );
                                    },
                                    onDeleteNetwork: (manifest, isLast) async {
                                      logInfo('User deleted network: ${manifest.name}');
                                      ref.watch(humHubProvider.notifier).removeHistory(manifest);
                                      if (isLast) {
                                        ref.watch(searchBarVisibilityNotifier.notifier).toggleVisibility();
                                      }
                                    }),
                              ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: GestureDetector(
                            onTap: () {
                              logInfo('User tapped help link');
                              openerControlLer.animationNavigationWrapper(
                                navigate: () => Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 500),
                                    pageBuilder: (context, animation, secondaryAnimation) => const Help(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            child: AnimatedOpacity(
                              opacity: ref.watch(visibilityProvider) ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                AppLocalizations.of(context)!.opener_need_help,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration openerDecoration(context) => InputDecoration(
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey,
          width: 1.0,
        ),
      ),
      border: const OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey,
          width: 1.0,
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelText: AppLocalizations.of(context)!.url.toUpperCase(),
      labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color));

  @override
  void dispose() {
    openerControlLer.dispose();
    super.dispose();
  }
}
