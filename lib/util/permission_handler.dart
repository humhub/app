import 'dart:io';

import 'package:flutter/material.dart';
import 'package:humhub/util/const.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PermissionHandler {
  // Static method that takes a list of permissions and handles requests
  static Future<void> requestPermissions(List<Permission> permissions) async {
    for (Permission permission in permissions) {
      // Check the current status of the permission
      PermissionStatus status = await permission.status;

      // Only request the permission if it has never been asked or is not granted
      if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
        continue; // Don't request again if it's denied or restricted
      }

      // Request the permission if not granted
      if (!status.isGranted) {
        await permission.request();
      }
    }
  }

  // Static method to check permissions before executing a function
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
      if(navigatorKey.currentState != null && navigatorKey.currentState!.mounted){
        scaffoldMessengerStateKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(navigatorKey.currentState!.context)!.enable_permissions),
            action: SnackBarAction(
              label: AppLocalizations.of(navigatorKey.currentState!.context)!.settings,
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
