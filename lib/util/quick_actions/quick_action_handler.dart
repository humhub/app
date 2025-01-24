import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'quick_actions_provider.dart';

class QuickActionsHandler extends ConsumerWidget {
  const QuickActionsHandler({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickAction = ref.watch(quickActionsProvider);

    if (quickAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Handle navigation or UI logic here, if needed
        quickAction.action();
        // Clear the action after handling
        ref.read(quickActionsProvider.notifier).clearAction();
      });
    }

    return const SizedBox.shrink();
  }
}
