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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 700), (){
        setState(() {
          _textFieldAddInfoVisibility = true;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    controlLer = OpenerController(ref: ref, helper: helper);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Form(
          key: helper.key,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RiveAnimation.asset(
                'assets/opener_animation.riv',
                fit: BoxFit.fill,
                controllers: [_controller],
              ),
              RiveAnimation.asset(
                'assets/opener_animation_reverse.riv',
                fit: BoxFit.fill,
                controllers: [_controllerReverse],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Column(
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
                          opacity: _textFieldAddInfoVisibility ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
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
                                        keyboardType: TextInputType.url,
                                        controller: controlLer.urlTextController,
                                        cursorColor: Theme.of(context).textTheme.bodySmall?.color,
                                        onSaved: controlLer.helper.onSaved(controlLer.formUrlKey),
                                        style: const TextStyle(
                                          decoration: TextDecoration.none,
                                        ),
                                        decoration: openerDecoration(context),
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
                        )),
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
                            _textFieldAddInfoVisibility = false;
                          });
                          Future.delayed(const Duration(milliseconds: 700)).then((value) {
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
                                Future.delayed(const Duration(milliseconds: 700), (){
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
              ),
            ],
          ),
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
      labelText: 'URL',
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
