// ========================================
// FILE: local_storage.dart
// MÔ TẢ: Quản lý local storage sử dụng Hive
// ========================================

import 'package:hive_flutter/hive_flutter.dart';

// ========================================
// CLASS: LocalStorage
// MÔ TẢ: Quản lý việc khởi tạo và truy cập local storage
// ========================================
class LocalStorage {
  // ========================================
  // CONSTRUCTOR: Private constructor
  // MÔ TẢ: Ngăn chặn việc tạo instance của class này
  // ========================================
  LocalStorage._();

  // ========================================
  // HÀM: init()
  // MÔ TẢ: Khởi tạo Hive cho ứng dụng
  // ========================================
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  // ========================================
  // HÀM: openBox()
  // MÔ TẢ: Mở Hive box với tên và kiểu dữ liệu cụ thể
  // ========================================
  static Future<Box<T>> openBox<T>(String name) async {
    return Hive.openBox<T>(name);
  }
}



























