import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'firebase_options.dart';

import 'presentation/widgets/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Syncfusion license to remove watermark
  SyncfusionLicense.registerLicense(
    'Ngo9BigBOggjHTQxAR8/V1JFaF1cXGFCf1FpQXxbf1x1ZFZMZVpbRXJPIiBoS35Rc0RiW3hfdXFTR2RZWEB2VEFc',
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Session check moved to AuthWrapper - Clean Architecture

  runApp(
    const ProviderScope(
      child: AuthWrapper(),
    ),
  );
}
