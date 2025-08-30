import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalDbService {
  LocalDbService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    if (kIsWeb) {
      // Web-specific adapters or boxes could be initialized here
    }
    // Register Hive adapters here when models are added
  }
}



