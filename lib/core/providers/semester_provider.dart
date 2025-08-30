// ========================================
// FILE: semester_provider.dart
// MÔ TẢ: Provider quản lý trạng thái học kỳ hiện tại
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========================================
// CLASS: SemesterNotifier
// MÔ TẢ: StateNotifier quản lý thay đổi học kỳ
// ========================================
class SemesterNotifier extends StateNotifier<String> {
  // ========================================
  // CONSTRUCTOR: SemesterNotifier
  // MÔ TẢ: Khởi tạo với học kỳ mặc định
  // ========================================
  SemesterNotifier() : super('HK1 2024-2025');

  // ========================================
  // HÀM: changeSemester()
  // MÔ TẢ: Thay đổi học kỳ hiện tại
  // ========================================
  void changeSemester(String semester) {
    state = semester;
  }

  // ========================================
  // HÀM: getAvailableSemesters()
  // MÔ TẢ: Lấy danh sách các học kỳ có sẵn
  // ========================================
  List<String> getAvailableSemesters() {
    return [
      'HK1 2024-2025',
      'HK2 2024-2025',
      'HK3 2024-2025',
      'HK1 2025-2026',
      'HK2 2025-2026',
      'HK3 2025-2026',
    ];
  }
}

// ========================================
// PROVIDER: semesterProvider
// MÔ TẢ: Provider chính cho việc quản lý học kỳ
// ========================================
final semesterProvider = StateNotifierProvider<SemesterNotifier, String>((ref) {
  return SemesterNotifier();
});
