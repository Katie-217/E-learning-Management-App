// ========================================
// FILE: semester_model.dart
// MÔ TẢ: Model định nghĩa học kỳ cụ thể (Instance)
// ========================================

import 'semester_template_model.dart';

class SemesterModel {
  final String id;
  final String code;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final String? description;

  const SemesterModel({
    required this.id,
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
    this.description,
  });

  // ========================================
  // HÀM: fromTemplate()
  // MÔ TẢ: Tạo SemesterModel từ SemesterTemplateModel + year
  // VD: Template "HK1" + year 2025 = "HK1_2025"
  // ========================================
  factory SemesterModel.fromTemplate({
    required SemesterTemplateModel template,
    required int year,
    String? customDescription,
  }) {
    return SemesterModel(
      id: template.generateSemesterCode(year), // Will be used as document ID
      code: template.generateSemesterCode(year), // "HK1_2025"
      name:
          template.generateSemesterName(year), // "Học kỳ 1 (Năm học 2025-2026)"
      startDate: template.generateStartDate(year), // DateTime(2025, 9, 5)
      endDate: template.generateEndDate(year), // DateTime(2025, 12, 30)
      isActive: true,
      createdAt: DateTime.now(),
      description: customDescription ?? template.description,
    );
  }

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo SemesterModel từ Map (Firebase data)
  // ========================================
  factory SemesterModel.fromMap(Map<String, dynamic> map) {
    return SemesterModel(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
      isActive: map['isActive'] ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      description: map['description'],
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển SemesterModel thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo bản sao với một số field thay đổi
  // ========================================
  SemesterModel copyWith({
    String? id,
    String? code,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    String? description,
  }) {
    return SemesterModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }

  // ========================================
  // GETTER: displayName
  // MÔ TẢ: Tên hiển thị đầy đủ của học kỳ
  // ========================================
  String get displayName => '$code - $name';

  // ========================================
  // GETTER: isCurrentSemester
  // MÔ TẢ: Kiểm tra xem có phải học kỳ hiện tại không
  // ========================================
  bool get isCurrentSemester {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && isActive;
  }

  // ========================================
  // GETTER: templateId
  // MÔ TẢ: Lấy template ID từ code (VD: "HK1_2025" -> "HK1")
  // ========================================
  String get templateId {
    final parts = code.split('_');
    return parts.isNotEmpty ? parts[0] : '';
  }

  // ========================================
  // GETTER: year
  // MÔ TẢ: Lấy năm từ code (VD: "HK1_2025" -> 2025)
  // ========================================
  int get year {
    final parts = code.split('_');
    if (parts.length > 1) {
      return int.tryParse(parts[1]) ?? DateTime.now().year;
    }
    return DateTime.now().year;
  }

  // ========================================
  // HÀM: getRelatedTemplate()
  // MÔ TẢ: Lấy template tương ứng với semester này
  // ========================================
  SemesterTemplateModel? getRelatedTemplate() {
    return SemesterTemplates.getTemplateById(templateId);
  }

  // ========================================
  // GETTER: duration
  // MÔ TẢ: Thời lượng học kỳ tính bằng ngày
  // ========================================
  int get duration => endDate.difference(startDate).inDays;

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
    return 'SemesterModel(id: $id, code: $code, name: $name, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemesterModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// CLASS: SemesterStatus
// MÔ TẢ: Enum trạng thái học kỳ
// ========================================
enum SemesterStatus {
  upcoming, // Sắp tới
  current, // Hiện tại
  completed, // Đã hoàn thành
}

extension SemesterStatusExtension on SemesterStatus {
  String get displayName {
    switch (this) {
      case SemesterStatus.upcoming:
        return 'Sắp tới';
      case SemesterStatus.current:
        return 'Hiện tại';
      case SemesterStatus.completed:
        return 'Đã hoàn thành';
    }
  }

  String get name {
    switch (this) {
      case SemesterStatus.upcoming:
        return 'upcoming';
      case SemesterStatus.current:
        return 'current';
      case SemesterStatus.completed:
        return 'completed';
    }
  }
}
