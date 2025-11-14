// ========================================
// FILE: user_model.dart
// MÔ TẢ: Model chính cho User (Student/Instructor)
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/users-role.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String displayName;
  final UserRole role;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserSettings settings;
  final bool isActive;
  final bool isDefault; // Cho tài khoản admin mặc định

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.displayName,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    required this.settings,
    this.isActive = true,
    this.isDefault = false,
  });

  // ========================================
  // HÀM: fromFirestore() - CLEAN ARCHITECTURE COMPLIANT
  // MÔ TẢ: Tạo UserModel từ DocumentSnapshot (Firebase Firestore)
  // ========================================
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id, // Sử dụng document ID làm uid
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      displayName: data['displayName'] ?? data['name'] ?? '',
      role: _parseUserRole(data['role']),
      photoUrl: data['photoUrl'],
      createdAt: _parseDateTime(data['createdAtLocal'] ?? data['createdAt']),
      lastLoginAt:
          _parseDateTime(data['lastLoginAtLocal'] ?? data['lastLoginAt']),
      settings: UserSettings.fromMap(data['settings'] ?? {}),
      isActive: data['isActive'] ?? (data['settings']?['status'] == 'active'),
      isDefault: data['isDefault'] ?? false,
    );
  }

  // ========================================
  // HÀM: fromMap() - LEGACY SUPPORT
  // MÔ TẢ: Tạo UserModel từ Map (Firebase data)
  // ========================================
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      displayName: map['displayName'] ?? map['name'] ?? '',
      role: _parseUserRole(map['role']),
      photoUrl: map['photoUrl'],
      createdAt: _parseDateTime(map['createdAtLocal'] ?? map['createdAt']),
      lastLoginAt:
          _parseDateTime(map['lastLoginAtLocal'] ?? map['lastLoginAt']),
      settings: UserSettings.fromMap(map['settings'] ?? {}),
      isActive: map['isActive'] ?? (map['settings']?['status'] == 'active'),
      isDefault: map['isDefault'] ?? false,
    );
  }

  // ========================================
  // HÀM: toFirestore() - CLEAN ARCHITECTURE COMPLIANT
  // MÔ TẢ: Chuyển UserModel thành Map để lưu Firestore
  // ========================================
  Map<String, dynamic> toFirestore() {
    return {
      // Không bao gồm uid vì nó là document ID
      'email': email,
      'name': name,
      'displayName': displayName,
      'role': role.name,
      'photoUrl': photoUrl,
      'createdAtLocal': createdAt.toString(),
      'lastLoginAtLocal': lastLoginAt?.toString(),
      'settings': settings.toMap(),
      'isActive': isActive,
      'isDefault': isDefault,
      'updatedAt': DateTime.now().toString(),
    };
  }

  // ========================================
  // HÀM: toMap() - LEGACY SUPPORT
  // MÔ TẢ: Chuyển UserModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'displayName': displayName,
      'role': role.name,
      'photoUrl': photoUrl,
      'createdAtLocal': createdAt.toString(),
      'lastLoginAtLocal': lastLoginAt?.toString(),
      'settings': settings.toMap(),
      'isActive': isActive,
      'isDefault': isDefault,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? displayName,
    UserRole? role,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserSettings? settings,
    bool? isActive,
    bool? isDefault,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // ========================================
  // GETTER: isInstructor
  // ========================================
  bool get isInstructor => role == UserRole.instructor;

  // ========================================
  // GETTER: isStudent
  // ========================================
  bool get isStudent => role == UserRole.student;

  // ========================================
  // HÀM: _parseUserRole()
  // MÔ TẢ: Parse role từ string thành UserRole enum
  // ========================================
  static UserRole _parseUserRole(dynamic roleData) {
    if (roleData == null) return UserRole.student;

    final roleString = roleData.toString().toLowerCase().trim();
    switch (roleString) {
      case 'instructor':
      case 'teacher':
        return UserRole.instructor;
      case 'student':
        return UserRole.student;
      default:
        return UserRole.student;
    }
  }

  // ========================================
  // HÀM: _parseDateTime()
  // MÔ TẢ: Parse datetime từ string
  // ========================================
  static DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) return DateTime.now();

    if (dateData is DateTime) return dateData;

    try {
      return DateTime.parse(dateData.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

// ========================================
// CLASS: UserSettings
// MÔ TẢ: Cài đặt user
// ========================================
class UserSettings {
  final String language;
  final String theme;
  final String status;

  const UserSettings({
    this.language = 'vi',
    this.theme = 'light',
    this.status = 'active',
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      language: map['language'] ?? 'vi',
      theme: map['theme'] ?? 'light',
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'theme': theme,
      'status': status,
    };
  }

  UserSettings copyWith({
    String? language,
    String? theme,
    String? status,
  }) {
    return UserSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      status: status ?? this.status,
    );
  }
}
