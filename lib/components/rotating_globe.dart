import 'package:flutter/material.dart';

enum Direction { left, right }

class RotatingGlobe extends StatefulWidget {
  final Direction rotationDirection;
  final String imagePath;

  const RotatingGlobe({super.key, required this.rotationDirection, required this.imagePath});

  @override
  State<RotatingGlobe> createState() => _RotatingGlobeState();
}

class _RotatingGlobeState extends State<RotatingGlobe> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _animationFir;
  late Animation<double> _animationSec;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animationFir = Tween(begin: 0.5, end: 0.0).animate(_controller);
    _animationSec = Tween(begin: 0.0, end: -0.5).animate(_controller);
    _animation = widget.rotationDirection == Direction.left ? _animationSec : _animationFir;
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return RotationTransition(
      alignment: Alignment.bottomCenter,
      turns: _animation,
      child: Image.asset(widget.imagePath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
