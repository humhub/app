import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'quick_actions_provider.dart';

class QuickActionsHandler extends ConsumerWidget {
  final Widget child;
  const QuickActionsHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickAction = ref.watch(quickActionsProvider);
    if (quickAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        quickAction.action();
        // Clear the action after handling
        ref.read(quickActionsProvider.notifier).clearAction();
      });
    }

    return child;
  }
}
