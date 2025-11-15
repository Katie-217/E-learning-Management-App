import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:elearning_management_app/core/services/local_storage.dart';

class AuthSession {
  final String role;
  final DateTime expiresAt;

  AuthSession({required this.role, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'role': role,
        'expiresAt': expiresAt.toIso8601String(),
      };

  static AuthSession? fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return null;
    final role = json['role'] as String?;
    final expiresAtStr = json['expiresAt'] as String?;
    if (role == null || expiresAtStr == null) return null;
    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return null;
    return AuthSession(role: role, expiresAt: expiresAt);
  }
}

class AuthSessionManager {
  static const _sessionDuration = Duration(days: 7);
  static const _hiveBoxName = 'auth_session_box';
  static const _hiveSessionKey = 'session';

  static const _prefsLoggedInKey = 'auth_logged_in';
  static const _prefsRoleKey = 'auth_role';
  static const _prefsExpiryKey = 'auth_expiry';

  static Box<Map<dynamic, dynamic>>? _sessionBox;

  static Future<void> initialize() async {
    await LocalStorage.init();
    _sessionBox = await LocalStorage.openBox<Map<dynamic, dynamic>>(_hiveBoxName);
  }

  static Future<void> saveSession({required String role}) async {
    final expiresAt = DateTime.now().add(_sessionDuration);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsLoggedInKey, true);
    await prefs.setString(_prefsRoleKey, role);
    await prefs.setString(_prefsExpiryKey, expiresAt.toIso8601String());

    await _sessionBox?.put(
      _hiveSessionKey,
      {
        'role': role,
        'expiresAt': expiresAt.toIso8601String(),
      },
    );
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsLoggedInKey);
    await prefs.remove(_prefsRoleKey);
    await prefs.remove(_prefsExpiryKey);

    await _sessionBox?.delete(_hiveSessionKey);
  }

  static Future<AuthSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_prefsLoggedInKey) ?? false;
    if (isLoggedIn) {
      final role = prefs.getString(_prefsRoleKey);
      final expiryStr = prefs.getString(_prefsExpiryKey);
      if (role != null && expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null) {
          final session = AuthSession(role: role, expiresAt: expiry);
          if (!session.isExpired) {
            return session;
          }
        }
      }
    }

    final stored = _sessionBox?.get(_hiveSessionKey);
    final session = AuthSession.fromJson(stored);
    if (session == null) return null;
    if (session.isExpired) {
      await clearSession();
      return null;
    }
    return session;
  }

  static Future<String?> getStoredRole() async {
    final session = await restoreSession();
    return session?.role;
  }
}


