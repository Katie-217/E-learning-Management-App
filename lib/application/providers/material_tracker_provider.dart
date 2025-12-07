// ========================================
// FILE: material_tracker_provider.dart
// MÔ TẢ: Riverpod providers for Material Tracking
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/material_tracker_model.dart';
import 'package:elearning_management_app/data/repositories/material/material_tracker_repository.dart';

// ========================================
// REPOSITORY PROVIDER
// ========================================
final materialTrackerRepositoryProvider =
    Provider<MaterialTrackerRepository>((ref) {
  return MaterialTrackerRepository();
});

// ========================================
// STREAM PROVIDER: Trackers for Material with Group Filter
// ========================================
final materialTrackersStreamProvider = StreamProvider.family
    .autoDispose<List<MaterialTrackerModel>, MaterialTrackersParams>(
  (ref, params) {
    final repository = ref.watch(materialTrackerRepositoryProvider);
    return repository.streamTrackersForMaterial(
      params.materialId,
      groupId: params.groupId,
      status: params.status,
    );
  },
);

// ========================================
// FUTURE PROVIDER: Material Statistics
// ========================================
final materialStatsProvider =
    FutureProvider.family.autoDispose<Map<String, int>, String>(
  (ref, materialId) async {
    final repository = ref.watch(materialTrackerRepositoryProvider);
    return repository.getMaterialStats(materialId);
  },
);

// ========================================
// HELPER CLASSES
// ========================================

/// Parameters for filtering trackers
class MaterialTrackersParams {
  final String materialId;
  final String? groupId;
  final String? status;

  MaterialTrackersParams({
    required this.materialId,
    this.groupId,
    this.status,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialTrackersParams &&
        other.materialId == materialId &&
        other.groupId == groupId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(materialId, groupId, status);
}
