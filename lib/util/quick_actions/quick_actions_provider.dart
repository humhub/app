// quick_actions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loggy/loggy.dart';
import 'package:quick_actions/quick_actions.dart';

class InternalShortcut {
  final ShortcutItem shortcut;
  final Function action;

  InternalShortcut({required this.shortcut, required this.action});
}

class QuickActionsService {
  final _quickActions = const QuickActions();

  List<InternalShortcut> shortcuts = [
    InternalShortcut(
        shortcut: const ShortcutItem(
          type: 'action_one',
          localizedTitle: 'Action one',
          localizedSubtitle: 'Action one subtitle',
          icon: 'ic_launcher',
        ),
        action: () {
          logInfo('action_one');
        }),
    InternalShortcut(
        shortcut: const ShortcutItem(
          type: 'action_two',
          localizedTitle: 'Action two',
          localizedSubtitle: 'Action two subtitle',
          icon: 'ic_launcher',
        ),
        action: () {
          logInfo('action_two');
        }),
    InternalShortcut(
        shortcut: const ShortcutItem(
          type: 'action_three',
          localizedTitle: 'Action three',
          localizedSubtitle: 'Action three subtitle',
          icon: 'ic_launcher',
        ),
        action: () {
          logInfo('action_three');
        })
  ];

  Future<void> initialize(Function(String) onAction) async {
    _quickActions.initialize(onAction);
    await _quickActions.setShortcutItems(shortcuts.map((e) => e.shortcut).toList());
  }
}

class QuickActionsNotifier extends StateNotifier<InternalShortcut?> {
  final QuickActionsService _service;

  QuickActionsNotifier(this._service) : super(null);

  Future<void> initialize() async {
    await _service.initialize((actionType) {
      // Find the shortcut by type and execute its action
      final shortcut = _service.shortcuts
          .firstWhere((s) => s.shortcut.type == actionType);

      shortcut.action(); // Execute the action
      state = shortcut; // Update the state with the InternalShortcut
    });
  }

  void clearAction() {
    state = null; // Clear the state after handling the action
  }
}

final quickActionsProvider =
StateNotifierProvider<QuickActionsNotifier, InternalShortcut?>((ref) {
  final service = QuickActionsService();
  final notifier = QuickActionsNotifier(service);

  // Initialize the service on app start
  notifier.initialize();

  return notifier;
});
