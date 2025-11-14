// Generated-like file: Placeholder Firebase options for manual setup
// Replace the placeholder values with your actual Firebase Web app config

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return web;
    }
  }

  // Fill these with your real values or re-generate using `flutterfire configure`
  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyADyohRSDQ7XDoGnF4qLzeR4g32oLrbwbc",
      authDomain: "e-learning-management-79797.firebaseapp.com",
      projectId: "e-learning-management-79797",
      storageBucket: "e-learning-management-79797.firebasestorage.app",
      messagingSenderId: "601468166401",
      appId: "1:601468166401:web:9c3d5dab0eb2f988c7bb00",
      measurementId: "G-JQBLRCVK5K");

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADyohRSDQ7XDoGnF4qLzeR4g32oLrbwbc',
    appId: '1:601468166401:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '601468166401',
    projectId: 'e-learning-management-79797',
    storageBucket: 'e-learning-management-79797.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.app',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = web;
  static const FirebaseOptions linux = web;
}
