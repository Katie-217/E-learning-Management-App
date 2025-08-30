// ========================================
// FILE: responsive_helper.dart
// MÔ TẢ: Các hàm tiện ích để xử lý responsive design
// ========================================

import 'package:flutter/material.dart';

// ========================================
// CLASS: ResponsiveHelper
// MÔ TẢ: Chứa các phương thức kiểm tra và xử lý responsive
// ========================================
class ResponsiveHelper {
  // ========================================
  // HÀM: isMobile()
  // MÔ TẢ: Kiểm tra xem có phải thiết bị mobile không
  // ========================================
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  // ========================================
  // HÀM: isTablet()
  // MÔ TẢ: Kiểm tra xem có phải thiết bị tablet không
  // ========================================
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  // ========================================
  // HÀM: isDesktop()
  // MÔ TẢ: Kiểm tra xem có phải thiết bị desktop không
  // ========================================
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  // ========================================
  // HÀM: getGridCrossAxisCount()
  // MÔ TẢ: Lấy số cột cho GridView dựa trên kích thước màn hình
  // ========================================
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  // ========================================
  // HÀM: getStatsCardCount()
  // MÔ TẢ: Lấy số lượng card thống kê hiển thị dựa trên kích thước màn hình
  // ========================================
  static int getStatsCardCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 768) return 3;
    if (width >= 480) return 2;
    return 1;
  }

  // ========================================
  // HÀM: getCardAspectRatio()
  // MÔ TẢ: Lấy tỷ lệ khung hình cho card dựa trên thiết bị
  // ========================================
  static double getCardAspectRatio(BuildContext context) {
    if (isMobile(context)) return 0.85;
    if (isTablet(context)) return 0.9;
    return 1.0;
  }

  // ========================================
  // HÀM: getHorizontalPadding()
  // MÔ TẢ: Lấy padding ngang dựa trên kích thước màn hình
  // ========================================
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 32;
    if (width >= 768) return 24;
    return 16;
  }

  // ========================================
  // HÀM: getResponsivePadding()
  // MÔ TẢ: Lấy padding responsive cho toàn bộ màn hình
  // ========================================
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final padding = getHorizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: padding, vertical: 16);
  }
}
