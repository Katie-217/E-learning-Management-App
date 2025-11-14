// ========================================
// FILE: cache_manager.dart
// MÔ TẢ: Quản lý cache JSON data sử dụng Hive
// ========================================

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

// ========================================
// CLASS: CacheManager
// MÔ TẢ: Quản lý việc lưu trữ và truy xuất dữ liệu JSON trong cache
// ========================================
class CacheManager {
  // ========================================
  // CONSTRUCTOR: Private constructor
  // MÔ TẢ: Ngăn chặn việc tạo instance của class này
  // ========================================
  CacheManager._();

  // ========================================
  // HÀM: putJson()
  // MÔ TẢ: Lưu dữ liệu JSON vào Hive box
  // ========================================
  static Future<void> putJson(String boxName, String key, Object value) async {
    final box = await Hive.openBox<String>(boxName);
    await box.put(key, jsonEncode(value));
  }

  // ========================================
  // HÀM: getJson()
  // MÔ TẢ: Lấy dữ liệu JSON từ Hive box
  // ========================================
  static Future<Map<String, dynamic>?> getJson(
      String boxName, String key) async {
    final box = await Hive.openBox<String>(boxName);
    final str = box.get(key);
    if (str == null) return null;
    return jsonDecode(str) as Map<String, dynamic>;
  }
}
