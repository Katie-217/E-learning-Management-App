# E-Learning Management System

A comprehensive e-learning platform built with Flutter and Firebase, supporting both Instructor and Student roles with full course management, assignment submission, and grading features.

---

## 📋 Table of Contents

1. [Project Building Instructions](#project-building-instructions)
2. [Project Running Instructions](#project-running-instructions)
3. [Deployment URL](#deployment-url)
4. [Test Account Credentials](#test-account-credentials)
5. [Notes for Teachers/Evaluators](#notes-for-teachersevaluators)
6. [Optional Features](#optional-features)

---

## 🏗️ Project Building Instructions

### Prerequisites

Before building the project, ensure you have the following installed:

- **Flutter SDK** (version 3.5.0 or higher)
  - Download from: https://flutter.dev/docs/get-started/install
  - Verify installation: `flutter --version`
  
- **Node.js and npm** (for Firebase CLI)
  - Download from: https://nodejs.org/
  - Verify installation: `node --version` and `npm --version`

- **Firebase CLI** (for deployment)
  ```bash
  npm install -g firebase-tools
  ```

- **Git** (for cloning repository)
  - Download from: https://git-scm.com/downloads

### Step-by-Step Build Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Final-pro
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Build for Web (Production)**
   ```bash
   flutter build web --release --base-href /
   ```
   
   The build output will be in the `build/web` directory.

4. **Build for Android**
   ```bash
   flutter build apk --release
   ```

5. **Build for Windows**
   ```bash
   flutter build windows --release
   ```

6. **Build for macOS**
   ```bash
   flutter build macos --release
   ```

7. **Build for iOS** (macOS only)
   ```bash
   flutter build ios --release
   ```

### Using Automated Build Scripts

**Windows:**
```bash
build-only.bat
```

**Linux/Mac:**
```bash
chmod +x build-only.sh
./build-only.sh
```

---

## 🚀 Project Running Instructions

### Running Locally (Development Mode)

1. **Ensure dependencies are installed**
   ```bash
   flutter pub get
   ```

2. **Run on Web**
   ```bash
   flutter run -d chrome
   ```
   Or specify a different browser:
   ```bash
   flutter run -d edge
   flutter run -d firefox
   ```

3. **Run on Android**
   ```bash
   flutter run -d android
   ```
   (Requires Android emulator or connected device)

4. **Run on Windows**
   ```bash
   flutter run -d windows
   ```

5. **Run on macOS**
   ```bash
   flutter run -d macos
   ```

### Running Production Build Locally

After building with `flutter build web --release`:

1. Navigate to build directory:
   ```bash
   cd build/web
   ```

2. Start a local server:
   ```bash
   # Using Python
   python -m http.server 8000
   
   # Or using Node.js
   npx serve -s . -l 8000
   ```

3. Open browser and navigate to:
   ```
   http://localhost:8000
   ```

---

## 🌐 Deployment URL

The application is deployed and accessible at:

**Primary URL:**
```
https://e-learning-management-79797.web.app
```

**Alternative URL:**
```
https://e-learning-management-79797.firebaseapp.com
```

### Deployment Information

- **Hosting Service:** Firebase Hosting
- **Deployment Method:** Automated via `deploy.bat` script
- **Last Updated:** See Firebase Console for deployment history

### How to Deploy Updates

**Windows:**
```bash
deploy.bat
```

**Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

The deployment script will:
1. Clean previous builds
2. Install dependencies
3. Build the web app for production
4. Deploy to Firebase Hosting

---

## 🔐 Test Account Credentials

The following accounts have been pre-configured with real data in firebase for evaluation purposes:

### Instructor Account
- **UserName:** `admin`
- **Password:** `admin`
- **Role:** Instructor
- **Display Name:** Admin Instructor

**Features available:**
- Create and manage courses with detailed course pages
- Create assignments, quizzes, and course materials
- Manage student enrollments and student accounts
- Grade student submissions with feedback
- View analytics and reports with visual charts
- Manage groups and forums
- CSV import for bulk student/semester/course data
- Announcement management
- Calendar and semester management
- Chat and messaging with students

### Student Account
- **Email:** `student4@gmail.com`
- **Password:** `123456`
- **Role:** Student
- **Display Name:** Nguyen Van An

**Features available:**
- View enrolled courses with detailed course pages
- Submit assignments with file upload
- View grades and feedback from instructors
- Participate in course forums and discussions
- Chat with instructors and classmates
- View notifications and announcements
- Track progress and view course analytics
- View course materials and resources
---

## 📝 Notes for Teachers/Evaluators

### Initial Setup and Configuration

1. **Firebase Configuration:**
   - The project uses Firebase for backend services (Authentication, Firestore, Storage)
   - Firebase configuration is already set up in `lib/firebase_options.dart`
   - No additional server setup is required

2. **First Run:**
   - The test accounts are already configured in Firebase with real data
   - Use the provided credentials to login (see Test Account Credentials section)
   - No additional account creation needed for evaluation

3. **Data Setup:**
   - The app uses Firebase Firestore as the database
   - Test accounts already have real data pre-loaded in Firebase
   - The Instructor account has courses, assignments, and student enrollments
   - The Student account is enrolled in courses with assignments and grades
   - CSV import functionality is available for bulk data import (students, semesters, courses, groups)

### Testing the Application

1. **Login Testing:**
   - Use the provided test accounts above
   - Test both Instructor and Student roles
   - Verify role-based access control

2. **Core Features to Test:**
   - **Instructor Dashboard:** 
     - Course creation and management
     - Assignment and quiz creation
     - Material management and tracking
     - Student enrollment and management
     - Grading and feedback system
     - Analytics and reporting
     - CSV import functionality
     - Forum and group management
     - Chat with students
   - **Student Dashboard:**
     - Course enrollment and viewing
     - Assignment submission with file upload
     - Quiz taking and results viewing
     - Grade and feedback viewing
     - Course materials access
     - Forum participation
     - Chat with instructors and classmates
     - Progress tracking
   - **Authentication:** Login with username/email, logout, session management
   - **File Management:** Upload/download assignments, materials, forum attachments
   - **Notifications:** Real-time notification system for assignments, grades, announcements
   - **Forums:** Course-based discussion forums with file sharing
   - **Chat:** Real-time messaging between instructors and students

3. **Responsive Design:**
   - Test on different screen sizes (desktop, tablet, mobile)
   - The app is responsive and adapts to different viewport sizes

4. **Browser Compatibility:**
   - Tested on: Chrome, Firefox, Safari, Edge
   - Recommended: Chrome or Edge for best performance

### Known Issues and Limitations

1. **Initial Load Time:**
   - The web app may take 3-8 seconds to load initially due to Flutter web compilation
   - Subsequent loads are faster due to browser caching
   - A loading indicator is displayed during initialization

2. **Firebase Quotas:**
   - The app uses Firebase free tier
   - Some features may be rate-limited on the free tier
   - For production use, consider upgrading Firebase plan

3. **Offline Functionality:**
   - Limited offline support
   - Data syncs when connection is restored

### Troubleshooting

**If the app doesn't load:**
1. Clear browser cache (Ctrl+Shift+Delete)
2. Try hard refresh (Ctrl+Shift+R)
3. Check browser console for errors (F12)
4. Verify Firebase project is active

**If login fails:**
1. Verify Firebase Authentication is enabled
2. Check Firestore Security Rules
3. Ensure test accounts exist in Firebase

**If build fails:**
1. Run `flutter clean`
2. Run `flutter pub get`
3. Verify Flutter SDK version: `flutter --version`
4. Check for dependency conflicts

### Project Structure

```
Final-pro/
├── lib/                    # Main application code
│   ├── main.dart          # Application entry point
│   ├── core/              # Core functionality
│   ├── data/              # Data layer (repositories, models)
│   ├── domain/            # Domain models
│   ├── presentation/      # UI layer (screens, widgets)
│   └── application/       # Application logic (controllers, providers)
├── web/                   # Web-specific files
├── android/               # Android configuration
├── ios/                   # iOS configuration
├── windows/               # Windows configuration
├── macos/                 # macOS configuration
├── pubspec.yaml          # Dependencies
└── firebase.json         # Firebase configuration
```

### Technology Stack

- **Frontend:** Flutter 3.5.0+
- **State Management:** Riverpod
- **Backend:** Firebase (Firestore, Auth, Storage)
- **Architecture:** Clean Architecture with Feature-based structure
- **UI:** Material Design 3

---

## ⭐ Optional Features

The following optional features have been implemented and are available in the application:

### 1. **Real-time Notifications System**
   - Push notifications for new assignments, grades, and announcements
   - Notification center with read/unread status
   - Real-time updates using Firebase Firestore listeners
   - Notification history and management

### 2. **Advanced File Management**
   - Support for multiple file types (PDF, DOCX, images, etc.)
   - File preview functionality
   - Google Docs Viewer integration for Office documents
   - File upload progress tracking

### 3. **Forum and Discussion Groups**
   - Course-based discussion forums
   - Forum topics and threads management
   - Group messaging and chat system
   - Real-time chat between instructors and students
   - File sharing in forums and chat
   - Instructor forum group management

### 4. **Advanced Analytics and Reporting**
   - Student progress tracking
   - Grade analytics and statistics
   - Course performance metrics
   - Visual charts and graphs using fl_chart

### 5. **CSV Import/Export**
   - Bulk student enrollment via CSV
   - Semester data import via CSV
   - Course data import via CSV
   - Group data import via CSV
   - Comprehensive CSV import interface

### 6. **Responsive Design**
   - Fully responsive UI for all screen sizes
   - Mobile-first approach
   - Adaptive layouts for desktop, tablet, and mobile

### 7. **Dark/Light Theme Support**
   - Theme switching capability
   - System theme detection
   - Customizable color schemes

### 8. **Multi-platform Support**
   - Web (deployed)
   - Android (buildable)
   - iOS (buildable)
   - Windows (buildable)
   - macOS (buildable)

### 9. **Google Sign-In Integration**
   - OAuth authentication via Google
   - Seamless login experience
   - Account linking

### 10. **Advanced Assignment Features**
   - Assignment deadlines and reminders
   - Late submission handling
   - File upload with progress tracking
   - Assignment detail pages with submission tracking
   - Feedback and comments system
   - Assignment material tracking for instructors

### 11. **Course Material Management**
   - Upload and manage course materials
   - Material tracking and analytics
   - Support for multiple file types
   - Material detail pages with preview

### 12. **Quiz System**
   - Create quizzes with question bank
   - Question editor with multiple question types
   - Quiz taking interface for students
   - Quiz results and analytics
   - Quiz detail management

### 13. **Semester Management**
   - Create and manage semesters
   - Semester-based course filtering
   - Semester switcher widget
   - CSV import for semester data

### 14. **Announcement System**
   - Create and manage course announcements
   - Announcement detail pages
   - Announcement tracking
   - Real-time announcement updates

---

