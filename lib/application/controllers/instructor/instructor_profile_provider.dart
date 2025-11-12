import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elearning_management_app/data/repositories/instructor/instructor_profile_repository.dart';

final instructorProfileRepositoryProvider =
    Provider<InstructorProfileRepository>((ref) {
  return InstructorProfileRepository();
});

final instructorProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(instructorProfileRepositoryProvider);
  return repository.fetchInstructorProfile();
});

