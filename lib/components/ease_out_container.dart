import 'package:flutter/widgets.dart';

class EaseOutContainer extends StatefulWidget {
  final Widget child;
  const EaseOutContainer({super.key, required this.child, });

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
    _animation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          width: MediaQuery.of(context).size.width * 0.6,
          child: widget.child,
        ),
      ),
    );
  }
}
