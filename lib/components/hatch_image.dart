import 'package:flutter/widgets.dart';

class HatchImage extends StatefulWidget {
  const HatchImage({super.key});

  @override
  State<HatchImage> createState() => _HatchImageState();
}

class _HatchImageState extends State<HatchImage> with TickerProviderStateMixin {
  late AnimationController _animationControllerAppear;
  late AnimationController _animationControllerDisappear;

  @override
  void initState() {
    super.initState();
    _animationControllerAppear = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationControllerDisappear = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationControllerAppear.forward();
  }

  @override
  void dispose() {
    _animationControllerAppear.dispose();
    _animationControllerDisappear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          child: Positioned(
            bottom: 0,
            left: Tween(begin: -100.0, end: 0.0).animate(_animationControllerAppear).value,
            child: RotationTransition(
              turns: Tween(begin: 1.0, end: 0.0).animate(_animationControllerAppear),
              child: Image.asset('assets/images/help.png'),
            ),
          ),
        ),
        SizedBox(
          height: 300,
          child: Positioned(
            bottom: Tween(begin: -100.0, end: 0.0).animate(_animationControllerDisappear).value,
            left: Tween(begin: 0.0, end: -100.0).animate(_animationControllerDisappear).value,
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: -1.0).animate(_animationControllerDisappear),
              child: Image.asset('assets/images/help.png'),
            ),
          ),
        ),
      ],
    );
  }
}
