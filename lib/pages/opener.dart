import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/form_helper.dart';
import 'package:humhub/util/opener_controller.dart';
import 'package:humhub/util/providers.dart';
import 'package:rive/rive.dart';
import 'help/help.dart';

class Opener extends ConsumerStatefulWidget {
  const Opener({Key? key}) : super(key: key);
  static const String path = '/opener';

  @override
  OpenerState createState() => OpenerState();
}

class OpenerState extends ConsumerState<Opener> {
  late OpenerController controlLer;
  late RiveAnimationController _controller;
  final FormHelper helper = FormHelper();
  late SimpleAnimation _animation;
  // Fade out Logo and opener when redirecting
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _animation = SimpleAnimation('animation', autoplay: false);
    _controller = _animation;
  }

  @override
  Widget build(BuildContext context) {
    controlLer = OpenerController(ref: ref, helper: helper);
    InputDecoration openerDecoration = InputDecoration(
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
        labelText: 'URL',
        labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: helper.key,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RiveAnimation.asset(
                fit: BoxFit.fill,
                'assets/opener_animation.riv',
                controllers: [_controller],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: AnimatedOpacity(
                      opacity: _visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        height: 100,
                        width: 230,
                        child: Image.asset('assets/images/logo.png'),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: AnimatedOpacity(
                      opacity: _visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 35),
                        child: Column(
                          children: [
                            FutureBuilder<String>(
                              future: ref.read(humHubProvider).getLastUrl(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  controlLer.urlTextController.text = snapshot.data!;
                                  return TextFormField(
                                    controller: controlLer.urlTextController,
                                    cursorColor: Theme.of(context).textTheme.bodySmall?.color,
                                    onSaved: controlLer.helper.onSaved(controlLer.formUrlKey),
                                    style: const TextStyle(
                                      decoration: TextDecoration.none,
                                    ),
                                    decoration: openerDecoration,
                                    validator: controlLer.validateUrl,
                                  );
                                }
                                return progress;
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text('Enter your url and log in to your network.',
                                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: AnimatedOpacity(
                      opacity: _visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Center(
                        child: Container(
                          width: 140,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                          child: TextButton(
                            onPressed: () async {
                              await controlLer.initHumHub();
                              setState(() {});
                              if (controlLer.allOk) {
                                ref.read(humHubProvider).getInstance().then((value) {
                                  Navigator.pushNamed(ref.context, WebViewApp.path, arguments: value.manifest);
                                });
                              }
                            },
                            child: Text(
                              'Connect',
                              style: TextStyle(color: openerColor, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        _controller.isActive = true;
                        setState(() {
                          _visible = false;
                        });
                        Future.delayed(const Duration(milliseconds: 700)).then((value) => {
                              Navigator.push(
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
                              ).then((value) {
                                setState(() {
                                  _controller.isActive = true;
                                  _animation.reset();
                                  _visible = true;
                                });
                              })
                            });
                      },
                      child: AnimatedOpacity(
                        opacity: _visible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Text(
                          "Need Help?",
                          style: TextStyle(
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controlLer.urlTextController.dispose();
    super.dispose();
  }
}
