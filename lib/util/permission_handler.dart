import 'dart:io';

import 'package:flutter/material.dart';
import 'package:humhub/util/const.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PermissionHandler {
  /// A static method that takes a list of permissions and handles permission requests.
  /// It only requests permissions that have not yet been granted ([permission.isGranted]) and are not permanently denied ([permission.isPermanentlyDenied]).
  ///
  /// **Android:** This will be triggered every time if the user closes the permission modal without providing input.
  /// **iOS:** Permissions will only be requested once, as the modal is required before continuing.
  /// [permissions] - A list of [Permission] objects to be requested.
  /// This method ensures that unnecessary permission requests are avoided, improving user experience.
  static Future<void> requestPermissions(List<Permission> permissions) async {
    // Filter permissions asynchronously
    List<Permission> toRequest = [];
    for (var permission in permissions) {
      if (!(await permission.isGranted) && !(await permission.isPermanentlyDenied)) {
        toRequest.add(permission);
      }
    }
    // Request the permissions that are not granted
    if (toRequest.isNotEmpty) {
      await toRequest.request();
    }
  }

  /// A static method to check if all the necessary permissions are granted before executing a given action.
  ///
  /// If all required permissions are granted, the provided [action] is executed.
  /// If any permissions are missing on Android, a [SnackBar] is shown informing the user to enable the required permissions.
  /// **Parameters:**
  /// - [permissions]: A list of [Permission] objects that need to be checked.
  /// - [action]: A callback function that will be executed if the required permissions are granted.
  /// **Android:** If the user closes the permissions dialog without providing input, the method won't proceed with the action.
  /// **iOS:** Permissions are required before continuing, so the action will proceed automatically once permissions are granted.
  /// If permissions are not granted, the user will be prompted to open the app settings.
  static Future<void> runWithPermissionCheck({
    required List<Permission> permissions,
    required Function action,
  }) async {
    bool allPermissionsGranted = true;

    for (Permission permission in permissions) {
      PermissionStatus status = await permission.status;
      if (!status.isGranted) {
        allPermissionsGranted = false;
        break;
      }
    }

    if (allPermissionsGranted || Platform.isIOS) {
      // All permissions are granted, run the provided action
      action();
    } else {
      // Show a SnackBar indicating that permissions are missing
      if (Keys.navigatorKey.currentState != null && Keys.navigatorKey.currentState!.mounted) {
        Keys.scaffoldMessengerStateKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(Keys.navigatorKey.currentState!.context)!.enable_permissions),
            action: SnackBarAction(
              label: AppLocalizations.of(Keys.navigatorKey.currentState!.context)!.settings,
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    }
  }
}
