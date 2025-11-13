import 'package:flutter/material.dart';
import 'package:elearning_management_app/core/config/users-role.dart';
import 'package:elearning_management_app/presentation/screens/auth/auth_overlay_screen.dart';
import 'package:elearning_management_app/presentation/screens/splash/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-learning Management',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const AuthOverlayScreen(initialRole: UserRole.student),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
