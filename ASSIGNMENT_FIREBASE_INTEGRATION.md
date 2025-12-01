# Assignment Firebase Integration - Implementation Summary

## Overview
Implemented full Firebase integration for assignments with real-time updates and publish functionality, sorted by newest first (createdAt descending).

## Changes Made

### 1. Assignment Model - Added `createdAt` Field
**File**: `lib/domain/models/assignment_model.dart`

**Changes**:
- Added `final DateTime createdAt` field
- Updated constructor with `createdAt` parameter (defaults to `DateTime.now()`)
- Updated `fromFirestore()` to parse `createdAt` from Firebase
- Updated `toFirestore()` to write `createdAt` as Timestamp
- Updated `copyWith()` method to include `createdAt`

**Purpose**: Enable sorting assignments by creation date (newest first)

---

### 2. Assignment Repository - Sort by `createdAt` Descending
**File**: `lib/data/repositories/assignment/assignment_repository.dart`

**Changes**:
- **`getAssignmentsByCourse()`**: Changed `orderBy('deadline')` to `orderBy('createdAt', descending: true)`
- **`listenToAssignments()`**: Changed `orderBy('deadline')` to `orderBy('createdAt', descending: true)`
- In-memory fallback sort: `assignments.sort((a, b) => b.createdAt.compareTo(a.createdAt))`
- Removed unused `import 'package:firebase_auth/firebase_auth.dart';`

**Purpose**: Fetch and stream assignments sorted by newest first

---

### 3. Assignment Controller - Uncommented `createAssignment`
**File**: `lib/application/controllers/assignment/assignment_controller.dart`

**Changes**:
- Uncommented `createAssignment()` method (lines 114-141)
- Method signature: `Future<bool> createAssignment(Assignment assignment)`
- Calls `AssignmentRepository.createAssignment(assignment)`
- Reloads assignments after creation using `loadAssignmentsByCourse()`
- Returns `true` on success, `false` on failure

**Purpose**: Enable creating new assignments through the controller layer

---

### 4. Create Assignment Page - Implemented `_publishAssignment`
**File**: `lib/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/create_assignment_page.dart`

**Changes**:
- Changed from `StatefulWidget` to `ConsumerStatefulWidget` (Riverpod)
- Added imports:
  - `flutter_riverpod`
  - `assignment_controller.dart`
  - `assignment_model.dart`
- Implemented full `_publishAssignment()` function:
  - Form validation for required fields
  - Date/time combining (schedule, due, late deadline)
  - Convert `UploadedFileModel` to attachments format (using correct fields: `filePath`, `fileSizeBytes`, `fileExtension`)
  - Convert `LinkMetadata` to attachments format (using correct fields: `url`, `title`, `imageUrl`, `domain`)
  - Fetch group IDs from group names (supports "All Groups")
  - Parse allowed file formats from comma-separated string
  - Create `Assignment` object with `widget.course.semester` as `semesterId`
  - Show loading dialog during creation
  - Call `AssignmentController.createAssignment()`
  - Show success/error messages
  - Navigate back on success

**Purpose**: Allow instructors to create and publish assignments to Firebase

---

### 5. Instructor Classwork Tab - Real-time Firebase Stream
**File**: `lib/presentation/screens/instructor/classwork_tab/instructor_classwork_tab.dart`

**Changes**:
- Changed from `StatefulWidget` to `ConsumerStatefulWidget` (Riverpod)
- Added imports:
  - `flutter_riverpod`
  - `assignment_model.dart`
  - `assignment_repository.dart`
  - `intl` for date formatting
- Created `assignmentStreamProvider` (StreamProvider.family):
  - Uses `AssignmentRepository.listenToAssignments(courseId: courseId)`
  - Provides real-time updates when assignments are created/updated/deleted
- Replaced mock `ListView` with `Consumer` + `assignmentsAsync.when()`:
  - **data**: Shows list of assignments with real data
  - **loading**: Shows CircularProgressIndicator
  - **error**: Shows error message with details
  - **empty**: Shows "No assignments yet" message
- Updated `_buildAssignmentItem()` to accept optional `Assignment` parameter
- Display due date with `DateFormat('MMM dd, h:mm a').format(assignment.deadline)`

**Purpose**: Display assignments in real-time from Firebase, sorted newest first

---

## Key Features Implemented

### ✅ Sort by Newest First
- All queries use `orderBy('createdAt', descending: true)`
- Assignments with most recent `createdAt` appear at the top

### ✅ Real-time Updates
- `listenToAssignments()` returns `Stream<List<Assignment>>`
- UI automatically updates when assignments are added/modified/deleted
- No need to manually refresh

### ✅ Publish Functionality
- Full form validation (title, groups, schedule, due date)
- Supports file attachments and links
- Supports group assignment (individual groups or "All Groups")
- Shows loading indicator during creation
- Success/error feedback with SnackBar

### ✅ Architecture Compliance
- **UI Layer**: `instructor_classwork_tab.dart`, `create_assignment_page.dart`
- **Application Layer**: `assignment_controller.dart` with Riverpod
- **Data Layer**: `assignment_repository.dart` with Firebase
- **Domain Layer**: `assignment_model.dart` with business logic

---

## Firebase Collection Structure

```
assignments (Root Collection)
├── {assignmentId}
│   ├── courseId: "course123"
│   ├── semesterId: "Fall 2024"
│   ├── title: "Assignment Title"
│   ├── description: "Instructions..."
│   ├── startDate: Timestamp
│   ├── deadline: Timestamp
│   ├── createdAt: Timestamp ← NEW FIELD
│   ├── allowLateSubmissions: boolean
│   ├── lateDeadline: Timestamp?
│   ├── maxSubmissionAttempts: number
│   ├── allowedFileFormats: string[]
│   ├── maxFileSizeMB: number
│   ├── attachments: Map[]
│   │   ├── { type: 'file', fileName: '...', url: '...', fileSize: ..., fileType: '...' }
│   │   └── { type: 'link', url: '...', title: '...', imageUrl: '...', domain: '...' }
│   └── groupIds: string[]
```

---

## Firestore Index Requirement

To support `where + orderBy`, you may need to create a composite index:

**Index**: `assignments`
- **Field**: `courseId` (Ascending)
- **Field**: `createdAt` (Descending)

If you get an index error, Firebase will provide a link in the console to auto-create the index.

---

## Testing Checklist

- [ ] Create assignment with all fields filled
- [ ] Verify assignment appears in list immediately (real-time)
- [ ] Verify newest assignments appear at top of list
- [ ] Test with file attachments
- [ ] Test with link attachments
- [ ] Test with "All Groups" selected
- [ ] Test with specific groups selected
- [ ] Verify loading indicator shows during creation
- [ ] Verify success message shows after creation
- [ ] Test error handling (missing required fields)
- [ ] Test late submission toggle
- [ ] Verify assignment has `createdAt` timestamp in Firebase

---

## Usage Example

### Creating an Assignment
```dart
final assignment = Assignment(
  id: '', // Auto-generated by Firebase
  courseId: 'course123',
  semesterId: 'Fall 2024',
  title: 'Homework 1',
  description: 'Complete exercises 1-5',
  startDate: DateTime.now(),
  deadline: DateTime.now().add(Duration(days: 7)),
  createdAt: DateTime.now(), // NEW
  allowLateSubmissions: true,
  lateDeadline: DateTime.now().add(Duration(days: 10)),
  maxSubmissionAttempts: 2,
  allowedFileFormats: ['.pdf', '.docx'],
  maxFileSizeMB: 10,
  attachments: [
    {'type': 'file', 'fileName': 'instructions.pdf', 'url': '...'},
    {'type': 'link', 'url': 'https://youtube.com/...', 'title': 'Tutorial'},
  ],
  groupIds: ['group1', 'group2'],
);

final controller = ref.read(assignmentControllerProvider.notifier);
final success = await controller.createAssignment(assignment);
```

### Listening to Assignments
```dart
final assignmentsStream = ref.watch(assignmentStreamProvider(courseId));

assignmentsStream.when(
  data: (assignments) => ListView.builder(...),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

---

## Notes

- **Course Model**: Uses `semester` field as `semesterId` (CourseModel doesn't have separate `semesterId`)
- **File Attachments**: Stored as local paths (`filePath`), not URLs. You may need to upload to Firebase Storage separately.
- **Submission Count**: Currently shows `0` in UI - needs integration with submission repository
- **Edit/Delete**: Popup menu exists but actions not implemented yet

---

## Related Files

- `lib/domain/models/assignment_model.dart`
- `lib/data/repositories/assignment/assignment_repository.dart`
- `lib/application/controllers/assignment/assignment_controller.dart`
- `lib/presentation/screens/instructor/classwork_tab/instructor_classwork_tab.dart`
- `lib/presentation/widgets/course/Instructor_Course/classwork_tab_widget/assignment/create_assignment_page.dart`

---

**Implementation Date**: 2025
**Status**: ✅ Complete
**Tested**: Pending manual testing
