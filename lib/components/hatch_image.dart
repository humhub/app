import 'package:flutter/material.dart';

class HatchImage extends StatefulWidget {
  final String imageUrl;

  const HatchImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  State<HatchImage> createState() => _HatchImageState();
}

class _HatchImageState extends State<HatchImage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _animation = Tween<Offset>(
      begin: const Offset(1.0, 1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAnimated) {
      _animationController.forward();
      _hasAnimated = true;
    }
    return SlideTransition(position: _animation, child: Image.asset(widget.imageUrl, fit: BoxFit.cover));
  }
}
