// ========================================
// FILE: format_utils.dart
// MÔ TẢ: Các hàm tiện ích để format dữ liệu
// ========================================

import 'package:intl/intl.dart';

// ========================================
// CLASS: FormatUtils
// MÔ TẢ: Chứa các phương thức format dữ liệu chung
// ========================================
class FormatUtils {
  // ========================================
  // CONSTRUCTOR: Private constructor
  // MÔ TẢ: Ngăn chặn việc tạo instance của class này
  // ========================================
  FormatUtils._();

  // ========================================
  // HÀM: formatDateTime()
  // MÔ TẢ: Format DateTime thành chuỗi với giờ phút
  // ========================================
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  // ========================================
  // HÀM: formatDate()
  // MÔ TẢ: Format DateTime thành chuỗi chỉ có ngày
  // ========================================
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
