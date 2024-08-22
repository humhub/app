import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/components/language_switcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:humhub/components/last_login_widget.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/form_helper.dart';
import 'package:humhub/util/intent/intent_plugin.dart';
import 'package:humhub/util/notifications/channel.dart';
import 'package:humhub/util/openers/opener_controller.dart';
import 'package:humhub/util/providers.dart';
import 'package:rive/rive.dart';
import 'help/help_android.dart';
import 'help/help_ios.dart';

class Opener extends ConsumerStatefulWidget {
  const Opener({Key? key}) : super(key: key);
  static const String path = '/opener';

  @override
  OpenerState createState() => OpenerState();
}

class OpenerState extends ConsumerState<Opener> with SingleTickerProviderStateMixin {
  late OpenerController controlLer;

  late RiveAnimationController _controller;
  late SimpleAnimation _animation;
  late RiveAnimationController _controllerReverse;
  late SimpleAnimation _animationReverse;

  final FormHelper helper = FormHelper();
  // Fade out Logo and opener when redirecting
  bool _visible = true;
  bool _textFieldAddInfoVisibility = false;

  @override
  void initState() {
    super.initState();
    _animation = SimpleAnimation('animation', autoplay: false);
    _controller = _animation;

    _animationReverse = SimpleAnimation('animation', autoplay: true);
    _controllerReverse = _animationReverse;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(const Duration(milliseconds: 700), () {
        setState(() {
          _textFieldAddInfoVisibility = true;
        });
      });

      String? urlIntent = InitFromIntent.usePayloadForInit();
      if (urlIntent != null) {
        await ref.read(notificationChannelProvider).value!.onTap(urlIntent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    controlLer = OpenerController(ref: ref, helper: helper);
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          RiveAnimation.asset(
            Assets.openerAnimationForward,
            fit: BoxFit.fill,
            controllers: [_controller],
          ),
          RiveAnimation.asset(
            Assets.openerAnimationReverse,
            fit: BoxFit.fill,
            controllers: [_controllerReverse],
          ),
          Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.transparent,
            body: SafeArea(
              bottom: false,
              top: false,
              child: Form(
                key: helper.key,
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedOpacity(
                        opacity: _visible ? 1.0 : 0.0,
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
                        child: AnimatedOpacity(
                          opacity: _visible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: SizedBox(
                            height: 100,
                            width: 230,
                            child: Image.asset(Assets.logo),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 16,
                        child: AnimatedOpacity(
                          opacity: _visible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: FutureBuilder<List<dynamic>>(
                              future: Future.wait([
                                ref.read(humHubProvider).getLastThreeInstances(),
                                ref.read(humHubProvider).getInstance()
                              ]),
                              builder: (context, snap) {
                                if (!snap.hasData) return const SizedBox.shrink();
                                List<HumHub> lastNetworks = snap.data?[0];
                                HumHub currentNetwork = snap.data?[1];
                                if (lastNetworks.isNotEmpty) {
                                  return LastLoginWidget(
                                    networks: lastNetworks,
                                  );
                                } else {
                                  controlLer.urlTextController.text = currentNetwork.manifestUrl ?? "";
                                  return Column(children: [
                                    Expanded(
                                      flex: 12,
                                      child: AnimatedOpacity(
                                        opacity: _visible ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 500),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 35),
                                          child: Column(
                                            children: [
                                              TextFormField(
                                                keyboardType: TextInputType.url,
                                                controller: controlLer.urlTextController,
                                                cursorColor: Theme.of(context).textTheme.bodySmall?.color,
                                                onSaved: controlLer.helper.onSaved(controlLer.formUrlKey),
                                                onEditingComplete: () {
                                                  controlLer.helper.onSaved(controlLer.formUrlKey);
                                                  _connectInstance();
                                                },
                                                onChanged: (value) {
                                                  // Calculate the new cursor position
                                                  final cursorPosition =
                                                      controlLer.urlTextController.selection.baseOffset;
                                                  final trimmedValue = value.trim();
                                                  // Update the text controller and set the new cursor position
                                                  controlLer.urlTextController.value = TextEditingValue(
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
                                                validator: controlLer.validateUrl,
                                                autocorrect: false,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 5),
                                                child: Text(
                                                  AppLocalizations.of(context)!.opener_enter_url,
                                                  style: const TextStyle(
                                                      color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
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
                                        opacity: _visible ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: Center(
                                          child: TextButton(
                                            onPressed: _connectInstance,
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                side: BorderSide(
                                                  color:
                                                      HumhubTheme.primaryColor, // Adjust the color to match your theme
                                                  width: 2, // Adjust the width as needed
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(horizontal: 0), // Adjust padding as needed
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
                                  ]);
                                }
                              }),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: GestureDetector(
                          onTap: () {
                            _controller.isActive = true;
                            setState(() {
                              _visible = false;
                              _textFieldAddInfoVisibility = false;
                            });
                            Future.delayed(const Duration(milliseconds: 700)).then((value) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 500),
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      Platform.isAndroid ? const HelpAndroid() : const HelpIos(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              ).then((value) {
                                setState(() {
                                  _controller.isActive = true;
                                  _animation.reset();
                                  _visible = true;
                                  Future.delayed(const Duration(milliseconds: 700), () {
                                    setState(() {
                                      _textFieldAddInfoVisibility = true;
                                    });
                                  });
                                  _controllerReverse.isActive = true;
                                });
                              });
                              _controllerReverse.isActive = true;
                              _animationReverse.reset();
                            });
                          },
                          child: AnimatedOpacity(
                            opacity: _visible ? 1.0 : 0.0,
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
    await controlLer.initHumHub();
    if (controlLer.allOk) {
      ref.read(humHubProvider).getInstance().then((value) {
        Navigator.pushNamed(ref.context, WebView.path, arguments: value.manifest);
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
    controlLer.urlTextController.dispose();
    _controller.dispose();
    _controllerReverse.dispose();
    _animation.dispose();
    _animationReverse.dispose();
    super.dispose();
  }
}
