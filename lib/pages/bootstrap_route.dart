import 'package:flutter/material.dart';

class BootstrapRoute extends StatefulWidget {
  final String targetRoute;
  final Object? arguments;

  const BootstrapRoute({
    super.key,
    required this.targetRoute,
    this.arguments,
  });

  @override
  State<BootstrapRoute> createState() => _BootstrapRouteState();
}

class _BootstrapRouteState extends State<BootstrapRoute> {
  bool _redirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_redirected) return;
    _redirected = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        widget.targetRoute,
        arguments: widget.arguments,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.shrink(),
    );
  }
}
