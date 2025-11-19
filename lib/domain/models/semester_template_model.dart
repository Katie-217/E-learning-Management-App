// ========================================
// FILE: semester_template_model.dart
// MÔ TẢ: Định nghĩa "khuôn" cho học kỳ (ví dụ: HK1, HK2)
// Clean Architecture: Template Pattern cho Semester
// ========================================

class SemesterTemplateModel {
  final String id; 
  final String name; 
  final int startMonth; // Ví dụ: 9 (cho tháng 9)
  final int startDay; // Ví dụ: 5
  final int endMonth; // Ví dụ: 12 (cho tháng 12)
  final int endDay; // Ví dụ: 30
  final String description; // Optional description
  final bool isActive; // Template có đang được sử dụng không

  const SemesterTemplateModel({
    required this.id,
    required this.name,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
    this.description = '',
    this.isActive = true,
  });

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo model từ Firebase document
  // ========================================
  factory SemesterTemplateModel.fromMap(String id, Map<String, dynamic> map) {
    return SemesterTemplateModel(
      id: id,
      name: map['name'] ?? '',
      startMonth: map['startMonth'] ?? 1,
      startDay: map['startDay'] ?? 1,
      endMonth: map['endMonth'] ?? 1,
      endDay: map['endDay'] ?? 1,
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển model thành Map để lưu Firebase
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startMonth': startMonth,
      'startDay': startDay,
      'endMonth': endMonth,
      'endDay': endDay,
      'description': description,
      'isActive': isActive,
    };
  }

  // ========================================
  // HÀM: generateSemesterCode()
  // MÔ TẢ: Tạo code cho semester cụ thể từ template + year
  // VD: "HK1" + 2025 = "HK1_2025"
  // ========================================
  String generateSemesterCode(int year) {
    return "${id}_$year";
  }

  // ========================================
  // HÀM: generateSemesterName()
  // MÔ TẢ: Tạo tên cho semester cụ thể từ template + year
  // VD: "Học kỳ 1" + 2025 = "Học kỳ 1 (Năm học 2025-2026)"
  // ========================================
  String generateSemesterName(int year) {
    return "$name (Năm học $year-${year + 1})";
  }

  // ========================================
  // HÀM: generateStartDate()
  // MÔ TẢ: Tạo DateTime bắt đầu cho semester cụ thể
  // VD: startMonth=9, startDay=5, year=2025 = DateTime(2025, 9, 5)
  // ========================================
  DateTime generateStartDate(int year) {
    return DateTime(year, startMonth, startDay);
  }

  // ========================================
  // HÀM: generateEndDate()
  // MÔ TẢ: Tạo DateTime kết thúc cho semester cụ thể
  // VD: endMonth=12, endDay=30, year=2025 = DateTime(2025, 12, 30)
  // ========================================
  DateTime generateEndDate(int year) {
    return DateTime(year, endMonth, endDay);
  }

  // ========================================
  // HÀM: copyWith()
  // MÔ TẢ: Tạo copy với một số fields thay đổi
  // ========================================
  SemesterTemplateModel copyWith({
    String? id,
    String? name,
    int? startMonth,
    int? startDay,
    int? endMonth,
    int? endDay,
    String? description,
    bool? isActive,
  }) {
    return SemesterTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startMonth: startMonth ?? this.startMonth,
      startDay: startDay ?? this.startDay,
      endMonth: endMonth ?? this.endMonth,
      endDay: endDay ?? this.endDay,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  // ========================================
  // GETTER: isValidTemplate
  // MÔ TẢ: Kiểm tra template có hợp lệ không
  // ========================================
  bool get isValidTemplate {
    // Kiểm tra month hợp lệ (1-12)
    if (startMonth < 1 || startMonth > 12 || endMonth < 1 || endMonth > 12) {
      return false;
    }

    // Kiểm tra day hợp lệ (1-31)
    if (startDay < 1 || startDay > 31 || endDay < 1 || endDay > 31) {
      return false;
    }

    // Kiểm tra logic thời gian (có thể span qua năm)
    return true;
  }

  @override
  String toString() {
    return 'SemesterTemplateModel(id: $id, name: $name, ${startMonth}/${startDay} - ${endMonth}/${endDay})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemesterTemplateModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ========================================
// PREDEFINED TEMPLATES
// MÔ TẢ: Các template mặc định cho hệ thống
// ========================================
class SemesterTemplates {
  static const SemesterTemplateModel hk1 = SemesterTemplateModel(
    id: 'S1',
    name: 'Semester 1',
    startMonth: 9,
    startDay: 5,
    endMonth: 12,
    endDay: 30,
    description: 'Semester 1 - From September to December',
  );

  static const SemesterTemplateModel hk2 = SemesterTemplateModel(
    id: 'S2',
    name: 'Semester 2',
    startMonth: 1,
    startDay: 15,
    endMonth: 5,
    endDay: 31,
    description: 'Semester 2 - From January to May',
  );

  static const SemesterTemplateModel hkHe = SemesterTemplateModel(
    id: 'S3',
    name: 'Summer Semester',
    startMonth: 6,
    startDay: 1,
    endMonth: 8,
    endDay: 31,
    description: 'Summer Semester - From June to August',
  );

  static const List<SemesterTemplateModel> allTemplates = [
    hk1,
    hk2,
    hkHe,
  ];

  // ========================================
  // HÀM: getTemplateById()
  // MÔ TẢ: Lấy template theo ID
  // ========================================
  static SemesterTemplateModel? getTemplateById(String id) {
    for (final template in allTemplates) {
      if (template.id == id) return template;
    }
    return null;
  }
}
