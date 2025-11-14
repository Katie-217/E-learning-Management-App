// ========================================
// FILE: app_theme.dart
// MÔ TẢ: Định nghĩa theme và giao diện cho ứng dụng
// ========================================

import 'package:flutter/material.dart';

// ========================================
// CLASS: AppTheme
// MÔ TẢ: Quản lý theme sáng và tối cho ứng dụng
// ========================================
class AppTheme {
  // ========================================
  // CONSTRUCTOR: Private constructor
  // MÔ TẢ: Ngăn chặn việc tạo instance của class này
  // ========================================
  AppTheme._();

  // ========================================
  // GETTER: lightTheme
  // MÔ TẢ: Theme cho chế độ sáng
  // ========================================
  static ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  // ========================================
  // GETTER: darkTheme
  // MÔ TẢ: Theme cho chế độ tối
  // ========================================
  static ThemeData get darkTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}
