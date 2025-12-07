# 📚 E-Learning Management System

> A comprehensive, production-ready e-learning platform built with **Flutter**, **Firebase**, and **Cloud Functions**. Features role-based access control, real-time collaboration, automated grading, and email notifications.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Environment Setup](#-environment-setup)
- [Firebase Configuration](#-firebase-configuration)
- [Cloud Functions](#-cloud-functions)
- [Database Schema](#-database-schema)
- [User Roles](#-user-roles)
- [Features Documentation](#-features-documentation)
- [Development](#-development)
- [Deployment](#-deployment)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

---

## 🎯 Overview

**E-Learning Management System** is a full-featured Learning Management System (LMS) designed for educational institutions. It supports multiple user roles (Instructors, Students), course management, assignments, quizzes, materials, and real-time tracking.

### Key Highlights

- ✅ **Clean Architecture** with feature-based structure
- ✅ **Firebase Integration** (Auth, Firestore, Storage, Cloud Functions)
- ✅ **Real-time Updates** with Firestore streams
- ✅ **Automated Grading** for quizzes via Cloud Functions
- ✅ **Email Notifications** using Nodemailer
- ✅ **Material Tracking** (views, downloads)
- ✅ **CSV Import/Export** for bulk operations
- ✅ **Responsive Design** (Desktop, Tablet, Mobile)
- ✅ **PDF Viewer** with Syncfusion
- ✅ **Link Preview** for external resources

---

## ✨ Features

### 👨‍🏫 Instructor Features

- **Course Management**
  - Create/Edit courses with semester system
  - Manage groups within courses
  - Track student enrollments
  
- **Assignment System**
  - Create assignments with file/link attachments
  - Set due dates and max points
  - Assign to specific groups
  - Grade submissions with feedback
  - Bulk return grades via Cloud Function
  - Email notifications to students

- **Quiz System**
  - Create quizzes with question bank
  - Multiple question types (Multiple Choice)
  - Auto-grading via Cloud Function
  - Time limits and attempt controls
  - Real-time tracking dashboard

- **Material Management**
  - Upload PDF, images, links
  - Track student views and downloads
  - Filter by status (viewed/downloaded)
  - Export tracking data to CSV

- **Analytics Dashboard**
  - Course statistics
  - Student performance tracking
  - Submission status overview
  - Material engagement metrics

### 👨‍🎓 Student Features

- **Course Access**
  - View enrolled courses
  - Access course materials
  - Download/view PDFs inline

- **Assignment Submission**
  - Upload files (PDF, images)
  - Add links
  - Track submission history
  - View grades and feedback

- **Quiz Taking**
  - Timed quiz sessions
  - Auto-save answers
  - Instant results (if enabled)
  - Attempt history

- **Notifications**
  - In-app notifications
  - Email notifications
  - Real-time updates

### 🔧 Admin Features

- **User Management**
  - Bulk create users via CSV
  - Update student emails
  - Delete users completely

- **Semester Management**
  - Create semester templates
  - Activate/deactivate semesters
  - Import semester data from CSV

---

## 🏗️ Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, Controllers)        │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         Application Layer               │
│       (Providers, Use Cases)            │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│          Domain Layer                   │
│     (Models, Entities, Interfaces)      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│           Data Layer                    │
│    (Repositories, Services, APIs)       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│        External Services                │
│  (Firebase, Cloud Functions, Email)     │
└─────────────────────────────────────────┘
```

### State Management

- **Riverpod 2.x** - Reactive state management
- **StreamProvider** - Real-time Firestore data
- **FutureProvider** - Async operations
- **StateNotifier** - Complex state logic

### Navigation

- **go_router** - Declarative routing with deep linking support

---

## 🛠️ Tech Stack

### Frontend (Flutter)

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter | ^3.5.0 |
| Language | Dart | ^3.5.0 |
| State Management | Riverpod | ^2.5.1 |
| Routing | go_router | ^14.2.3 |
| UI Components | Material Design 3 | - |
| PDF Viewer | Syncfusion PDFViewer | ^25.2.7 |
| Charts | fl_chart | ^0.69.0 |
| Local Storage | Hive, SharedPreferences | ^2.2.3 |

### Backend (Firebase)

| Service | Purpose |
|---------|---------|
| Firebase Auth | User authentication (Email/Password, Google) |
| Cloud Firestore | NoSQL database |
| Firebase Storage | File storage |
| Cloud Functions | Serverless backend logic |
| Firebase Analytics | Usage analytics |

### Cloud Functions (Node.js)

| Package | Version | Purpose |
|---------|---------|---------|
| firebase-functions | ^5.0.0 | Cloud Functions SDK |
| firebase-admin | ^12.0.0 | Admin SDK |
| nodemailer | ^7.0.11 | Email service |
| cheerio | ^1.0.0 | HTML parsing for link preview |
| TypeScript | ^5.2.0 | Type safety |

---

## 📁 Project Structure

```
E-learning-Management-App/
│
├── lib/                                    # Flutter source code
│   ├── main.dart                          # App entry point
│   ├── firebase_options.dart              # Firebase config
│   │
│   ├── core/                              # Core functionality
│   │   ├── config/                        # App configuration
│   │   ├── utils/                         # Utilities
│   │   └── constants/                     # Constants
│   │
│   ├── domain/                            # Domain layer
│   │   └── models/                        # Domain models
│   │       ├── user_model.dart
│   │       ├── course_model.dart
│   │       ├── assignment_model.dart
│   │       ├── assignment_tracker_model.dart
│   │       ├── submission_model.dart
│   │       ├── quiz_model.dart
│   │       ├── quiz_submission_model.dart
│   │       ├── quiz_tracker_model.dart
│   │       ├── question_model.dart
│   │       ├── material_model.dart
│   │       ├── material_tracker_model.dart
│   │       ├── semester_model.dart
│   │       ├── enrollment_model.dart
│   │       ├── notification_model.dart
│   │       └── announcement_model.dart
│   │
│   ├── data/                              # Data layer
│   │   ├── repositories/                  # Data repositories
│   │   │   ├── auth/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   └── user_session_service.dart
│   │   │   ├── course/
│   │   │   │   ├── course_instructor_repository.dart
│   │   │   │   ├── course_student_repository.dart
│   │   │   │   └── enrollment_repository.dart
│   │   │   ├── assignment/
│   │   │   │   └── assignment_repository.dart
│   │   │   ├── submission/
│   │   │   │   └── submission_repository.dart
│   │   │   ├── quiz/
│   │   │   │   ├── quiz_repository.dart
│   │   │   │   ├── quiz_submission_repository.dart
│   │   │   │   └── quiz_tracker_repository.dart
│   │   │   ├── question/
│   │   │   │   └── question_repository.dart
│   │   │   ├── material/
│   │   │   │   ├── material_repository.dart
│   │   │   │   ├── material_tracker_repository.dart
│   │   │   │   └── material_tracking_repository.dart
│   │   │   ├── semester/
│   │   │   │   ├── semester_repository.dart
│   │   │   │   ├── semester_import_repository.dart
│   │   │   │   └── semester_template_repository.dart
│   │   │   ├── student/
│   │   │   │   └── student_repository.dart
│   │   │   ├── instructor/
│   │   │   │   ├── instructor_repository.dart
│   │   │   │   ├── instructor_profile_repository.dart
│   │   │   │   └── task_repository.dart
│   │   │   ├── notification/
│   │   │   │   └── notification_repository.dart
│   │   │   ├── assignment_tracker_repository.dart
│   │   │   └── ...
│   │   │
│   │   └── services/                      # Business services
│   │       ├── submission_service.dart
│   │       └── grade_return_service.dart
│   │
│   ├── application/                       # Application layer
│   │   └── providers/                     # Riverpod providers
│   │       ├── auth_provider.dart
│   │       ├── course_provider.dart
│   │       ├── semester_provider.dart
│   │       ├── assignment_provider.dart
│   │       ├── quiz_provider.dart
│   │       ├── material_provider.dart
│   │       ├── material_tracker_provider.dart
│   │       ├── notification_provider.dart
│   │       └── ...
│   │
│   ├── presentation/                      # Presentation layer
│   │   ├── screens/                       # Screen pages
│   │   │   ├── instructor/                # Instructor screens
│   │   │   │   ├── dashboard/
│   │   │   │   ├── classwork_tab/
│   │   │   │   │   ├── assignment/
│   │   │   │   │   ├── quiz/
│   │   │   │   │   └── material/
│   │   │   │   ├── group_tab/
│   │   │   │   └── grade_tab/
│   │   │   │
│   │   │   └── student/                   # Student screens
│   │   │       ├── dashboard/
│   │   │       ├── course/
│   │   │       │   ├── tab_course/
│   │   │       │   │   ├── classwork/
│   │   │       │   │   ├── material/
│   │   │       │   │   └── grades/
│   │   │       │   └── quiz/
│   │   │       └── notifications/
│   │   │
│   │   └── widgets/                       # Reusable widgets
│   │       ├── auth/
│   │       ├── course/
│   │       ├── common/
│   │       └── student/
│   │
│   └── navigation/                        # App navigation
│       └── app_router.dart
│
├── functions/                             # Firebase Cloud Functions
│   ├── src/
│   │   ├── index.ts                      # Main functions file
│   │   └── utils/
│   │       └── emailService.ts           # Email templates
│   ├── .env                              # Environment variables (not in git)
│   ├── package.json                      # Node dependencies
│   └── tsconfig.json                     # TypeScript config
│
├── assets/                                # Static assets
│   ├── icons/
│   └── svg/
│
├── android/                               # Android configuration
├── ios/                                   # iOS configuration
├── web/                                   # Web configuration
├── windows/                               # Windows configuration
├── macos/                                 # macOS configuration
│
├── docs/                                  # Documentation
│   ├── ARCHITECTURE_REFACTOR_SUMMARY.md
│   ├── ASSIGNMENT_CHANGES_SUMMARY.md
│   ├── CLOUD_FUNCTIONS_DEPLOYMENT.md
│   ├── CSV_IMPORT_SYSTEM_DOCUMENTATION.md
│   ├── ENROLLMENT_SYSTEM_GUIDE.md
│   ├── FIRESTORE_INDEX_GUIDE.md
│   ├── PROJECT_STRUCTURE.md
│   ├── SEMESTER_FILTER_IMPLEMENTATION.md
│   └── ...
│
├── firebase.json                          # Firebase configuration
├── firestore.indexes.json                # Firestore indexes
├── pubspec.yaml                          # Flutter dependencies
├── analysis_options.yaml                 # Dart linting rules
└── README.md                             # This file
```

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.5.0 or higher)
- **Dart SDK** (3.5.0 or higher)
- **Node.js** (20.x or higher) - for Cloud Functions
- **Firebase CLI** (`npm install -g firebase-tools`)
- **Git**
- **IDE**: VS Code or Android Studio with Flutter extensions

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/Katie-217/E-learning-Management-App.git
cd E-learning-Management-App
```

2. **Install Flutter dependencies**

```bash
flutter pub get
```

3. **Install Cloud Functions dependencies**

```bash
cd functions
npm install
cd ..
```

4. **Run code generation** (if using build_runner)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🔧 Environment Setup

### 1. Firebase Project Setup

#### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `e-learning-management-79797` (or your preferred name)
4. Enable Google Analytics (optional)
5. Create project

#### Enable Firebase Services

1. **Authentication**
   - Go to **Authentication** → **Sign-in method**
   - Enable **Email/Password**
   - Enable **Google** (configure OAuth consent screen)

2. **Cloud Firestore**
   - Go to **Firestore Database** → **Create database**
   - Start in **production mode** (we'll set rules later)
   - Choose location: `us-central1` or nearest

3. **Cloud Storage**
   - Go to **Storage** → **Get started**
   - Start in **production mode**
   - Use default bucket

4. **Cloud Functions**
   - Automatically enabled when deploying functions
   - Requires Blaze (pay-as-you-go) plan

#### Firebase CLI Login

```bash
firebase login
firebase init
```

Select:
- ✅ Firestore
- ✅ Functions
- ✅ Storage

### 2. Flutter Firebase Configuration

#### Generate Firebase Options

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure
```

This will:
- Create `firebase_options.dart`
- Register apps for all platforms (Android, iOS, Web, etc.)

#### Update `lib/firebase_options.dart`

The generated file should look like:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      // ... other platforms
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'e-learning-management-79797',
    storageBucket: 'e-learning-management-79797.appspot.com',
  );
  
  // ... other platform configs
}
```

### 3. Syncfusion License

This app uses **Syncfusion PDF Viewer**. You need a license key:

1. Register at [Syncfusion](https://www.syncfusion.com/account/register)
2. Get **Community License** (free for individuals/small businesses)
3. Copy license key
4. Update in `lib/main.dart`:

```dart
SyncfusionLicense.registerLicense('YOUR_SYNCFUSION_LICENSE_KEY');
```

---

## 📧 Cloud Functions

### Environment Variables

Create `functions/.env`:

```env
# Email Service (Nodemailer)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Firebase Admin
FIREBASE_PROJECT_ID=e-learning-management-79797
```

#### Gmail App Password Setup

1. Go to Google Account → Security
2. Enable **2-Step Verification**
3. Go to **App passwords**
4. Generate password for "Mail"
5. Copy password to `SMTP_PASS`

### Available Cloud Functions

| Function Name | Type | Trigger | Purpose |
|--------------|------|---------|---------|
| `fetchLinkPreview` | Callable | HTTPS | Fetch metadata for link previews |
| `bulkCreateUsers` | HTTPS Request | HTTPS | Create multiple users from CSV |
| `healthCheck` | HTTPS Request | HTTPS | Check function health |
| `updateStudentEmailV2` | HTTPS Request | HTTPS | Update student email |
| `deleteStudentCompletely` | HTTPS Request | HTTPS | Delete user and all data |
| `onAssignmentWritten` | Firestore Trigger | `assignments/{id}` write | Create/update assignment trackers |
| `onQuizCreated` | Firestore Trigger | `quizzes/{id}` create | Create quiz trackers + send notifications |
| `onQuizSubmissionCompleted` | Firestore Trigger | `quiz_submissions/{id}` write | Auto-grade quiz + send email |
| `onAnnouncementCreated` | Firestore Trigger | `announcements/{id}` create | Send notifications |
| `onMaterialCreated` | Firestore Trigger | `materials/{id}` create | Create material trackers |
| `onSubmissionCreated` | Firestore Trigger | `submissions/{id}` create | Notify instructor |
| `onTrackerUpdated` | Firestore Trigger | `assignment_trackers/{id}` update | Sync tracker data |
| `submitAssignment` | Callable | HTTPS | Submit assignment |
| `startQuiz` | Callable | HTTPS | Start quiz session |
| `returnAssignmentGrades` | Callable | HTTPS | Return grades + send emails |
| `createQuizTrackers` | Callable | HTTPS | Manually create quiz trackers |

### Deploy Cloud Functions

```bash
cd functions

# Build TypeScript
npm run build

# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:onQuizCreated
```

### View Function Logs

```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only onQuizSubmissionCompleted

# Tail logs (real-time)
firebase functions:log --only onQuizCreated --follow
```

---

## 🗄️ Database Schema

### Firestore Collections

#### `users`

```typescript
{
  id: string                    // Document ID (Firebase Auth UID)
  email: string
  fullName: string
  role: 'instructor' | 'student'
  studentId?: string            // For students
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

#### `semesters`

```typescript
{
  id: string
  name: string                  // "HK1 2024-2025"
  startDate: string             // ISO date
  endDate: string
  isActive: boolean
  createdAt: Timestamp
}
```

#### `course_of_study`

```typescript
{
  id: string
  code: string                  // "CS101"
  name: string                  // "Introduction to Programming"
  instructorId: string
  instructorName: string
  semesterId: string
  createdAt: Timestamp
  
  // Subcollection: groups
  groups/{groupId}: {
    id: string
    name: string                // "Group A"
    capacity: number
    currentEnrollment: number
  }
}
```

#### `enrollments`

```typescript
{
  id: string
  userId: string
  courseId: string
  groupId: string
  semesterId: string
  status: 'active' | 'inactive'
  enrolledAt: Timestamp
}
```

#### `assignments`

```typescript
{
  id: string
  courseId: string
  title: string
  description: string
  dueDate: string               // ISO date
  maxPoints: number
  groupIds: string[]            // Target groups
  attachments: Attachment[]
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

#### `assignment_trackers`

```typescript
{
  id: string                    // Composite: "{assignmentId}_{studentId}"
  assignmentId: string
  studentId: string
  courseId: string
  groupId: string
  studentName: string
  studentEmail: string
  groupName: string
  status: 'not_submitted' | 'submitted' | 'graded' | 'returned'
  submissionCount: number
  grade: number | null
  feedback: string | null
  lastSubmissionId: string | null
  gradedAt: Timestamp | null
  returnedAt: Timestamp | null
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

#### `submissions`

```typescript
{
  id: string
  assignmentId: string
  courseId: string
  studentId: string
  studentName: string
  attemptNumber: number
  content: string
  attachments: Attachment[]
  status: 'pending' | 'graded'
  grade: number | null
  feedback: string | null
  submittedAt: Timestamp
  gradedAt: Timestamp | null
}
```

#### `quizzes`

```typescript
{
  id: string
  courseId: string
  title: string
  description: string
  openDate: string              // ISO date
  closeDate: string
  durationMinutes: number
  maxAttempts: number
  points: number
  structure: {                  // Question distribution by topic
    [topic: string]: number
  }
  questions: number             // Total questions
  shuffleAnswers: boolean
  showScore: boolean
  groupIds: string[]
  status: 'upcoming' | 'active' | 'closed'
  createdAt: Timestamp
}
```

#### `quiz_trackers`

```typescript
{
  id: string                    // Composite: "{quizId}_{studentId}"
  quizId: string
  studentId: string
  courseId: string
  groupId: string
  studentName: string
  studentEmail: string
  groupName: string
  status: 'not_started' | 'in_progress' | 'completed'
  attemptCount: number
  score: number | null
  startedAt: Timestamp | null
  lastAttemptAt: Timestamp | null
  completedAt: Timestamp | null
  lastSubmissionId: string | null
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

#### `quiz_submissions`

```typescript
{
  id: string
  quizId: string
  courseId: string
  studentId: string
  studentName: string
  questions: SnapshotQuestion[] // Snapshot of questions at submission time
  answers: {
    [questionId: string]: number // Selected answer index
  }
  status: 'in_progress' | 'completed'
  score: number | null
  maxScore: number
  startedAt: Timestamp
  submittedAt: Timestamp | null
  gradedAt: Timestamp | null
  timeSpentSeconds: number
  isAutoSubmitted: boolean
}
```

#### `questions`

```typescript
{
  id: string
  courseId: string
  topic: string                 // "Variables", "Loops", etc.
  questionText: string
  answers: string[]             // Array of answer options
  correctAnswer: number         // Index of correct answer (0-based)
  difficulty: 'easy' | 'medium' | 'hard'
  createdAt: Timestamp
}
```

#### `materials`

```typescript
{
  id: string
  courseId: string
  title: string
  description: string
  type: 'file' | 'link'
  fileUrl?: string              // For files
  fileName?: string
  fileSize?: number
  linkUrl?: string              // For links
  linkTitle?: string
  linkDescription?: string
  linkImage?: string
  groupIds: string[]
  createdAt: Timestamp
}
```

#### `material_trackers`

```typescript
{
  id: string                    // Composite: "{materialId}_{studentId}"
  materialId: string
  studentId: string
  courseId: string
  groupId: string
  studentName: string
  studentEmail: string
  groupName: string
  hasViewed: boolean
  hasDownloaded: boolean
  viewedAt: Timestamp | null
  downloadedAt: Timestamp | null
  viewCount: number
  downloadCount: number
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

#### `notifications`

```typescript
{
  id: string
  userId: string
  courseId: string
  type: 'assignment' | 'quiz' | 'material' | 'announcement' | 'quiz_graded'
  title: string
  content: string
  relatedId: string             // ID of related entity
  relatedType: string
  priority: 'low' | 'normal' | 'high'
  isRead: boolean
  isArchived: boolean
  metadata: any                 // Additional context
  createdAt: Timestamp
}
```

#### `announcements`

```typescript
{
  id: string
  courseId: string
  title: string
  content: string
  attachments: Attachment[]
  groupIds: string[]
  createdBy: string
  createdAt: Timestamp
}
```

---

## 👥 User Roles

### Instructor

**Permissions:**
- ✅ Create/edit courses
- ✅ Manage groups
- ✅ Create assignments, quizzes, materials
- ✅ Grade submissions
- ✅ View analytics
- ✅ Send announcements

**Access:**
- Dashboard with course overview
- Classwork tab (Assignments, Quizzes, Materials)
- Groups tab
- Grades tab
- Analytics

### Student

**Permissions:**
- ✅ View enrolled courses
- ✅ Submit assignments
- ✅ Take quizzes
- ✅ View/download materials
- ✅ View grades and feedback

**Access:**
- Dashboard with course list
- Course details (Classwork, Materials, Grades)
- Notifications

---

## 📖 Features Documentation

### Assignment Workflow

1. **Instructor Creates Assignment**
   - Define title, description, due date, max points
   - Upload files or add links
   - Select target groups
   - Cloud Function `onAssignmentWritten` creates trackers for all students

2. **Student Submits Assignment**
   - Upload files or add links
   - Write submission text
   - Callable Function `submitAssignment` validates and creates submission
   - Tracker status updates to "submitted"

3. **Instructor Grades Assignment**
   - View all submissions in grade tab
   - Enter grade (0-100) and feedback
   - Click "Return" button
   - Callable Function `returnAssignmentGrades` sends emails to students
   - Tracker status updates to "graded" → "returned"

### Quiz Workflow

1. **Instructor Creates Quiz**
   - Define quiz details (time, attempts, etc.)
   - Create questions in question bank
   - Cloud Function `onQuizCreated` creates trackers + sends notifications

2. **Student Takes Quiz**
   - Click "Start Quiz"
   - Callable Function `startQuiz` creates quiz submission
   - Answer questions (auto-saved)
   - Submit quiz (manual or auto-submit on timeout)

3. **Auto-Grading**
   - Cloud Function `onQuizSubmissionCompleted` triggers on submission status = "completed"
   - Calculates score by comparing answers
   - Updates quiz_tracker with score
   - Sends email notification to student

### Material Tracking

1. **Instructor Uploads Material**
   - Upload PDF/image or add link
   - Cloud Function `onMaterialCreated` creates trackers for all students

2. **Student Views/Downloads Material**
   - Click material → opens in viewer
   - Repository updates tracker: `hasViewed = true`
   - Download button → updates tracker: `hasDownloaded = true`

3. **Instructor Views Tracking**
   - Material tracking page shows all student activity
   - Filter by status (Viewed, Downloaded, etc.)
   - Export to CSV

---

## 💻 Development

### Run App Locally

```bash
# Run on Chrome (web)
flutter run -d chrome

# Run on Windows
flutter run -d windows

# Run on Android emulator
flutter run -d emulator-5554
```

### Hot Reload / Hot Restart

- **Hot Reload**: `r` in terminal
- **Hot Restart**: `R` in terminal
- **Quit**: `q` in terminal

### Code Generation

```bash
# Generate Hive type adapters (if used)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes
flutter pub run build_runner watch
```

### Linting

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

---

## 🚀 Deployment

### Deploy Cloud Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

### Build Flutter App

#### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Android App Bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

#### Windows

```bash
flutter build windows --release
```

Output: `build/windows/runner/Release/`

#### Web

```bash
flutter build web --release
```

Output: `build/web/`

### Deploy Web to Firebase Hosting

```bash
firebase init hosting
# Select build/web as public directory

firebase deploy --only hosting
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Firebase not initialized

**Error**: `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**Solution**:
- Ensure `Firebase.initializeApp()` is called in `main.dart`
- Check `firebase_options.dart` is properly configured

#### 2. Cloud Function not triggering

**Error**: Function logs show no execution

**Solution**:
- Check Firestore collection path matches function trigger
- Verify function is deployed: `firebase functions:list`
- Check function logs: `firebase functions:log --only functionName`

#### 3. Email not sending

**Error**: `Invalid login` or `Authentication failed`

**Solution**:
- Verify Gmail App Password is correct
- Check `.env` file exists in `functions/` directory
- Ensure 2-Step Verification is enabled in Google Account

#### 4. Quiz auto-grading returns 0 score

**Error**: All quizzes graded as 0/100

**Solution**:
- Check debug logs in Cloud Function
- Verify answer comparison logic (type matching)
- Ensure `correctAnswer` index matches `answers` array

#### 5. Material tracking not updating

**Error**: Views/downloads not recorded

**Solution**:
- Check `onMaterialCreated` function created trackers
- Verify `material_trackers` collection exists
- Check repository update calls in Flutter code

#### 6. Syncfusion watermark appears

**Error**: "Generated using an evaluation copy of Syncfusion"

**Solution**:
- Register for free Community License
- Update license key in `main.dart`

---

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open Pull Request**

### Coding Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use **Clean Architecture** principles
- Write descriptive commit messages
- Add comments for complex logic
- Update documentation for new features

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Example:**

```
feat(quiz): add auto-grading via Cloud Function

- Implemented onQuizSubmissionCompleted trigger
- Calculates score by comparing student answers
- Sends email notification with grade
- Updates quiz_tracker document

Closes #123
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Authors

- **Katie-217** - [GitHub](https://github.com/Katie-217)

---

## 🙏 Acknowledgments

- Flutter Team for amazing framework
- Firebase Team for backend infrastructure
- Syncfusion for PDF viewer component
- Riverpod community for state management guidance
- All contributors and testers

---

## 📞 Support

For issues, questions, or suggestions:

- **GitHub Issues**: [Create Issue](https://github.com/Katie-217/E-learning-Management-App/issues)
- **Email**: quocminhtran24032004@gmail.com
- **Documentation**: Check `docs/` folder for detailed guides

---

## 🔮 Future Enhancements

- [ ] Real-time video conferencing
- [ ] Discussion forums
- [ ] Gamification (badges, leaderboards)
- [ ] Mobile app (iOS/Android native)
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Offline mode with sync
- [ ] Calendar integration
- [ ] Parent portal

---

**Made with ❤️ using Flutter & Firebase**
