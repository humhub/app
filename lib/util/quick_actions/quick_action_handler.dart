import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/quick_actions/quick_action_provider.dart';

class QuickActionsHandler extends ConsumerWidget {
  final Widget child;
  const QuickActionsHandler({Key? key, required this.child}) : super(key: key);

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
