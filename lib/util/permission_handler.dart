import 'package:permission_handler/permission_handler.dart';

Future<bool> checkAndRequestPermissions() async {
  Map<Permission, PermissionStatus> permissions = await [
    Permission.location,
    Permission.camera,
    Permission.microphone,
    Permission.storage,
  ].request();
  if (permissions[Permission.location] == PermissionStatus.granted &&
      permissions[Permission.camera] == PermissionStatus.granted &&
      permissions[Permission.microphone] == PermissionStatus.granted &&
      permissions[Permission.storage] == PermissionStatus.granted) {
    return true;
  } else {
    return false;
  }
}
