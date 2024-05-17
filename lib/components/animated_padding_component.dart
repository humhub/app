import 'package:flutter/material.dart';

class AnimatedPaddingComponent extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const AnimatedPaddingComponent({super.key, required this.padding, required this.child});

  @override
  AnimatedPaddingComponentState createState() => AnimatedPaddingComponentState();
}

class AnimatedPaddingComponentState extends State<AnimatedPaddingComponent> {
  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(duration: const Duration(milliseconds: 500), padding: widget.padding, child: widget.child);
  }
}
