import 'package:hive_flutter/hive_flutter.dart';

class OfflineDb {
  OfflineDb._();

  static Future<void> init() async {
    await Hive.initFlutter();
    // Register Hive adapters here in the future
  }
}












