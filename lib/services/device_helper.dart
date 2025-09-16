import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceHelper {
  static Future<Map<String, dynamic>> getDeviceDetails() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return {
        "androidId": android.id,
        "brand": android.brand,
        "model": android.model,
        "os": "Android ${android.version.release}",
        "appVersion": "1.0.3" // TODO: fetch dynamically if needed
      };
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return {
        "androidId": ios.identifierForVendor ?? "unknown",
        "brand": "Apple",
        "model": ios.utsname.machine,
        "os": "iOS ${ios.systemVersion}",
        "appVersion": "1.0.3"
      };
    } else {
      return {
        "androidId": "unknown",
        "brand": "unknown",
        "model": "unknown",
        "os": "unknown",
        "appVersion": "1.0.3"
      };
    }
  }
}
