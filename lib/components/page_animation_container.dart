import 'package:flutter/material.dart';

class PageAnimationContainer extends StatefulWidget {
  final List<Widget> children;
  final Duration fadeDuration;
  final Curve fadeCurve;
  final Function(int, int)? navigationCallback;

  const PageAnimationContainer({
    super.key,
    required this.children,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.fadeCurve = Curves.easeInOut,
    this.navigationCallback,
  });

  @override
  PageAnimationContainerState createState() => PageAnimationContainerState();
}

class PageAnimationContainerState extends State<PageAnimationContainer> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentIndex = 0;
  int _previousIndex = 0;

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
    return Stack(
      children: [
        IgnorePointer(
          ignoring: true,
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 1,
              end: 0,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: widget.fadeCurve,
            )),
            child: widget.children[_previousIndex],
          ),
        ),
        FadeTransition(
          opacity: _fadeAnimation,
          child: _currentIndex < 0 ? widget.children[0] : widget.children[_currentIndex],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void navigateTo(int index) {
    if (widget.navigationCallback != null) {
      widget.navigationCallback!(_currentIndex, index);
    }
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }
}
