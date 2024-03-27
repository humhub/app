import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityPlugin {
  static Future<bool> get hasConnectivity async {
    ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
