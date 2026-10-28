import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:humhub/l10n/generated/app_localizations.dart';
import 'package:humhub/pages/settings/app_lock_provider.dart';
import 'package:humhub/util/app_lock_service.dart';

/// Gates [child] behind the native OS unlock prompt when "Require device
/// unlock" is enabled in settings. Only checked once per app process: this
/// widget keeps its state for the lifetime of the app, so returning from the
/// background does not ask again (that is left for a future iteration).
class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with SingleTickerProviderStateMixin {
  bool? _unlocked;
  bool _isAuthenticating = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _tryUnlock();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _tryUnlock() async {
    final enabled = await AppLockNotifier.isEnabled;
    if (!mounted) return;
    if (!enabled) {
      setState(() => _unlocked = true);
      return;
    }
    await _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    final reason = AppLocalizations.of(context)!.app_lock_auth_reason_unlock;
    final success = await AppLockService.authenticate(reason);
    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      _unlocked = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked == null) {
      return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
    }

    if (_unlocked!) {
      return widget.child;
    }

    final loc = AppLocalizations.of(context)!;
    final brandColor = Theme.of(context).primaryColor;

    return Material(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  brandColor,
                  Color.lerp(brandColor, Colors.black, 0.5)!,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, entrance, child) => Opacity(
                    opacity: entrance,
                    child: Transform.scale(
                        scale: 0.92 + (entrance * 0.08), child: child),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 40, horizontal: 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              button: true,
                              label: loc.app_lock_unlock_button,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(55),
                                onTap: _isAuthenticating ? null : _authenticate,
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    final glow =
                                        0.12 + (_pulseController.value * 0.22);
                                    final ringScale =
                                        1 + (_pulseController.value * 0.18);
                                    return SizedBox(
                                      width: 110,
                                      height: 110,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Transform.scale(
                                            scale: ringScale,
                                            child: Container(
                                              width: 96,
                                              height: 96,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(
                                                          alpha: 1 -
                                                              _pulseController
                                                                  .value),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 88,
                                            height: 88,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white
                                                  .withValues(alpha: 0.12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withValues(alpha: glow),
                                                  blurRadius: 26,
                                                  spreadRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: child,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: _isAuthenticating
                                      ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.lock_rounded,
                                          size: 48, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              loc.app_lock_locked_title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.app_lock_locked_subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
