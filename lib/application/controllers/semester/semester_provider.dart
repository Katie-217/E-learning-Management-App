// ========================================
// FILE: semester_provider.dart
// PURPOSE: Global providers for semester management - Clean Architecture
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/semester_model.dart';
import '../../../domain/models/semester_template_model.dart';
import '../../../data/repositories/semester/semester_template_repository.dart';
import 'semester_controller.dart';

// ========================================
// GLOBAL PROVIDERS FOR SEMESTER MANAGEMENT
// ========================================

// Semester Controller Provider
final semesterControllerProvider = Provider<SemesterController>((ref) {
  return SemesterController();
});

// Semester List Provider - Global data for all semester dropdowns
final semesterListProvider = FutureProvider<List<SemesterModel>>((ref) async {
  final controller = ref.read(semesterControllerProvider);
  return await controller.getAllSemesters();
});

// Semester Template Provider - Global data for semester templates
final semesterTemplateListProvider =
    FutureProvider<List<SemesterTemplateModel>>((ref) async {
  final repository = SemesterTemplateRepository();
  return await repository.getSemesterTemplates();
});

// Legacy provider for backward compatibility (if needed)
class SemesterNotifier extends StateNotifier<String> {
  SemesterNotifier() : super('');

  void changeSemester(String semester) {
    state = semester;
  }

  // No hardcoded semesters - data comes from Firestore
  List<String> getAvailableSemesters() {
    return [];
  }
}

// Legacy provider - kept for backward compatibility
final semesterProvider = StateNotifierProvider<SemesterNotifier, String>((ref) {
  return SemesterNotifier();
});
