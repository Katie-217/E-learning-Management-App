// ========================================
// FILE: student_model.dart
// MÔ TẢ: Model sinh viên - Kế thừa từ UserModel (users collection)
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  // ========================================
  // Fields từ users collection
  // ========================================
  final String uid;                    // Document ID (từ Firebase Auth)
  final String email;
  final String name;
  final String displayName;
  final String? photoUrl;
  final String role;                   // Luôn = "student"
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final bool isDefault;
  final StudentSettings settings;

  // ========================================
  // Fields bổ sung cho Student
  // ========================================
  final String? studentCode;           // Mã sinh viên (SV001, SV002...)
  final String? phone;
  final String? department;            // Khoa/Bộ môn
  final List<String> courseIds;        // Danh sách khóa học
  final List<String> groupIds;         // Danh sách nhóm
  final Map<String, dynamic>? metadata; // Dữ liệu bổ sung

  const StudentModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.displayName,
    this.photoUrl,
    this.role = 'student',
    required this.createdAt,
    this.lastLoginAt,
    required this.settings,
    this.isActive = true,
    this.isDefault = false,
    // Student fields
    this.studentCode,
    this.phone,
    this.department,
    this.courseIds = const [],
    this.groupIds = const [],
    this.metadata,
  });

  // ========================================
  // HÀM: fromFirestore()
  // MÔ TẢ: Chuyển Firestore Document → StudentModel
  // Sử dụng cấu trúc của user collection
  // ========================================
  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return StudentModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      displayName: data['displayName'] ?? data['name'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'student',
      // Parse timestamps
      createdAt: _parseDateTime(data['createdAtLocal'] ?? data['createdAt']),
      lastLoginAt: _parseDateTime(
        data['lastLoginAtLocal'] ?? data['lastLoginAt'],
      ),
      isActive: data['isActive'] ?? 
                (data['settings']?['status'] == 'active') ?? true,
      isDefault: data['isDefault'] ?? false,
      // Parse settings
      settings: StudentSettings.fromMap(data['settings'] ?? {}),
      // Student-specific fields
      studentCode: data['studentCode'],
      phone: data['phone'],
      department: data['department'],
      courseIds: List<String>.from(data['courseIds'] ?? []),
      groupIds: List<String>.from(data['groupIds'] ?? []),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Chuyển Map → StudentModel (Legacy support)
  // ========================================
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      displayName: map['displayName'] ?? map['name'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'student',
      createdAt: _parseDateTime(map['createdAtLocal'] ?? map['createdAt']),
      lastLoginAt: _parseDateTime(
        map['lastLoginAtLocal'] ?? map['lastLoginAt'],
      ),
      isActive: map['isActive'] ?? true,
      isDefault: map['isDefault'] ?? false,
      settings: StudentSettings.fromMap(map['settings'] ?? {}),
      studentCode: map['studentCode'],
      phone: map['phone'],
      department: map['department'],
      courseIds: List<String>.from(map['courseIds'] ?? []),
      groupIds: List<String>.from(map['groupIds'] ?? []),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  // ========================================
  // HÀM: toFirestore()
  // MÔ TẢ: Chuyển StudentModel → Map để lưu Firestore
  // ========================================
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'createdAtLocal': createdAt.toString(),
      'lastLoginAtLocal': lastLoginAt?.toString(),
      'settings': settings.toMap(),
      'isActive': isActive,
      'isDefault': isDefault,
      // Student-specific fields
      'studentCode': studentCode,
      'phone': phone,
      'department': department,
      'courseIds': courseIds,
      'groupIds': groupIds,
      'metadata': metadata,
    };
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển StudentModel → Map (Legacy)
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'createdAtLocal': createdAt.toString(),
      'lastLoginAtLocal': lastLoginAt?.toString(),
      'settings': settings.toMap(),
      'isActive': isActive,
      'isDefault': isDefault,
      'studentCode': studentCode,
      'phone': phone,
      'department': department,
      'courseIds': courseIds,
      'groupIds': groupIds,
      'metadata': metadata,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  StudentModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? displayName,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    StudentSettings? settings,
    bool? isActive,
    bool? isDefault,
    String? studentCode,
    String? phone,
    String? department,
    List<String>? courseIds,
    List<String>? groupIds,
    Map<String, dynamic>? metadata,
  }) {
    return StudentModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      studentCode: studentCode ?? this.studentCode,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      courseIds: courseIds ?? this.courseIds,
      groupIds: groupIds ?? this.groupIds,
      metadata: metadata ?? this.metadata,
    );
  }

  // ========================================
  // Helper Methods
  // ========================================

  // 📚 Thêm sinh viên vào course
  StudentModel enrollCourse(String courseId) {
    if (courseIds.contains(courseId)) return this;
    return copyWith(courseIds: [...courseIds, courseId]);
  }

  // 📚 Xóa sinh viên khỏi course
  StudentModel unenrollCourse(String courseId) {
    return copyWith(
      courseIds: courseIds.where((id) => id != courseId).toList(),
    );
  }

  // 👥 Thêm sinh viên vào group
  StudentModel joinGroup(String groupId) {
    if (groupIds.contains(groupId)) return this;
    return copyWith(groupIds: [...groupIds, groupId]);
  }

  // 👥 Xóa sinh viên khỏi group
  StudentModel leaveGroup(String groupId) {
    return copyWith(
      groupIds: groupIds.where((id) => id != groupId).toList(),
    );
  }

  // ========================================
  // Getters
  // ========================================

  /// Kiểm tra sinh viên có hoạt động không
  bool get isStudentActive => isActive && settings.status == 'active';

  /// Lấy tên hiển thị
  String get displayNameOrName => displayName.isNotEmpty ? displayName : name;

  /// Kiểm tra có mã sinh viên không
  bool get hasStudentCode => studentCode != null && studentCode!.isNotEmpty;

  /// Số khóa học đang học
  int get courseCount => courseIds.length;

  /// Số nhóm tham gia
  int get groupCount => groupIds.length;

  // ========================================
  // Static Helpers
  // ========================================

  static DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) return DateTime.now();

    if (dateData is DateTime) return dateData;

    try {
      return DateTime.parse(dateData.toString());
    } catch (e) {
      print('DEBUG: ❌ Lỗi parse DateTime: $e');
      return DateTime.now();
    }
  }

  @override
  String toString() {
    return 'StudentModel('
        'uid: $uid, '
        'name: $name, '
        'email: $email, '
        'code: $studentCode, '
        'courses: ${courseIds.length}, '
        'groups: ${groupIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

// ========================================
// CLASS: StudentSettings
// MÔ TẢ: Cài đặt của sinh viên
// ========================================
class StudentSettings {
  final String language;  // 'vi', 'en'
  final String theme;     // 'light', 'dark'
  final String status;    // 'active', 'inactive', 'banned'

  const StudentSettings({
    this.language = 'vi',
    this.theme = 'light',
    this.status = 'active',
  });

  factory StudentSettings.fromMap(Map<String, dynamic> map) {
    return StudentSettings(
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

  StudentSettings copyWith({
    String? language,
    String? theme,
    String? status,
  }) {
    return StudentSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      status: status ?? this.status,
    );
  }

  @override
  String toString() => 'Settings(lang: $language, theme: $theme, status: $status)';
}