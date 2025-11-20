// ========================================
// FILE: semester_controller.dart
// MÔ TẢ: Controller cho "Học Kỳ Cụ Thể" với logic SNAPSHOT quan trọng
// Clean Architecture: Application Layer
// ========================================

import '../../../data/repositories/semester/semester_repository.dart';
import '../../../data/repositories/semester/semester_template_repository.dart';
import '../../../domain/models/semester_model.dart';
import '../../../domain/models/validation_result.dart';

class SemesterController {
  final SemesterRepository _semesterRepository;
  final SemesterTemplateRepository _templateRepository;

  SemesterController({
    SemesterRepository? semesterRepository,
    SemesterTemplateRepository? templateRepository,
  })  : _semesterRepository = semesterRepository ?? SemesterRepository(),
        _templateRepository =
            templateRepository ?? SemesterTemplateRepository();

  // ========================================
  // VALIDATION METHODS
  // ========================================

  /// Validates semester creation input
  Future<ValidationResult> validateSemesterCreation({
    String? templateId,
    String? yearText,
    String? name,
  }) async {
    String? templateError;
    String? yearError;
    String? nameError;
    bool isValid = true;

    // Validate template selection
    if (templateId == null || templateId.isEmpty) {
      templateError = 'Please select a semester template';
      isValid = false;
    } else {
      // Check if template exists and is active
      try {
        final template = await _templateRepository.getTemplateById(templateId);
        if (template == null) {
          templateError = 'Selected template does not exist';
          isValid = false;
        } else if (!template.isActive) {
          templateError = 'Selected template is not active';
          isValid = false;
        }
      } catch (e) {
        templateError = 'Error validating template: $e';
        isValid = false;
      }
    }

    // Validate year
    if (yearText == null || yearText.isEmpty) {
      yearError = 'Year is required';
      isValid = false;
    } else {
      try {
        final year = int.parse(yearText);
        final currentYear = DateTime.now().year;
        if (year < currentYear - 5 || year > currentYear + 10) {
          yearError =
              'Year must be between ${currentYear - 5} and ${currentYear + 10}';
          isValid = false;
        }
      } catch (e) {
        yearError = 'Please enter a valid year';
        isValid = false;
      }
    }

    // Validate display name
    if (name == null || name.trim().isEmpty) {
      nameError = 'Display name is required';
      isValid = false;
    } else {
      // Check for duplicate name
      try {
        final existingSemesters = await _semesterRepository.getAllSemesters();
        final trimmedName = name.trim();

        final isDuplicate = existingSemesters.any((semester) =>
            semester.name.toLowerCase() == trimmedName.toLowerCase());

        if (isDuplicate) {
          nameError = 'A semester with this name already exists';
          isValid = false;
        }
      } catch (e) {
        // If we can't check for duplicates, log warning but don't fail validation
        print('Warning: Could not check for duplicate semester names: $e');
      }
    }

    return ValidationResult.semester(
      isValid: isValid,
      templateError: templateError,
      yearError: yearError,
      nameError: nameError,
    );
  }

  // ========================================
  // 🔥 HÀM QUAN TRỌNG NHẤT: handleCreateSemester()
  // MÔ TẢ: Thực hiện QUY TẮC NGHIỆP VỤ 4 BƯỚC BẮT BUỘC
  // ⚠️  TUYỆT ĐỐI KHÔNG được làm tắt!
  // ========================================
  Future<String> handleCreateSemester({
    required String templateId, // Từ Dropdown (ví dụ: "S1")
    required int year, // Từ Input Năm (ví dụ: 2025)
    required String name,
  }) async {
    try {
      // ========================================
      // BƯỚC 1: Nhận Input từ UI
      // ========================================
      print(
          '🔥 BƯỚC 1: Nhận input - templateId: $templateId, year: $year, name: $name');

      // ========================================
      // BƯỚC 2: Xử lý và Tra cứu (Bước A + B)
      // ========================================

      // Bước A: Tạo finalCode
      final finalCode = '${templateId}_$year'; // "S1_2025"
      print('🔥 BƯỚC 2A: finalCode = $finalCode');

      // Bước B: Tra cứu Khuôn
      final template = await _templateRepository.getTemplateById(templateId);
      if (template == null) {
        throw Exception('Template "$templateId" không tồn tại');
      }
      if (!template.isActive) {
        throw Exception('Template "$templateId" đã bị vô hiệu hóa');
      }
      print('🔥 BƯỚC 2B: Đã lấy được template ${template.name}');

      // ========================================
      // BƯỚC 3: Tính toán Ngày (Bước C)
      // ========================================

      // Tính toán ngày tháng tuyệt đối từ template + year
      DateTime finalStartDate;
      DateTime finalEndDate;

      // Xử lý logic học kỳ vắt qua năm (ví dụ: S2 từ tháng 1-5)
      if (template.startMonth <= template.endMonth) {
        // Học kỳ bình thường trong cùng 1 năm
        finalStartDate = DateTime(year, template.startMonth, template.startDay);
        finalEndDate = DateTime(year, template.endMonth, template.endDay);
      } else {
        // Học kỳ vắt qua năm (startMonth > endMonth)
        finalStartDate = DateTime(year, template.startMonth, template.startDay);
        finalEndDate = DateTime(year + 1, template.endMonth, template.endDay);
      }

      print(
          '🔥 BƯỚC 3: finalStartDate = $finalStartDate, finalEndDate = $finalEndDate');

      // ========================================
      // BƯỚC 4: Lưu "Snapshot" (Bước D)
      // ========================================

      // Kiểm tra trùng lặp trước khi tạo
      final existingSemesters = await _semesterRepository.getAllSemesters();
      final existingSemester =
          existingSemesters.where((s) => s.code == finalCode).firstOrNull;
      if (existingSemester != null) {
        // Return human-readable error with existing semester's display name
        throw Exception(
            'Semester already exists with name: "${existingSemester.name}"');
      }

      // Tạo đối tượng SemesterModel với TOÀN BỘ dữ liệu đã xử lý
      final newSemester = SemesterModel(
        id: '', // Firestore sẽ tự tạo ID
        code: finalCode, // "HK1_2025"
        name: name, // "Học kỳ 1 (2025-2026)"
        startDate: finalStartDate, // DateTime(2025, 9, 5)
        endDate: finalEndDate, // DateTime(2025, 12, 30)
        description: 'Được tạo từ template ${template.name}',
        createdAt: DateTime.now(),
        isActive: true,
      );

      print('🔥 BƯỚC 4: Tạo SemesterModel hoàn chỉnh');
      print('   - Code: ${newSemester.code}');
      print('   - Start: ${newSemester.startDate}');
      print('   - End: ${newSemester.endDate}');

      // Lưu vào collection "semesters"
      final semesterId = await _semesterRepository.createSemester(newSemester);

      print('🔥 ✅ HOÀN THÀNH: Đã lưu semester với ID: $semesterId');
      return semesterId;
    } catch (e) {
      print('🔥 ❌ LỖI: $e');
      throw Exception('Lỗi tạo semester: $e');
    }
  }

  // ========================================
  // CRUD CƠ BẢN
  // ========================================

  Future<List<SemesterModel>> getAllSemesters() async {
    return await _semesterRepository.getAllSemesters();
  }

  Future<SemesterModel?> getSemesterById(String semesterId) async {
    return await _semesterRepository.getSemesterById(semesterId);
  }

  Future<List<SemesterModel>> getSemestersByYear(int year) async {
    return await _semesterRepository.getSemestersByYear(year);
  }

  Future<SemesterModel?> getCurrentActiveSemester() async {
    return await _semesterRepository.getCurrentActiveSemester();
  }

  Future<void> updateSemester(SemesterModel semester) async {
    await _semesterRepository.updateSemester(semester);
  }

  Future<void> deactivateSemester(String semesterId) async {
    await _semesterRepository.deactivateSemester(semesterId);
  }

  Future<void> deleteSemester(String semesterId) async {
    await _semesterRepository.deleteSemester(semesterId);
  }

  // ========================================
  // VALIDATION & BUSINESS LOGIC
  // ========================================

  /// Updates an existing semester
  Future<void> handleUpdateSemester({
    required String semesterId,
    required String templateId,
    required int year,
    required String name,
  }) async {
    try {
      print('🔥 UPDATE SEMESTER: Starting update for $semesterId');

      // Get template for date calculation
      final template = await _templateRepository.getTemplateById(templateId);
      if (template == null) {
        throw Exception('Template "$templateId" không tồn tại');
      }
      if (!template.isActive) {
        throw Exception('Template "$templateId" đã bị vô hiệu hóa');
      }

      // Calculate dates
      DateTime finalStartDate;
      DateTime finalEndDate;

      if (template.startMonth <= template.endMonth) {
        finalStartDate = DateTime(year, template.startMonth, template.startDay);
        finalEndDate = DateTime(year, template.endMonth, template.endDay);
      } else {
        finalStartDate = DateTime(year, template.startMonth, template.startDay);
        finalEndDate = DateTime(year + 1, template.endMonth, template.endDay);
      }

      // Update semester
      final updatedSemester = SemesterModel(
        id: semesterId,
        code: '${templateId}_$year',
        name: name.trim(),
        startDate: finalStartDate,
        endDate: finalEndDate,
        isActive: true,
        createdAt: DateTime.now(), // Will be ignored in update
      );

      await _semesterRepository.updateSemester(updatedSemester);
      print('✅ UPDATE SEMESTER: Successfully updated $semesterId');
    } catch (error) {
      print('❌ UPDATE SEMESTER ERROR: $error');
      rethrow;
    }
  }

  /// Deletes a semester
  Future<void> handleDeleteSemester(String semesterId) async {
    try {
      print('🔥 DELETE SEMESTER: Starting delete for $semesterId');
      await _semesterRepository.deleteSemester(semesterId);
      print('✅ DELETE SEMESTER: Successfully deleted $semesterId');
    } catch (error) {
      print('❌ DELETE SEMESTER ERROR: $error');
      rethrow;
    }
  }

  Future<Map<String, int>> getSemesterStatistics(String semesterId) async {
    return await _semesterRepository.getSemesterStatistics(semesterId);
  }

  Future<List<SemesterModel>> searchSemesters(String query) async {
    return await _semesterRepository.searchSemesters(query);
  }

  Stream<List<SemesterModel>> listenToSemesters() {
    return _semesterRepository.listenToSemesters();
  }
}
