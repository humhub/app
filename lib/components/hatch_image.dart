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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.reverse().then((_) {
      super.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _animation, child: Expanded(child: Image.asset('assets/images/help.png', fit: BoxFit.cover)));
  }
}
