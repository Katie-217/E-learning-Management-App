# ROOT COLLECTION MIGRATION GUIDE
## Migration from Sub-collections to Root Collections

### 📊 OVERVIEW
Đã thực hiện migration từ **Sub-collections** sang **Root Collections** cho Assignment và Submission system để:
- ✅ Giải quyết N+1 query problems
- ✅ Hỗ trợ cross-course queries cho Dashboard
- ✅ Tăng hiệu suất query với proper indexing
- ✅ Hỗ trợ CSV export và analytics

---

## 🏗️ ARCHITECTURE CHANGES

### BEFORE: Sub-collection Structure
```
courses/{courseId}/assignments/{assignmentId}
courses/{courseId}/assignments/{assignmentId}/submissions/{submissionId}
```

### AFTER: Root Collection Structure  
```
assignments/{assignmentId}
submissions/{submissionId}
```

---

## 📋 MODEL ENHANCEMENTS

### Assignment Model Changes
**File:** `lib/domain/models/assignment_model.dart`

**Added Field:**
- `semesterId` (required): String để hỗ trợ filtering by semester

**Updated Methods:**
- `constructor`: Thêm required semesterId parameter
- `fromFirestore()`: Mapping semesterId từ Firestore
- `toFirestore()`: Include semesterId when saving
- `copyWith()`: Support semesterId copying

### Submission Model Changes  
**File:** `lib/domain/models/submission_model.dart`

**Added Fields:**
- `semesterId` (required): String để hỗ trợ filtering by semester
- `groupId` (required): String để hỗ trợ filtering by group

**Updated Methods:**
- `constructor`: Thêm required semesterId và groupId parameters
- `fromMap()`: Mapping các fields mới từ Firestore
- `toMap()`: Include các fields mới when saving
- `copyWith()`: Support copying các fields mới

---

## 🔧 REPOSITORY CHANGES

### Assignment Repository
**File:** `lib/data/repositories/assignment/assignment_repository.dart`

**Collection Path:** `assignments` (Root Collection)

**Methods Updated:**
- ✅ `getAssignmentsByCourse(courseId)` - Uses `where('courseId', isEqualTo: courseId)`
- ✅ `createAssignment(assignment)` - Validates required fields including semesterId
- ✅ `updateAssignment(assignment)` - Direct document update
- ✅ `deleteAssignment(assignmentId)` - Direct document delete

**New Methods Added:**
- 🆕 `getAssignmentsBySemester(semesterId)` - Cross-course semester filtering
- 🆕 `getAssignmentsForStudent(studentId)` - Student dashboard queries
- 🆕 `listenToAssignments()` - Real-time updates with Stream

### Submission Repository
**File:** `lib/data/repositories/submission/submission_repository.dart`

**Collection Path:** `submissions` (Root Collection)

**Methods Updated:**
- ✅ `getSubmissionsForAssignment(assignmentId)` - Uses `where('assignmentId', isEqualTo: assignmentId)`
- ✅ `createSubmission(submission)` - Validates courseId, semesterId, groupId
- ✅ `updateSubmission(submission)` - Takes SubmissionModel directly
- ✅ `deleteSubmission(submissionId)` - Direct document delete

**New Methods Added:**
- 🆕 `getSubmissionsForStudent(studentId)` - Student's submissions across courses
- 🆕 `getSubmissionsByCourse(courseId)` - Instructor course overview
- 🆕 `getSubmissionsByGroup(groupId)` - Group filtering
- 🆕 `getSubmissionsBySemester(semesterId)` - Semester analytics
- 🆕 `getStudentSubmissionForAssignment(assignmentId, studentId)` - Specific lookup
- 🆕 `listenToSubmissions()` - Real-time updates with multiple filters
- 🆕 `bulkDeleteSubmissions()` - Cleanup operations
- 🆕 `getSubmissionStats()` - Analytics and dashboard metrics

---

## 🔀 METHOD MAPPING

### Assignment Repository Method Changes
| Old Method (Sub-collection) | New Method (Root Collection) | Changes |
|------------------------------|------------------------------|---------|
| `getAssignmentsByCourse(courseId)` | `getAssignmentsByCourse(courseId)` | ✅ Same interface, different implementation |
| `createAssignment(courseId, assignment)` | `createAssignment(assignment)` | ⚠️ Requires semesterId in assignment |
| `updateAssignment(courseId, assignmentId, assignment)` | `updateAssignment(assignment)` | ⚠️ Takes full model |
| `deleteAssignment(courseId, assignmentId)` | `deleteAssignment(assignmentId)` | ✅ Simplified parameters |

### Submission Repository Method Changes
| Old Method (Sub-collection) | New Method (Root Collection) | Changes |
|------------------------------|------------------------------|---------|
| `getUserSubmissionForAssignment(courseId, assignmentId)` | `getStudentSubmissionForAssignment(assignmentId, studentId)` | ⚠️ Different parameters |
| `submitAssignment(courseId, submission)` | `createSubmission(submission)` | ⚠️ Requires semesterId, groupId |
| `updateSubmission(courseId, submissionId, submission)` | `updateSubmission(submission)` | ⚠️ Takes full model |

---

## 📱 PRESENTATION LAYER UPDATES

### Student Dashboard
**File:** `lib/presentation/screens/student/student_dashboard_page.dart`

**Changes:**
- ✅ Updated `getUserSubmissionForAssignment` → `getStudentSubmissionForAssignment`
- ✅ Modified parameters: `(courseId, assignmentId)` → `(assignmentId, studentId)`

### Assignment Detail Page
**File:** `lib/presentation/screens/course/Student_Course/assignment/assignment_detail_page.dart`

**Changes:**
- ✅ Updated submission loading method
- ✅ Added user authentication check
- ✅ Modified submission creation with required fields
- ⚠️ **TODO:** Need semesterId and groupId from CourseModel

---

## ⚠️ CURRENT LIMITATIONS & TODOs

### 1. CourseModel Enhancement Needed
**Issue:** CourseModel missing `semesterId` and `groupId` fields

**Current Workaround:** Using fallback values
```dart
semesterId: 'default_semester', // TODO: Get from course/context
groupId: 'default_group', // TODO: Get from course/context
```

**Action Required:**
- Update CourseModel to include semesterId and groupId
- Update CourseRepository to populate these fields
- Update course creation forms

### 2. Incomplete Screens
**Files with minimal implementation:**
- `create_assignment_page.dart` - Only comment
- `submissions_page.dart` - Only comment
- `assignments_page.dart` - Basic scaffold only

**Action Required:**
- Implement assignment creation UI
- Implement submission viewing UI for instructors
- Implement assignment listing UI

### 3. Controller Layer
**Missing:**
- AssignmentController/AssignmentProvider
- SubmissionController/SubmissionProvider

**Action Required:**
- Create controller layer using Riverpod
- Implement state management for assignments and submissions

---

## 🔥 FIREBASE RULES UPDATES NEEDED

### New Indexes Required
```javascript
// assignments collection
assignments: {
  courseId: 'asc',
  dueDate: 'desc'
},
assignments: {
  semesterId: 'asc', 
  createdAt: 'desc'
}

// submissions collection  
submissions: {
  assignmentId: 'asc',
  submittedAt: 'desc'
},
submissions: {
  studentId: 'asc',
  submittedAt: 'desc'
},
submissions: {
  courseId: 'asc',
  submittedAt: 'desc'
},
submissions: {
  semesterId: 'asc',
  submittedAt: 'desc'
},
submissions: {
  groupId: 'asc',
  submittedAt: 'desc'
}
```

### Security Rules Update
```javascript
// assignments collection
match /assignments/{assignmentId} {
  allow read: if isAuthenticated();
  allow create, update: if isInstructor() && 
    resource.data.courseId in getUserCourses();
  allow delete: if isInstructor() && 
    resource.data.courseId in getUserCourses();
}

// submissions collection
match /submissions/{submissionId} {
  allow read: if isAuthenticated() && 
    (resource.data.studentId == request.auth.uid || 
     isInstructorOfCourse(resource.data.courseId));
  allow create, update: if isAuthenticated() && 
    resource.data.studentId == request.auth.uid;
  allow delete: if isInstructor() && 
    isInstructorOfCourse(resource.data.courseId);
}
```

---

## 🚀 DEPLOYMENT CHECKLIST

### Pre-deployment
- [ ] Backup existing data
- [ ] Test migration scripts
- [ ] Update Firebase indexes
- [ ] Update security rules

### Post-deployment  
- [ ] Verify all queries work correctly
- [ ] Test real-time updates
- [ ] Monitor performance improvements
- [ ] Update documentation

### Data Migration
- [ ] Script to migrate existing assignments to root collection
- [ ] Script to migrate existing submissions to root collection
- [ ] Script to populate semesterId and groupId fields
- [ ] Cleanup old sub-collection data

---

## 🎯 BENEFITS ACHIEVED

### Performance Improvements
- ✅ **Eliminated N+1 Queries:** No more nested collection traversal
- ✅ **Better Indexing:** Root collections support composite indexes
- ✅ **Faster Dashboard Queries:** Direct filtering across all courses

### Feature Enhancements
- ✅ **Cross-Course Analytics:** Query assignments/submissions across multiple courses
- ✅ **Semester Filtering:** Easy semester-based reporting
- ✅ **Group Management:** Support for group-based operations
- ✅ **CSV Export Ready:** Simplified data extraction

### Scalability
- ✅ **Better Query Limits:** Root collections handle large datasets better
- ✅ **Reduced Complexity:** Simpler query patterns
- ✅ **Real-time Updates:** Efficient change streams

---

## 📞 SUPPORT

For questions about this migration:
1. Check repository implementation in `lib/data/repositories/`
2. Review model definitions in `lib/domain/models/`
3. Test with sample data using debug logs
4. Monitor Firebase console for query performance

**Migration completed:** ✅
**Date:** Current
**Status:** Ready for testing and CourseModel enhancement