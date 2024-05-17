import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/extensions.dart';

/// Remembers whether current FirebaseApp is initialized.
final firebaseInitialized = StateProvider<AsyncValue<bool>>(
  (ref) => const AsyncValue.loading(),
);

final _pushTokenProvider = FutureProvider<AsyncValue<String?>>(
  (ref) async {
    var initialized = ref.watch(firebaseInitialized.notifier).state;
    if (initialized.isLoaded) {
      return AsyncValue.guard(FirebaseMessaging.instance.getToken);
    }
    return const AsyncValue.loading();
  },
);

/// Provides current push token. Will wait until Firebase is initialized.
///
/// See also:
/// * [_PushPluginState._init]
final pushTokenProvider = Provider<AsyncValue<String?>>(
  (ref) {
    var provider = ref.watch(_pushTokenProvider);
    return provider.when(
      data: (value) => value,
      error: (e, s) => AsyncValue.error(e, s),
      loading: () => const AsyncValue.loading(),
    );
  },
);
