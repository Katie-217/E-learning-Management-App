// ========================================
// FILE: student_model.dart
// MÔ TẢ: Model sinh viên - Kế thừa từ UserModel (users collection)
// UPDATED: Removed department field
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  // ========================================
  // Fields từ users collection
  // ========================================
  final String uid;
  final String email;
  final String name;
  final String displayName;
  final String? photoUrl;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final bool isDefault;
  final StudentSettings settings;

  // ========================================
  // Fields bổ sung cho Student (REMOVED department)
  // ========================================
  final String? studentCode;
  final String? phone;
  final List<String> courseIds;
  final List<String> groupIds;
  final Map<String, dynamic>? metadata;

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
    this.courseIds = const [],
    this.groupIds = const [],
    this.metadata,
  });

  // ========================================
  // HÀM: fromFirestore()
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
      createdAt: _parseDateTime(data['createdAtLocal'] ?? data['createdAt']),
      lastLoginAt: _parseDateTime(
        data['lastLoginAtLocal'] ?? data['lastLoginAt'],
      ),
      isActive: data['isActive'] ?? 
                (data['settings']?['status'] == 'active') ?? true,
      isDefault: data['isDefault'] ?? false,
      settings: StudentSettings.fromMap(data['settings'] ?? {}),
      studentCode: data['studentCode'],
      phone: data['phone'],
      courseIds: List<String>.from(data['courseIds'] ?? []),
      groupIds: List<String>.from(data['groupIds'] ?? []),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // ========================================
  // HÀM: fromMap()
  // ========================================
factory StudentModel.fromMap(Map<String, dynamic> map) {
  // ✅ FIX 1: Nếu không có dữ liệu createdAt (từ CSV), sử dụng DateTime.now()
  // Loại bỏ logic phức tạp _parseDateTime() cho createdAt khi import
  final parsedCreatedAt = _parseDateTime(map['createdAtLocal'] ?? map['createdAt']);
  
  return StudentModel(
    uid: map['uid'] ?? '',
    email: map['email'] ?? '',
    name: map['name'] ?? '',
    displayName: map['displayName'] ?? map['name'] ?? '',
    photoUrl: map['photoUrl'],
    role: map['role'] ?? 'student',
    
    // SỬA ĐỔI: Nếu không có dữ liệu hợp lệ, sử dụng DateTime.now()
    createdAt: parsedCreatedAt, 
    
    lastLoginAt: _parseDateTime(
      map['lastLoginAtLocal'] ?? map['lastLoginAt'],
    ),
    isActive: map['isActive'] ?? false, // ✅ FIX 2: Mặc định là false vì chưa có Auth
    isDefault: map['isDefault'] ?? false,
    settings: StudentSettings.fromMap(map['settings'] ?? {}).copyWith(
      status: map['settings']?['status'] ?? 'inactive', // Mặc định là 'inactive'
    ),
    // Student fields
    studentCode: map['studentCode'],
    phone: map['phone'],
    courseIds: List<String>.from(map['courseIds'] ?? []),
    groupIds: List<String>.from(map['groupIds'] ?? []),
    metadata: map['metadata'] as Map<String, dynamic>?,
  );
}

  // ========================================
  // HÀM: toFirestore()
  // ========================================
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'createdAtLocal': FieldValue.serverTimestamp(),
      'lastLoginAtLocal': lastLoginAt?.toString(),
      'settings': settings.toMap(),
      'isActive': isActive,
      'isDefault': isDefault,
      'studentCode': studentCode,
      'phone': phone,
      'courseIds': courseIds,
      'groupIds': groupIds,
      'metadata': metadata,
    };
  }

  // ========================================
  // HÀM: toMap()
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
      'courseIds': courseIds,
      'groupIds': groupIds,
      'metadata': metadata,
    };
  }

  // ========================================
  // HÀM: copyWith()
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
      courseIds: courseIds ?? this.courseIds,
      groupIds: groupIds ?? this.groupIds,
      metadata: metadata ?? this.metadata,
    );
  }

  // ========================================
  // Helper Methods
  // ========================================

  StudentModel enrollCourse(String courseId) {
    if (courseIds.contains(courseId)) return this;
    return copyWith(courseIds: [...courseIds, courseId]);
  }

  StudentModel unenrollCourse(String courseId) {
    return copyWith(
      courseIds: courseIds.where((id) => id != courseId).toList(),
    );
  }

  StudentModel joinGroup(String groupId) {
    if (groupIds.contains(groupId)) return this;
    return copyWith(groupIds: [...groupIds, groupId]);
  }

  StudentModel leaveGroup(String groupId) {
    return copyWith(
      groupIds: groupIds.where((id) => id != groupId).toList(),
    );
  }

  // ========================================
  // Getters
  // ========================================

  bool get isStudentActive => isActive && settings.status == 'active';
  String get displayNameOrName => displayName.isNotEmpty ? displayName : name;
  bool get hasStudentCode => studentCode != null && studentCode!.isNotEmpty;
  int get courseCount => courseIds.length;
  int get groupCount => groupIds.length;

  // ========================================
  // Static Helpers
  // ========================================

static DateTime _parseDateTime(dynamic dateData) {
  if (dateData == null) return DateTime.now(); // Trả về thời điểm hiện tại

  if (dateData is DateTime) return dateData;

  // Nếu là Timestamp từ Firestore (dạng Map), thì extract
  if (dateData is Map && dateData.containsKey('seconds')) {
    // Có thể là Timestamp (cần import cloud_firestore để dùng Timestamp.fromMillis)
    // Nhưng vì bạn đang parse từ Map/String, giữ nguyên logic parse String
  }

  try {
    // Nếu là string hợp lệ
    return DateTime.parse(dateData.toString());
  } catch (e) {
    // Nếu parse String thất bại, trả về thời điểm hiện tại
    print('DEBUG: ❌ Lỗi parse DateTime: $e. Sử dụng DateTime.now().');
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
// ========================================
class StudentSettings {
  final String language;
  final String theme;
  final String status;

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