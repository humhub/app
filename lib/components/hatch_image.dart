import 'package:flutter/material.dart';

class HatchImage extends StatefulWidget {
  final String imageUrl;
  final bool fadeIn;

  const HatchImage({Key? key, required this.imageUrl, required this.fadeIn}) : super(key: key);

  @override
  State<HatchImage> createState() => _HatchImageState();
}

class _HatchImageState extends State<HatchImage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  late Animation<Offset> _animationFir;
  late Animation<Offset> _animationSec;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _animationFir = Tween<Offset>(
      begin: const Offset(1.0, 1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationSec = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(-1.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animation = widget.fadeIn ? _animationSec : _animationFir;
  }

  @override
  Widget build(BuildContext context) {
    _animationController.forward();
    return SlideTransition(position: _animation, child: Image.asset(widget.imageUrl, fit: BoxFit.cover));
  }
}
