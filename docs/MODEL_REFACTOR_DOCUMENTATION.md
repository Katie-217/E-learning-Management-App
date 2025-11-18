# 📋 MODEL REFACTOR DOCUMENTATION

**Ngày thực hiện:** November 18, 2025  
**Tác giả:** AI Assistant  
**Mục đích:** Refactor CommentModel và MaterialTrackingModel theo yêu cầu dự án

---

## 🔄 REFACTOR & NEW MODEL SUMMARY

### 1. 💬 **CommentModel Refactor (SIMPLIFIED)**

#### **Lý do Refactor:**
- Dự án phân biệt **Announcement** (đơn giản) vs **Forum** (phức tạp)
- CommentModel hiện tại quá phức tạp (như Forum)
- Announcement chỉ cần "short comment threads" (chuỗi bình luận ngắn)

#### **Các thay đổi đã thực hiện:**

##### ❌ **REMOVED (Đã xóa):**
```dart
// XÓA Reply Logic
final List<String> replyIds;
final String parentType;
bool get hasReplies => replyIds.isNotEmpty;

// XÓA Like Logic  
final int likeCount;
final List<String> likedBy;
bool isLikedBy(String userId);
CommentModel toggleLike(String userId);
```

##### ✅ **CHANGED (Đã thay đổi):**
```dart
// ĐỔI TÊN
final String parentId; → final String announcementId;
```

##### ✅ **KEPT (Giữ lại):**
```dart
// Các trường cần thiết cho Comment đơn giản
final String id;
final String announcementId; // Liên kết trực tiếp với Announcement
final String courseId;
final String content;
final String authorId;
final String authorName;
final String authorRole;
final DateTime createdAt;
final DateTime? updatedAt;
final bool isEdited;
final bool isDeleted;
String get timeAgo; // Getter hiển thị thời gian
```

#### **Kết quả:**
- Model trở thành "flat" (phẳng) và đơn giản
- Chỉ liên kết trực tiếp với Announcement mẹ
- Phù hợp với yêu cầu "simplified comment threads"

---

### 2. 📈 **MaterialTrackingModel Verification (ENRICHED)**

#### **Lý do cần Model này:**
- Đáp ứng yêu cầu "track who has viewed or downloaded materials"
- Cần `groupId` để Giảng viên xem thống kê theo nhóm
- Thay thế `downloadCount` cũ bằng tracking chi tiết

#### **Các trường đã có đầy đủ:**

##### ✅ **CORE FIELDS:**
```dart
final String id;           // Composite ID: [materialId]_[studentId]
final String materialId;   // ID của Material đã xem
final String courseId;     // ID của Course mẹ
final String studentId;    // ID của sinh viên
final String groupId;      // ⭐ QUAN TRỌNG: Cho thống kê theo nhóm
```

##### ✅ **TRACKING FIELDS:**
```dart
final bool hasViewed;      // Đáp ứng "who has viewed"
final bool hasDownloaded;  // Đáp ứng "who has downloaded"
final DateTime lastViewedAt;      // Timestamp xem cuối
final DateTime? lastDownloadedAt; // Timestamp download cuối
```

##### ✅ **UTILITY METHODS:**
```dart
static String generateId({required String materialId, required String studentId});
MaterialTrackingModel markAsViewed();
MaterialTrackingModel markAsDownloaded();
```

#### **Kết quả:**
- Model đã sẵn sàng cho tracking requirements
- Có đủ thông tin cho UI statistics
- Hỗ trợ group-based reporting

---

### 3. 📢 **AnnouncementTrackingModel Creation (NEW)**

#### **Lý do tạo Model này:**
- Đáp ứng yêu cầu PDF: "track who has viewed the announcement and who has downloaded attached files"
- Giải quyết vấn đề: AnnouncementModel không thể lưu mảng "ai đã xem" (vi phạm giới hạn 1MB Firebase)
- Thiết kế 2-Model Architecture: AnnouncementModel (content) + AnnouncementTrackingModel (tracking logs)

#### **Thiết kế Architecture:**

##### ✅ **Firebase Collection:**
```
announcementTracking/ (Root Collection - ngang hàng với users, enrollments)
├── {announcementId}_{studentId}/  (Composite ID Document)
│   ├── announcementId: "ann_123"
│   ├── studentId: "student_456" 
│   ├── courseId: "course_789" (Denormalized)
│   ├── groupId: "group_ABC" (⭐ Quan trọng cho UI thống kê)
│   ├── hasViewed: true/false
│   ├── hasDownloaded: true/false
│   ├── lastViewedAt: timestamp
│   └── lastDownloadedAt: timestamp?
```

##### ✅ **Core Features Implemented:**
```dart
// COMPOSITE ID PATTERN cho performance tối ưu
static String generateId({required String announcementId, required String studentId});

// TRACKING ACTIONS
AnnouncementTrackingModel markAsViewed();    // Đánh dấu đã xem
AnnouncementTrackingModel markAsDownloaded(); // Đánh dấu đã tải

// TIME UTILITIES  
String get timeAgo;          // "2 giờ trước"
String? get downloadTimeAgo; // "1 ngày trước" (nếu đã download)

// DENORMALIZED FIELDS cho Query Performance
final String courseId;  // Không cần join với Announcement
final String groupId;   // Cho statistics theo nhóm
```

##### ✅ **Business Logic:**
- **Composite ID Strategy:** `[announcementId]_[studentId]` cho upsert siêu nhanh
- **Denormalization:** Copy `courseId`, `groupId` để tránh join queries
- **Two-Boolean Tracking:** `hasViewed` + `hasDownloaded` đáp ứng đầy đủ requirements
- **Timestamp Precision:** Track cả thời gian xem và download riêng biệt

#### **Use Cases được hỗ trợ:**
1. **Student Action Tracking:** Mỗi khi student click announcement → `markAsViewed()`
2. **File Download Tracking:** Mỗi khi student download attachment → `markAsDownloaded()`
3. **Instructor Statistics:** Query theo `courseId` + `groupId` để xem statistics
4. **Individual Progress:** Check specific student đã xem announcement chưa
5. **Bulk Analytics:** Count tổng views/downloads per announcement

#### **Kết quả:**
- Model hoàn chỉnh cho Announcement tracking requirements
- Performance tối ưu với Composite ID pattern
- UI-ready với denormalized fields cho group statistics
- Scalable architecture (không vi phạm Firebase limits)

---

## 🧹 CLEANUP STATUS

### ✅ **Files Checked for Old Logic:**
- **CommentModel references:** Chỉ có trong chính file model (đã sửa)
- **Old logic usage:** Không có file nào sử dụng logic cũ
- **ForumTopicModel:** Vẫn giữ logic riêng cho Forum (đúng)

### ✅ **Import Statements:**
- Tất cả imports đã được kiểm tra
- Không cần thay đổi imports vì chỉ thay đổi nội dung model

### ✅ **Database Collections:**
- CommentModel: Sẽ lưu với `announcementId` thay vì `parentId`
- MaterialTrackingModel: Đã sử dụng root collection `materialTracking/`

---

## 🎯 IMPACT ANALYSIS

### **CommentModel Changes Impact:**
1. **Repository Layer:** Cần update query từ `parentId` → `announcementId`
2. **UI Layer:** Bỏ UI cho Reply và Like functionality
3. **Database:** Migration data từ `parentId` → `announcementId`

### **MaterialTrackingModel Impact:**
1. **Already Implemented:** Model đã đầy đủ requirements
2. **Controller Ready:** MaterialTrackingController đã sử dụng đúng
3. **UI Ready:** Statistics UI có thể dùng groupId

### **AnnouncementTrackingModel Impact:**
1. **New Repository Needed:** AnnouncementTrackingRepository cho CRUD operations
2. **Controller Integration:** Update AnnouncementController để handle tracking
3. **UI Components:** 
   - Student UI: Auto-track khi view/download announcements
   - Instructor UI: Statistics dashboard với group-based filtering
4. **Database Setup:** Tạo Firestore collection `announcementTracking/`
5. **Index Requirements:** Composite indexes cho `courseId` + `groupId` queries

---

## 📋 TODO NEXT STEPS

### **For CommentModel:**
1. ✅ Model refactor (COMPLETED)
2. 🔄 Update CommentRepository queries
3. 🔄 Update UI components
4. 🔄 Database migration script

### **For MaterialTrackingModel:**
1. ✅ Model verification (COMPLETED)
2. ✅ Controller integration (ALREADY DONE)
3. 🔄 UI statistics implementation
4. 🔄 Group-based reporting

### **For AnnouncementTrackingModel:**
1. ✅ Model creation (COMPLETED)
2. 🔄 AnnouncementTrackingRepository creation
3. 🔄 Controller integration with AnnouncementController
4. 🔄 Student UI auto-tracking implementation
5. 🔄 Instructor statistics dashboard
6. 🔄 Firestore collection setup & indexes

---

## 🏁 CONCLUSION

**CommentModel:** Đã được đơn giản hóa thành công, phù hợp với Announcement requirements.

**MaterialTrackingModel:** Đã sẵn sàng với đầy đủ fields cho material tracking requirements.

**AnnouncementTrackingModel:** Đã được thiết kế hoàn chỉnh với Composite ID pattern và denormalized fields, sẵn sàng đáp ứng tracking requirements.

**3-Model Announcement System:**
- `AnnouncementModel` (Sub-collection): Content storage
- `CommentModel` (Simplified): Simple comments under announcements  
- `AnnouncementTrackingModel` (Root collection): Who viewed/downloaded tracking

**Compatibility:** Các thay đổi không ảnh hưởng đến ForumTopicModel và logic Forum.

**Next Phase:** Implement Repository và Controller cho AnnouncementTrackingModel, sau đó update UI components.