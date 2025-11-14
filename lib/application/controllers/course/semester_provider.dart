// Provider quản lý trạng thái học kỳ hiện tại

import 'package:flutter_riverpod/flutter_riverpod.dart';

// MÔ TẢ: StateNotifier quản lý logic nghiệp vụ cho học kỳ

class SemesterNotifier extends StateNotifier<String> {
  SemesterNotifier() : super('Fall 2024');

  void changeSemester(String semester) {
    state = semester;
  }

  List<String> getAvailableSemesters() {
    return [
      'Fall 2024',
      'Spring 2024',
      'Summer 2024',
      'Fall 2023',
      'Spring 2023',
    ];
  }
}

//  Provider chính cho việc quản lý học kỳ

final semesterProvider = StateNotifierProvider<SemesterNotifier, String>((ref) {
  return SemesterNotifier();
});
