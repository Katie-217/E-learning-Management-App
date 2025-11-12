// ========================================
// FILE: group_model.dart
// MÔ TẢ: Model nhóm trong một khóa học
// ========================================

class GroupModel {
  final String id;
  final String courseId;
  final String name;
  final String code;
  final String? description;
  final List<String> studentIds;
  final int maxMembers;
  final DateTime createdAt;
  final String createdBy; // UID của instructor
  final bool isActive;

  const GroupModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.code,
    this.description,
    required this.studentIds,
    this.maxMembers = 30,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
  });

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo GroupModel từ Map (Firebase data)
  // ========================================
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      description: map['description'],
      studentIds: List<String>.from(map['studentIds'] ?? []),
      maxMembers: map['maxMembers'] ?? 30,
      createdAt: _parseDateTime(map['createdAt']),
      createdBy: map['createdBy'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển GroupModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'name': name,
      'code': code,
      'description': description,
      'studentIds': studentIds,
      'maxMembers': maxMembers,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  GroupModel copyWith({
    String? id,
    String? courseId,
    String? name,
    String? code,
    String? description,
    List<String>? studentIds,
    int? maxMembers,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      studentIds: studentIds ?? this.studentIds,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }

  // ========================================
  // GETTER: currentMemberCount
  // MÔ TẢ: Số lượng thành viên hiện tại
  // ========================================
  int get currentMemberCount => studentIds.length;

  // ========================================
  // GETTER: isFull
  // MÔ TẢ: Kiểm tra nhóm đã đầy chưa
  // ========================================
  bool get isFull => currentMemberCount >= maxMembers;

  // ========================================
  // GETTER: availableSlots
  // MÔ TẢ: Số chỗ còn trống
  // ========================================
  int get availableSlots => maxMembers - currentMemberCount;

  // ========================================
  // GETTER: displayName
  // MÔ TẢ: Tên hiển thị của nhóm
  // ========================================
  String get displayName => '$code - $name';

  // ========================================
  // HÀM: addStudent()
  // MÔ TẢ: Thêm sinh viên vào nhóm
  // ========================================
  GroupModel addStudent(String studentId) {
    if (isFull || studentIds.contains(studentId)) {
      return this;
    }

    final updatedStudentIds = [...studentIds, studentId];
    return copyWith(studentIds: updatedStudentIds);
  }

  // ========================================
  // HÀM: removeStudent()
  // MÔ TẢ: Xóa sinh viên khỏi nhóm
  // ========================================
  GroupModel removeStudent(String studentId) {
    final updatedStudentIds =
        studentIds.where((id) => id != studentId).toList();
    return copyWith(studentIds: updatedStudentIds);
  }

  // ========================================
  // HÀM: hasStudent()
  // MÔ TẢ: Kiểm tra sinh viên có trong nhóm không
  // ========================================
  bool hasStudent(String studentId) {
    return studentIds.contains(studentId);
  }

  // ========================================
  // HÀM: _parseDateTime()
  // MÔ TẢ: Parse datetime từ string/dynamic
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
    return 'GroupModel(id: $id, code: $code, name: $name, members: $currentMemberCount/$maxMembers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
