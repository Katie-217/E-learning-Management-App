# E-Learning Management System

A comprehensive e-learning platform built with Flutter and Firebase (Auth, Firestore, Storage). The legacy Node.js backend has been deprecated and replaced by a Firebase-only architecture. See `docs/CHANGE_ARCHITECTURE.md` for rationale and details.

## 📁 Project Structure

```
Final-pro/
│
├── lib/                           # Flutter app source code
│   ├── main.dart                  # App entry point
│   ├── core/                      # Core functionality
│   │   ├── config/                # App configuration & constants
│   │   │   ├── app_constants.dart
│   │   │   ├── app_theme.dart
│   │   │   └── users-role.dart    # User role definitions
│   │   ├── services/              # Core services
│   │   │   ├── api_service.dart
│   │   │   ├── cache_service.dart
│   │   │   └── firestore_service.dart
│   │   ├── providers/             # State management
│   │   │   ├── course_provider.dart
│   │   │   └── semester_provider.dart
│   │   ├── routing/               # Navigation
│   │   │   └── app_router.dart
│   │   ├── utils/                  # Utilities
│   │   │   ├── format_utils.dart
│   │   │   ├── responsive_helper.dart
│   │   │   └── validators.dart
│   │   └── widgets/               # Core widgets
│   │       ├── course_card.dart
│   │       ├── semester_switcher.dart
│   │       └── skeleton_loader.dart
│   │
│   ├── data/                      # Data layer
│   │   └── models/                # Data models
│   │       ├── course_model.dart
│   │       ├── assignment_model.dart
│   │       └── quiz_model.dart
│   │
│   ├── features/                  # Feature-based architecture
│   │   ├── auth/                  # Authentication
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── auth_overlay_screen.dart
│   │   │   │   │   ├── login_page.dart
│   │   │   │   │   └── register_form.dart
│   │   │   │   ├── controllers/
│   │   │   │   │   └── login_controller.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── auth_form_widgets.dart
│   │   │   │       └── login_form.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── repositories/
│   │   │       ├── auth_repository.dart
│   │   │       └── google_auth_repository.dart
│   │   │
│   │   ├── student/               # Student features
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   └── student_dashboard_page.dart
│   │   │       └── widgets/
│   │   │           └── circular_progress_widget.dart
│   │   │
│   │   ├── instructor/            # Instructor features
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           └── instructor_dashboard.dart
│   │   │
│   │   ├── groups/                # Group management
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── group_page.dart
│   │   │   │   │   └── manage_group_page.dart
│   │   │   │   └── widgets/
│   │   │   │       └── group_card.dart
│   │   │   ├── providers/
│   │   │   │   └── group_provider.dart
│   │   │   └── repositories/
│   │   │       └── group_repository.dart
│   │   │
│   │   ├── assignments/           # Assignment management
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           └── assignments_page.dart
│   │   │
│   │   ├── notifications/         # Notification system
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           └── notification_page.dart
│   │   │
│   │   └── settings/              # Settings & profile
│   │       └── presentation/
│   │           └── pages/
│   │               ├── profile_page.dart
│   │               └── profile_view.dart
│   │
│   ├── firebase_options.dart      # Firebase configuration
│   └── debug_firebase.dart        # Firebase debugging
│
├── backend/                       # Legacy Node.js backend (DEPRECATED - not used)
│
├── assets/                        # Static assets
│   ├── icons/
│   │   ├── background-roler.png
│   │   └── logo-google.png
│   └── svg/
│       ├── student_icon.svg
│       └── teacher_icon.svg
│
├── docs/                          # Documentation
│   └── diagrams/
│
├── android/                       # Android configuration
├── ios/                          # iOS configuration
├── macos/                        # macOS configuration
├── windows/                      # Windows configuration
├── web/                          # Web configuration
│
├── pubspec.yaml                  # Flutter dependencies
├── pubspec.lock
└── README.md                     # This file
```

## 🛠 Technology Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Local Storage**: Hive
- **Authentication**: Firebase Auth
- **Database**: Firebase Firestore
- **UI**: Material Design 3
- **Architecture**: Feature-based architecture

### Backend
- Replaced by Firebase (Firestore, Auth, Storage). No self-hosted server required.

## ✨ Features

### 🔐 Authentication & Authorization
- Firebase Authentication
- Role-based access control (Teacher/Student)
- Secure token verification
- Google Sign-In integration

### 👨‍🏫 Instructor Features
- Course management dashboard
- Assignment creation and grading
- Student enrollment management
- Analytics and reporting
- Class management
- Group management

### 👨‍🎓 Student Features
- Interactive dashboard
- Course enrollment
- Assignment submission
- Grade viewing
- Progress tracking
- Notification system

### 🔧 Common Features
- Profile management
- Real-time notifications
- Responsive design
- Dark/Light theme support
- File upload/download
- Cross-platform support (Web, Android, iOS, Windows, macOS)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x or higher)
- Firebase project setup
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Final-pro
   ```

2. **App Setup (Firebase-only)**
   ```bash
   flutter pub get
   # Configure Firebase for your project
   flutter run
   ```

### Firebase Configuration

1. Create a Firebase project
2. Enable Authentication and Firestore
3. Download `google-services.json` for Android
4. Add Firebase configuration to your Flutter app
5. (Optional) Set up Firebase Storage rules for uploads

### Environment Variables

Create a `.env` file in the backend directory:
```
PORT=4000
FIREBASE_SERVICE_ACCOUNT=./serviceAccountKey.json
```

## 🏗 Build Instructions

### Flutter App
```bash
# Web build
flutter build web --release

# Android APK
flutter build apk --release

# Windows executable
flutter build windows --release

# macOS app
flutter build macos --release

# iOS app
flutter build ios --release
```

> Note: REST API endpoints listed previously were for the deprecated Node.js backend. Data access is now performed directly via Firebase SDK in the Flutter app (see `docs/CHANGE_ARCHITECTURE.md`).

## 🧪 Testing

### Test Accounts
- **Teacher**: teacher@example.com / password123
- **Student**: student@example.com / password123

### Manual Testing
1. Register/Login with test accounts
2. Test course creation and enrollment
3. Test assignment creation and submission
4. Test grading functionality
5. Test notification system
6. Test responsive design on different screen sizes

## 🚀 Deployment

### Frontend Deployment
- **Web**: Deploy to Firebase Hosting or any web hosting service
- **Mobile**: Upload APK to Google Play Store / App Store
- **Desktop**: Distribute executable files

### Backend Deployment
Not applicable. The app uses Firebase services directly (Firestore, Auth, Storage). Consider Firebase Hosting for web.

## 🏗 Architecture

### Frontend Architecture
- **Feature-based structure**: Each feature is self-contained
- **Clean Architecture**: Separation of concerns
- **State Management**: Riverpod for reactive state
- **Local Storage**: Hive for offline support
- **Responsive Design**: Adaptive UI for all screen sizes

### Backend Architecture
- Firebase as Backend: Firestore (real-time DB), Firebase Auth, Firebase Storage
- Access control via Firebase Security Rules

## 📱 Supported Platforms

- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 11+)
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 10.14+)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation in `/docs` folder

## 📊 Project Status

- ✅ **Core Features**: Completed
- ✅ **Authentication**: Completed
- ✅ **Dashboard**: Completed
- 🔄 **Advanced Features**: In Development
- 🔄 **Testing**: In Progress
- 🔄 **Documentation**: In Progress

---

**Made with ❤️ by the E-Learning Development Team**