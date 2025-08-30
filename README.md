# E-learning Management App (Skeleton)

Clean architecture + feature-based Flutter skeleton for an e-learning management system.

## Tech
- Flutter (Android, Windows, macOS, Web)
- State management: Riverpod
- Routing: go_router
- HTTP: dio
- Offline DB: hive/sqflite
- Utilities: intl, csv, file_picker, image_picker
- Notifications: flutter_local_notifications, firebase_messaging
- Charts: fl_chart

## Run
```
flutter pub get
flutter run -d windows   # or -d chrome / -d macos / -d android
```

Default login for demo route:
- admin/admin → navigates to Dashboard.

## Structure
```
lib/
  core/
    routing/
    theme/
    constants/
  features/
    auth/
    dashboard/
    semester_course_group_student/
    content/
    forum_chat/
    notifications/
    analytics/
    profile/
  services/
```

## Build artifacts
- Android APK (arm64): `flutter build apk --target-platform=android-arm64`
- Windows EXE: `flutter build windows`
- macOS app: `flutter build macos`
- Web: `flutter build web`

## Team collaboration
- Use feature folders for module ownership.
- Commit at least twice per week per member.
- Track via GitHub Insights.


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
