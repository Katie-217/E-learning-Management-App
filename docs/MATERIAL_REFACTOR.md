# MATERIAL SYSTEM REFACTOR - Documentation

## 🎯 Tổng Quan Vấn Đề & Giải Pháp

### Vấn đề Cũ (Problems)
1. **SAI YÊU CẦU**: `MaterialModel` chứa `targetGroupIds` nhưng PDF yêu cầu Material KHÔNG được gán theo nhóm
2. **THIẾU TÍNH NĂNG**: Chỉ có `downloadCount` (số) nhưng PDF yêu cầu theo dõi "AI" (Who) đã "xem" và "tải"

### Giải Pháp Mới (Solution)
1. **"Dọn Dẹp" MaterialModel**: Xóa `targetGroupIds` và `downloadCount`
2. **"Tạo Mới" Tracking System**: Root Collection `materialTracking` ghi lại mọi hành động
3. **"Làm Giàu" Thống Kê**: Lưu `groupId` từ Enrollment để Giảng viên xem stats theo nhóm

---

## 🔄 Thay Đổi Chi Tiết (Detailed Changes)

### A. MaterialModel - ✅ CLEANED UP

#### Đã Xóa (Removed)
```dart
// ❌ REMOVED - Vi phạm yêu cầu PDF
final List<String> targetGroupIds; // Material không phân theo nhóm
final int downloadCount; // Thay bằng tracking system

// ❌ REMOVED - Related methods  
bool get isForAllGroups => targetGroupIds.isEmpty;
MaterialModel incrementDownloadCount() { ... }
```

#### Giữ Lại (Kept)
```dart
// ✅ CORE MATERIAL INFO
final String id;
final String courseId;
final String title;
final String? description;
final MaterialType type;
final String? url;
final String? filePath;
final AttachmentModel? attachment;
final String authorId;
final String authorName;
final DateTime createdAt;
final DateTime? updatedAt;
final bool isPublished;
```

### B. MaterialTrackingModel - ✅ NEW SYSTEM

#### Purpose
- **Root Collection**: `materialTracking` 
- **Composite ID**: `${materialId}_${studentId}`
- **Who Tracking**: Theo dõi "AI" đã xem/tải tài liệu

#### Fields
```dart
class MaterialTrackingModel {
  final String id; // Composite: materialId_studentId
  final String materialId;
  final String courseId;
  final String studentId;
  final String groupId; // ✅ QUAN TRỌNG: Từ Enrollment để stats theo nhóm
  final bool hasViewed; // "Who has viewed"
  final bool hasDownloaded; // "Who has downloaded"
  final DateTime lastViewedAt;
  final DateTime? lastDownloadedAt;
}
```

#### Key Methods
```dart
// Static ID generation
static String generateId({required String materialId, required String studentId});

// State changes
MaterialTrackingModel markAsViewed();
MaterialTrackingModel markAsDownloaded();
```

### C. MaterialTrackingRepository - ✅ DATA LAYER

#### Core Operations
```dart
class MaterialTrackingRepository {
  // Log events
  Future<void> logViewEvent(MaterialTrackingModel data);
  Future<void> logDownloadEvent(MaterialTrackingModel data);
  
  // Query stats
  Future<List<MaterialTrackingModel>> getStatsForMaterial(String materialId);
  Future<List<MaterialTrackingModel>> getStatsForCourse(String courseId);
  Future<List<MaterialTrackingModel>> getStudentActivity(String studentId);
  
  // Group analytics
  Future<Map<String, List<MaterialTrackingModel>>> getGroupStats(String materialId);
  
  // Cleanup
  Future<void> bulkDeleteTrackingForMaterial(String materialId);
}
```

#### Logic Flow
1. **logViewEvent()**: Set/Update document với `hasViewed: true`
2. **logDownloadEvent()**: Set/Update document với `hasDownloaded: true` (auto-mark viewed)
3. **getStatsForMaterial()**: Query by `materialId` để lấy tất cả tracking records

### D. MaterialTrackingController - ✅ BUSINESS LOGIC

#### Workflow Authority
```dart
class MaterialTrackingController {
  // Main event handlers
  Future<void> handleViewEvent({materialId, courseId, studentId});
  Future<void> handleDownloadEvent({materialId, courseId, studentId});
  
  // Stats for UI
  Future<MaterialStats> getStatsForMaterial(String materialId);
  Future<Map<String, dynamic>> getDetailedStatsForInstructor(String materialId);
}
```

#### Critical Business Logic
```dart
Future<void> handleViewEvent({...}) async {
  // 1. ✅ LẤY GROUPID TỪ ENROLLMENT
  final enrollment = await _enrollmentRepository.getEnrollment(courseId, studentId);
  final groupId = enrollment.groupId; // Strict Enrollment đảm bảo có groupId
  
  // 2. ✅ TẠO TRACKING RECORD VỚI GROUPID
  final trackingData = MaterialTrackingModel(
    id: MaterialTrackingModel.generateId(materialId: materialId, studentId: studentId),
    groupId: groupId, // QUAN TRỌNG cho thống kê theo nhóm
    hasViewed: true,
    lastViewedAt: DateTime.now(),
  );
  
  // 3. ✅ GHI NHẬT KÝ VÀO FIREBASE
  await _trackingRepository.logViewEvent(trackingData);
}
```

### E. MaterialStats - ✅ ANALYTICS MODEL

#### Structured Statistics
```dart
class MaterialStats {
  final String materialId;
  final int totalViews;
  final int totalDownloads;
  final Map<String, int> viewsByGroup; // groupId -> count
  final Map<String, int> downloadsByGroup; // groupId -> count
  final List<MaterialTrackingModel> recentActivity;
  
  // Auto-generate from tracking list
  factory MaterialStats.fromTrackingList(String materialId, List<MaterialTrackingModel> trackingList);
}
```

---

## 📊 Firebase Structure

### Old Structure (WRONG)
```
courses/{courseId}/materials/{materialId}
{
  targetGroupIds: [groupId1, groupId2], // ❌ Vi phạm yêu cầu
  downloadCount: 15 // ❌ Không biết "ai" đã tải
}
```

### New Structure (CORRECT)
```
// Materials (unchanged core data)
courses/{courseId}/materials/{materialId}
{
  id, title, description, type, url, authorId, authorName, createdAt, isPublished
  // ✅ NO targetGroupIds, NO downloadCount
}

// Tracking (new root collection)
materialTracking/{materialId}_{studentId}
{
  materialId: "mat123",
  courseId: "course456", 
  studentId: "student789",
  groupId: "group001", // ✅ Từ Enrollment để stats theo nhóm
  hasViewed: true,
  hasDownloaded: false,
  lastViewedAt: "2025-11-16T10:30:00Z",
  lastDownloadedAt: null
}
```

---

## 🔄 Migration Impact

### Code Changes Required

#### 1. UI Components
```dart
// ❌ OLD - BROKEN
Text('Downloads: ${material.downloadCount}')
if (material.isForAllGroups) { ... }

// ✅ NEW - Use MaterialTrackingController
final stats = await materialTrackingController.getStatsForMaterial(materialId);
Text('Total Downloads: ${stats.totalDownloads}')
Text('Views by Group: ${stats.viewsByGroup}')
```

#### 2. Repository Updates  
```dart
// ❌ OLD - createMaterial with targetGroupIds
await materialRepository.createMaterial(
  material.copyWith(targetGroupIds: [groupId])
);

// ✅ NEW - No group scoping needed
await materialRepository.createMaterial(material);
```

#### 3. Event Tracking Integration
```dart
// ✅ NEW - Track user interactions
// When student views material
await materialTrackingController.handleViewEvent(
  materialId: materialId,
  courseId: courseId, 
  studentId: currentUserId,
);

// When student downloads material  
await materialTrackingController.handleDownloadEvent(
  materialId: materialId,
  courseId: courseId,
  studentId: currentUserId,
);
```

### Data Migration Script
```dart
// Migration for existing materials
Future<void> migrateMaterials() async {
  final materials = await firestore.collection('materials').get();
  
  for (final doc in materials.docs) {
    // Remove deprecated fields
    await doc.reference.update({
      'targetGroupIds': FieldValue.delete(),
      'downloadCount': FieldValue.delete(),
    });
  }
}
```

---

## 🎯 Benefits Achieved

### 1. Compliance ✅
- **PDF Requirement**: Materials không phân theo nhóm
- **Who Tracking**: Biết chính xác "ai" đã xem/tải

### 2. Enhanced Analytics 📊
- **Group Breakdown**: Stats theo từng nhóm cho Giảng viên
- **Individual Tracking**: Lịch sử cá nhân từng sinh viên  
- **Real-time Stats**: Stream updates cho dashboard

### 3. Better Architecture 🏗️
- **Separation of Concerns**: Material data vs Tracking data
- **Scalable**: Root collection dễ query cross-course
- **GDPR Ready**: Dễ xóa tracking data khi cần

### 4. Rich UI Possibilities 🎨
```dart
// Instructor Dashboard
- "Material X: 15 views, 8 downloads"
- "Group A: 80% viewed, Group B: 60% viewed"
- "Recent activity: Student123 downloaded Material Y 5 mins ago"

// Student Progress
- "You have viewed 12/15 materials in this course"
- "Materials you haven't seen yet: [list]"
```

---

## 🧪 Testing Scenarios

### 1. Basic Tracking
```dart
// Test view event
await controller.handleViewEvent(materialId: 'mat1', courseId: 'course1', studentId: 'student1');
final stats = await controller.getStatsForMaterial('mat1');
expect(stats.totalViews, equals(1));

// Test download event  
await controller.handleDownloadEvent(materialId: 'mat1', courseId: 'course1', studentId: 'student1');
final updatedStats = await controller.getStatsForMaterial('mat1');
expect(updatedStats.totalDownloads, equals(1));
expect(updatedStats.totalViews, equals(1)); // Auto-marked as viewed
```

### 2. Group Statistics
```dart
// Multiple students from different groups
await controller.handleViewEvent(materialId: 'mat1', courseId: 'course1', studentId: 'student1'); // Group A
await controller.handleViewEvent(materialId: 'mat1', courseId: 'course1', studentId: 'student2'); // Group B

final groupStats = await controller.getGroupStats('mat1');
expect(groupStats['groupA']?.length, equals(1));
expect(groupStats['groupB']?.length, equals(1));
```

### 3. Error Handling
```dart
// Student not enrolled
expect(
  () => controller.handleViewEvent(materialId: 'mat1', courseId: 'course1', studentId: 'invalid'),
  throwsA(contains('chưa được ghi danh')),
);
```

---

## 🚀 Implementation Status

### ✅ Completed
- [x] MaterialModel cleanup (removed targetGroupIds, downloadCount)
- [x] MaterialTrackingModel creation
- [x] MaterialTrackingRepository implementation  
- [x] MaterialTrackingController business logic
- [x] MaterialStats analytics model
- [x] UI updates (material_detail_page.dart)

### 🔄 Recommended Next Steps
- [ ] Update remaining UI components to use new tracking system
- [ ] Implement MaterialController for CRUD operations
- [ ] Add tracking calls to material view/download workflows
- [ ] Create instructor dashboard with group statistics
- [ ] Add migration script for existing data
- [ ] Unit tests for tracking system

---

## 📁 Files Changed

### New Files Created
- `lib/domain/models/material_tracking_model.dart`
- `lib/data/repositories/material_tracking_repository.dart`  
- `lib/application/controllers/material_tracking_controller.dart`
- `docs/MATERIAL_REFACTOR.md` (this file)

### Modified Files
- `lib/domain/models/material_model.dart` - Removed targetGroupIds, downloadCount
- `lib/presentation/screens/course/Student_Course/material/material_detail_page.dart` - Removed downloadCount display

### Files to Review
- `lib/data/repositories/material/material_repository.dart` - Check for targetGroupIds usage
- `lib/application/controllers/material/*.dart` - Update material CRUD operations
- UI components using material model - Update to new tracking system

---

**Date**: 2025-11-16  
**Status**: ✅ CORE REFACTOR COMPLETED  
**Next Phase**: UI Integration & Testing