// ========================================
// FILE: instructor_kpi_provider.dart
// MÔ TẢ: Provider cho KPI stats của instructor dashboard - CHỈ UI, không tác động logic
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

// KPI Stats Model
class InstructorKPIStats {
  final int coursesCount;
  final int groupsCount;
  final int studentsCount;
  final int assignmentsCount;
  final int quizzesCount;

  const InstructorKPIStats({
    required this.coursesCount,
    required this.groupsCount,
    required this.studentsCount,
    required this.assignmentsCount,
    required this.quizzesCount,
  });
}

// Provider để lấy KPI stats - CHỈ TRẢ VỀ MOCK DATA cho UI
// Không gọi bất kỳ repository hay controller nào để tránh tác động đến logic hiện có
final instructorKPIStatsProvider = FutureProvider.family<InstructorKPIStats, String>(
  (ref, semesterName) async {
    // Chỉ trả về mock data cho UI
    // TODO: Có thể tích hợp với data thực tế sau nếu cần
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    
    return const InstructorKPIStats(
      coursesCount: 0,
      groupsCount: 0,
      studentsCount: 0,
      assignmentsCount: 0,
      quizzesCount: 0,
    );
  },
);

