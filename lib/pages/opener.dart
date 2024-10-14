import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/components/language_switcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:humhub/pages/help/help.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/intent/intent_plugin.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/openers/opener_controller.dart';
import 'package:humhub/util/providers.dart';
import 'package:rive/rive.dart';

class Opener extends ConsumerStatefulWidget {
  const Opener({Key? key}) : super(key: key);
  static const String path = '/opener';

  @override
  OpenerState createState() => OpenerState();
}

class OpenerState extends ConsumerState<Opener> with SingleTickerProviderStateMixin {
  late OpenerController openerControlLer;

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

      String? urlIntent = InitFromIntent.usePayloadForInit();
      if (urlIntent != null) {
        await ref.read(notificationChannelProvider).value!.onTap(urlIntent);
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
            body: SafeArea(
              bottom: false,
              top: false,
              child: Form(
                key: openerControlLer.helper.key,
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                        flex: 8,
                        child: SizedBox(
                          height: 100,
                          width: 230,
                          child: Image.asset(Assets.logo),
                        ),
                      ),
                      Expanded(
                        flex: 12,
                        child: AnimatedOpacity(
                          opacity: ref.watch(textFieldVisibilityProvider) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 35),
                            child: Column(
                              children: [
                                FutureBuilder<String>(
                                  future: ref.read(humHubProvider).getLastUrl(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      openerControlLer.urlTextController.text = snapshot.data!;
                                      return TextFormField(
                                        keyboardType: TextInputType.url,
                                        controller: openerControlLer.urlTextController,
                                        cursorColor: Theme.of(context).textTheme.bodySmall?.color,
                                        onSaved: openerControlLer.helper.onSaved(openerControlLer.formUrlKey),
                                        onEditingComplete: () {
                                          openerControlLer.helper.onSaved(openerControlLer.formUrlKey);
                                          _connectInstance();
                                        },
                                        onChanged: (value) {
                                          final cursorPosition =
                                              openerControlLer.urlTextController.selection.baseOffset;
                                          final trimmedValue = value.trim();
                                          openerControlLer.urlTextController.value = TextEditingValue(
                                            text: trimmedValue,
                                            selection: TextSelection.collapsed(
                                                offset: cursorPosition > trimmedValue.length
                                                    ? trimmedValue.length
                                                    : cursorPosition),
                                          );
                                        },
                                        style: const TextStyle(
                                          decoration: TextDecoration.none,
                                        ),
                                        decoration: openerDecoration(context),
                                        validator: openerControlLer.validateUrl,
                                        autocorrect: false,
                                      );
                                    }
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    AppLocalizations.of(context)!.opener_enter_url,
                                    style:
                                        const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: AnimatedOpacity(
                          opacity: ref.watch(visibilityProvider) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Center(
                            child: TextButton(
                              onPressed: _connectInstance,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: HumhubTheme.primaryColor, // Adjust the color to match your theme
                                    width: 2, // Adjust the width as needed
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 0), // Adjust padding as needed
                                minimumSize: const Size(140, 55),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.connect,
                                style: TextStyle(
                                  color: HumhubTheme.primaryColor,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: GestureDetector(
                          onTap: () {
                            openerControlLer.animationNavigationWrapper(
                              navigate: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 500),
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      const Help(),
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

  _connectInstance() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await openerControlLer.initHumHub();
    if (openerControlLer.allOk) {
      ref.read(humHubProvider).getInstance().then((instance) {
        FocusManager.instance.primaryFocus?.unfocus();
        openerControlLer.animationNavigationWrapper(
          navigate: () => Navigator.pushNamed(ref.context, WebView.path, arguments: instance.manifest),
        );
      });
    }
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
