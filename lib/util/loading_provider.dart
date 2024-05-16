import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _provider = StateProvider<GlobalKey<_ManagerState>>(
  (ref) => GlobalKey<_ManagerState>(),
);

class LoadingProvider extends StatelessWidget {
  final Widget child;

  const LoadingProvider({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) => _Manager(
        key: ref.watch(_provider),
        child: child!,
      ),
      child: child,
    );
  }

  //ignore: library_private_types_in_public_api
  static _ManagerState of(WidgetRef ref) {
    final state = ref.read(_provider).currentState;
    assert(
      state != null,
      'Loading overlay is uninitialized. '
      'Place LoadingProvider widget as high in widget tree as possible.',
    );
    return state!;
  }
}

class _Manager extends StatefulWidget {
  final Widget child;

  const _Manager({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _ManagerState createState() => _ManagerState();
}

class _ManagerState extends State<_Manager> with SingleTickerProviderStateMixin {
  final List<OverlayEntry> _entries = [];
  final GlobalKey<OverlayState> _overlayKey = GlobalKey();

  OverlayState? get _overlay => _overlayKey.currentState;

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: _overlayKey,
      initialEntries: [
        OverlayEntry(
          builder: (context) => Container(
            child: widget.child,
          ),
        ),
      ],
    );
  }

  void showLoading() {
    if (_entries.isNotEmpty) return;
    final entry = OverlayEntry(
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.black54,
        ),
        child: Center(
          child: Loader.fullscreen(),
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _entries.add(entry);
      _overlay?.insert(entry);
    });
  }

  void showImagePulseAnimation() {
    AnimationController controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    Animation<double> animation =
        Tween(begin: 1.0, end: 1.5).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    controller.repeat(reverse: true);
    if (_entries.isNotEmpty) return;
    final entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: Image.asset('assets/images/icon.png', width: 100, height: 100),
          );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _entries.add(entry);
      _overlay?.insert(entry);
    });
  }

  void dismissAll() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      while (_entries.isNotEmpty) {
        _entries.removeAt(0).remove();
      }
    });
  }

  @override
  void dispose() {
    dismissAll();
    super.dispose();
  }
}

abstract class Loader {
  static Widget inline() {
    return const Center(child: RefreshProgressIndicator());
  }

  static Widget fullscreen() {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        child: Center(
          child: inline(),
        ),
      ),
    );
  }

  static SizedBox sized(double size) {
    return SizedBox(
      height: size,
      width: size,
      child: inline(),
    );
  }
}
