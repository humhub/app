import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/components/language_switcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:humhub/pages/help/help.dart';
import 'package:humhub/pages/opener/components/search_bar.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/init_from_url.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/openers/opener_controller.dart';
import 'package:humhub/util/providers.dart';
import 'package:rive/rive.dart';

import 'components/last_login.dart';

class Opener extends ConsumerStatefulWidget {
  const Opener({Key? key}) : super(key: key);
  static const String path = '/opener';

  @override
  OpenerState createState() => OpenerState();
}

class OpenerState extends ConsumerState<Opener> with SingleTickerProviderStateMixin {
  late OpenerController openerControlLer;
  late bool isSearchBarOpen = false;

  @override
  void initState() {
    super.initState();
    openerControlLer = OpenerController(ref: ref);
    openerControlLer.setForwardAnimation(SimpleAnimation('animation', autoplay: false));
    openerControlLer.setReverseAnimation(SimpleAnimation('animation', autoplay: true));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Delay before showing text field
      ref.read(visibilityProvider.notifier).toggleVisibility(true);
      Future.delayed(const Duration(milliseconds: 900), () {
        ref.read(textFieldVisibilityProvider.notifier).toggleVisibility(true);
      });

      // Delay before showing language switcher
      Future.delayed(const Duration(milliseconds: 700), () {
        ref.read(languageSwitcherVisibilityProvider.notifier).toggleVisibility(true);
      });

      String? urlIntent = InitFromUrl.usePayload();
      if (urlIntent != null) {
        await ref.read(notificationChannelProvider).value!.onTap(urlIntent);
      }

      /// If there is only one item in history that means we can show [SearchBarWidget] that is already prefilled with url or null if count is 0.
      if (ref.read(humHubProvider).history.length < 2) {
        setState(() {
          isSearchBarOpen = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          RiveAnimation.asset(
            Assets.openerAnimationForward,
            fit: BoxFit.fill,
            controllers: [openerControlLer.animationForwardController],
          ),
          RiveAnimation.asset(
            Assets.openerAnimationReverse,
            fit: BoxFit.fill,
            controllers: [openerControlLer.animationReverseController],
          ),
          Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.transparent,
            floatingActionButton: isSearchBarOpen
                ? AnimatedOpacity(
                    opacity: ref.watch(languageSwitcherVisibilityProvider) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          isSearchBarOpen = !isSearchBarOpen;
                        });
                      },
                      tooltip: 'Increment',
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_back, color: HumhubTheme.primaryColor),
                    ),
                  )
                : null,
            body: SafeArea(
              bottom: false,
              top: false,
              child: Form(
                key: openerControlLer.helper.key,
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      // Language Switcher visibility
                      AnimatedOpacity(
                        opacity: ref.watch(languageSwitcherVisibilityProvider) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 10, right: 16),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 110,
                              child: LanguageSwitcher(),
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
                          flex: 8,
                          child: isSearchBarOpen
                              ? SearchBarWidget(openerControlLer: openerControlLer)
                              : LastLoginWidget(
                                  onAddNetwork: () {
                                    setState(() {
                                      isSearchBarOpen = !isSearchBarOpen;
                                    });
                                  },
                                )),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
