import 'package:flutter/material.dart';

class PageAnimationContainer extends StatefulWidget {
  final List<Widget> children;
  final Duration fadeDuration;
  final Curve fadeCurve;

  const PageAnimationContainer({
    Key? key,
    required this.children,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.fadeCurve = Curves.easeInOut,
  }) : super(key: key);

  @override
  PageAnimationContainerState createState() => PageAnimationContainerState();
}

class PageAnimationContainerState extends State<PageAnimationContainer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.fadeCurve,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(PageAnimationContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.children.length != oldWidget.children.length) {
      _currentIndex = 0;
      _animationController.reset();
      _animationController.forward();
    } else if (widget.children[_currentIndex] != oldWidget.children[_currentIndex]) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.children[_currentIndex],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void navigateTo(int index) {
    setState(() {
      _currentIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }
}