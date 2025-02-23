import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/providers.dart';
import 'package:quick_actions/quick_actions.dart';

/// Represents an internal shortcut that combines a platform shortcut item
/// with its associated action callback
class InternalShortcut {
  final ShortcutItem shortcut;
  final Function action;

  InternalShortcut({required this.shortcut, required this.action});
}

/// Manages quick actions (home screen shortcuts) functionality
/// and their registration with the platform
class QuickActionsService {
  final _quickActions = const QuickActions();
  List<InternalShortcut> shortcuts;

  QuickActionsService(this.shortcuts);

  /// Initializes quick actions and registers them with the platform
  ///
  /// Takes an [onAction] callback that will be triggered when shortcuts are selected
  Future<void> initialize(Function(String) onAction) async {
    await _quickActions.setShortcutItems(shortcuts.map((e) => e.shortcut).toList());
    _quickActions.initialize(onAction);
  }

  /// Updates the list of shortcuts and reinitializes quick actions
  Future<void> refreshShortcuts(List<InternalShortcut> newShortcuts, Function(String) onAction) async {
    shortcuts = newShortcuts;
    await initialize(onAction);
  }
}

/// Manages the state of quick actions and handles their initialization and execution
class QuickActionsNotifier extends StateNotifier<InternalShortcut?> {
  final QuickActionsService _service;

  QuickActionsNotifier(this._service) : super(null);

  /// Initializes quick actions and sets up the action handler
  ///
  /// When a shortcut is triggered, finds and executes the corresponding action
  Future<void> initialize() async {
    await _service.initialize((actionType) {
      final shortcut = _service.shortcuts.firstWhere((s) => s.shortcut.type == actionType);
      state = shortcut;
    });
  }

  /// Refreshes the shortcuts by updating the service's list of shortcuts
  /// and reinitializing quick actions
  Future<void> refreshQuickActions(List<InternalShortcut> newShortcuts) async {
    await _service.refreshShortcuts(newShortcuts, (actionType) {
      final shortcut = _service.shortcuts.firstWhere((s) => s.shortcut.type == actionType);
      state = shortcut;
    });
  }

  /// Clears the current shortcut state after handling an action
  void clearAction() {
    state = null;
  }
}

/// Provider that creates and manages the QuickActionsNotifier
/// Initializes quick actions with shortcuts from the app's history
final quickActionsProvider = StateNotifierProvider<QuickActionsNotifier, InternalShortcut?>((ref) {
  final service = QuickActionsService(ref.read(humHubProvider).history.map((e) => e.shortcut).toList());
  final notifier = QuickActionsNotifier(service);
  notifier.initialize();
  return notifier;
});
