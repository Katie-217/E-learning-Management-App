// ========================================
// FILE: validators.dart
// MÔ TẢ: Các hàm validation cho form và input
// ========================================

// ========================================
// CLASS: Validators
// MÔ TẢ: Chứa các phương thức validation chung
// ========================================
class Validators {
  // ========================================
  // CONSTRUCTOR: Private constructor
  // MÔ TẢ: Ngăn chặn việc tạo instance của class này
  // ========================================
  Validators._();

  // ========================================
  // HÀM: notEmpty()
  // MÔ TẢ: Kiểm tra trường không được để trống
  // ========================================
  static String? notEmpty(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field cannot be empty';
    }
    return null;
  }

  // ========================================
  // HÀM: email()
  // MÔ TẢ: Kiểm tra định dạng email hợp lệ
  // ========================================
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email cannot be empty';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) return 'Invalid email address';
    return null;
  }
}












