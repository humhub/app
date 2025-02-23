import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/quick_actions/quick_action_provider.dart';
import 'package:humhub/util/providers.dart';
import 'package:loggy/loggy.dart';

class QuickActionsHandler extends ConsumerStatefulWidget {
  final Widget child;

  const QuickActionsHandler({super.key, required this.child});

  @override
  ConsumerState<QuickActionsHandler> createState() =>
      _QuickActionsHandlerState();
}

class _QuickActionsHandlerState extends ConsumerState<QuickActionsHandler> {

  @override
  Widget build(BuildContext context) {
    // Watch the current quick action
    final quickAction = ref.watch(quickActionsProvider);
    // Handle the current quick action
    if (quickAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        quickAction.action();
        ref.read(quickActionsProvider.notifier).clearAction();
      });
    }

    ref.listen<int>(
      humHubProvider.select((state) => state.history.length),
          (previous, next) {
        List<Manifest> newHistory = ref.read(humHubProvider).history;
        logDebug("Refreshing quick actions", newHistory.map((e) => e.shortName).toList());
        ref.read(quickActionsProvider.notifier).refreshQuickActions(
            newHistory.map((e) => e.shortcut).toList());
      },
    );

    return widget.child;
  }
}
