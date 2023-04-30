import 'package:flutter/widgets.dart';

class EaseOutContainer extends StatefulWidget {
  final Widget child;
  final bool? fadeIn;
  const EaseOutContainer({
    super.key,
    required this.child,
    this.fadeIn,
  });

  @override
  State<EaseOutContainer> createState() => _EaseOutContainerState();
}

class _EaseOutContainerState extends State<EaseOutContainer> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    if (widget.fadeIn == null) {
      _animation = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
    } else {
      _animation = widget.fadeIn!
          ? Tween<Offset>(
              begin: Offset.zero,
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
            )
          : Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
            );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}
