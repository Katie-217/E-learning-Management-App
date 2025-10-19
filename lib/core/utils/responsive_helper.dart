// ========================================
// FILE: responsive_helper.dart
// MÔ TẢ: Utility class để xử lý responsive design
// ========================================

import 'package:flutter/material.dart';

// ========================================
// CLASS: ResponsiveHelper
// MÔ TẢ: Helper class cho responsive design
// ========================================
class ResponsiveHelper {
  // ========================================
  // HÀM: isMobile()
  // MÔ TẢ: Kiểm tra xem có phải mobile không
  // ========================================
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  // ========================================
  // HÀM: isTablet()
  // MÔ TẢ: Kiểm tra xem có phải tablet không
  // ========================================
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  // ========================================
  // HÀM: isDesktop()
  // MÔ TẢ: Kiểm tra xem có phải desktop không
  // ========================================
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  // ========================================
  // HÀM: getResponsiveValue()
  // MÔ TẢ: Lấy giá trị responsive dựa trên kích thước màn hình
  // ========================================
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  // ========================================
  // HÀM: getResponsivePadding()
  // MÔ TẢ: Lấy padding responsive
  // ========================================
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: EdgeInsets.all(16),
      tablet: EdgeInsets.all(24),
      desktop: EdgeInsets.all(32),
    );
  }

  // ========================================
  // HÀM: getResponsiveColumns()
  // MÔ TẢ: Lấy số cột responsive cho grid
  // ========================================
  static int getResponsiveColumns(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }
}