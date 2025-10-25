import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/services/user_session_service.dart';
import 'core/widgets/auth_wrapper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Restore user session
  await UserSessionService.checkAndRestoreSession();

  runApp(
    const ProviderScope(
      child: AuthWrapper(),
    ),
  );
}

