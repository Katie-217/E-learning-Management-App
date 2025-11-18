# 📢 AnnouncementTrackingModel Usage Examples

**File:** `lib/domain/models/announcement_tracking_model.dart`  
**Collection:** `announcementTracking` (Root Collection)  
**Purpose:** Track "WHO viewed" và "WHO downloaded" announcements

---

## 🚀 Basic Usage Examples

### 1. **Create Tracking Record (Student views announcement)**
```dart
// Khi student click vào announcement
final tracking = AnnouncementTrackingModel(
  id: AnnouncementTrackingModel.generateId(
    announcementId: 'ann_123',
    studentId: 'student_456',
  ),
  announcementId: 'ann_123',
  studentId: 'student_456', 
  courseId: 'course_789',        // Denormalized
  groupId: 'group_ABC',          // Denormalized for statistics
  hasViewed: true,
  hasDownloaded: false,
  lastViewedAt: DateTime.now(),
);
```

### 2. **Mark as Downloaded (Student downloads attachment)**
```dart
// Khi student download file đính kèm
final updatedTracking = existingTracking.markAsDownloaded();
// → hasDownloaded = true, lastDownloadedAt = now
```

### 3. **Quick Check (Has student viewed?)**
```dart
// Composite ID cho upsert siêu nhanh
final trackingId = AnnouncementTrackingModel.generateId(
  announcementId: 'ann_123',
  studentId: 'student_456',
);
// → 'ann_123_student_456'

// Firebase query: doc(trackingId).exists()
```

---

## 📊 Statistics Queries (Instructor Dashboard)

### 1. **Count views per announcement**
```dart
// Query: announcementTracking where announcementId == 'ann_123' && hasViewed == true
// Result: List<AnnouncementTrackingModel> → count views
```

### 2. **Group-based statistics**
```dart
// Query: announcementTracking where courseId == 'course_789' && groupId == 'group_ABC'
// Result: Statistics per group (sử dụng denormalized groupId)
```

### 3. **Download statistics**
```dart
// Query: announcementTracking where announcementId == 'ann_123' && hasDownloaded == true
// Result: List of students who downloaded files
```

---

## 🏗️ Firebase Collection Structure

```
announcementTracking/
├── ann_123_student_456/
│   ├── announcementId: "ann_123"
│   ├── studentId: "student_456"
│   ├── courseId: "course_789"      ← Denormalized
│   ├── groupId: "group_ABC"        ← Denormalized (⭐ Quan trọng)
│   ├── hasViewed: true
│   ├── hasDownloaded: false
│   ├── lastViewedAt: 2025-11-18T10:30:00Z
│   └── lastDownloadedAt: null
├── ann_123_student_789/
└── ann_456_student_456/
```

---

## ⚡ Performance Benefits

1. **Composite ID Pattern:** `[announcementId]_[studentId]`
   - Upsert operations siêu nhanh
   - Không cần query để check existence

2. **Denormalized Fields:** `courseId`, `groupId`
   - Không cần join với other collections
   - Statistics queries execute nhanh

3. **Boolean Flags:** `hasViewed`, `hasDownloaded`
   - Simple filtering cho reports
   - Easy aggregation counts

---

## 🎯 Requirements Fulfilled

✅ **"Track who has viewed the announcement"** → `hasViewed` + `studentId`  
✅ **"Track who has downloaded attached files"** → `hasDownloaded` + `studentId`  
✅ **Group-based statistics** → `groupId` denormalized  
✅ **Performance optimization** → Composite ID pattern  
✅ **Scalability** → Root collection (no 1MB limit)  

---

## 🔗 Integration Points

- **AnnouncementController:** Add tracking methods
- **Student UI:** Auto-call `markAsViewed()` when opening announcements
- **Instructor UI:** Query tracking data for statistics dashboard
- **Repository Layer:** AnnouncementTrackingRepository for CRUD operations