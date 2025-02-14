import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _provider = StateProvider<GlobalKey<_ManagerState>>(
  (ref) => GlobalKey<_ManagerState>(),
);

class LoadingProvider extends StatelessWidget {
  final Widget child;

  const LoadingProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', ''),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer(
          builder: (context, ref, child) => _Manager(
            key: ref.watch(_provider),
            child: child!,
          ),
          child: child,
        ),
      ),
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
    super.key,
    required this.child,
  });

  @override
  _ManagerState createState() => _ManagerState();
}

class _ManagerState extends State<_Manager> {
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

  void showLoading({bool hideBackground = false}) {
    if (_entries.isNotEmpty) return;
    final entry = OverlayEntry(
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: hideBackground ? Colors.white : Colors.black54,
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
