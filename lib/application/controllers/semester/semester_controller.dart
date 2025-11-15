// ========================================
// FILE: semester_controller.dart
// MÔ TẢ: Controller cho "Học Kỳ Cụ Thể" với logic SNAPSHOT quan trọng
// Clean Architecture: Application Layer
// ========================================

import '../../../data/repositories/semester/semester_repository.dart';
import '../../../data/repositories/semester/semester_template_repository.dart';
import '../../../domain/models/semester_model.dart';

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
  // 🔥 HÀM QUAN TRỌNG NHẤT: handleCreateSemester()
  // MÔ TẢ: Thực hiện QUY TẮC NGHIỆP VỤ 4 BƯỚC BẮT BUỘC
  // ⚠️  TUYỆT ĐỐI KHÔNG được làm tắt!
  // ========================================
  Future<String> handleCreateSemester({
    required String templateId, // Từ Dropdown (ví dụ: "HK1")
    required int year, // Từ Input Năm (ví dụ: 2025)
    required String name, // Từ Input Tên (ví dụ: "Học kỳ 1 (2025-2026)")
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
      final finalCode = '${templateId}_$year'; // "HK1_2025"
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

      // Xử lý logic học kỳ vắt qua năm (ví dụ: HK2 từ tháng 1-5)
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
      final isDuplicate = existingSemesters.any((s) => s.code == finalCode);
      if (isDuplicate) {
        throw Exception('Semester với mã "$finalCode" đã tồn tại');
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

  Future<bool> validateSemesterCreation({
    required String templateId,
    required int year,
  }) async {
    try {
      // Kiểm tra template tồn tại
      final template = await _templateRepository.getTemplateById(templateId);
      if (template == null || !template.isActive) return false;

      // Kiểm tra year hợp lệ
      final currentYear = DateTime.now().year;
      if (year < currentYear - 5 || year > currentYear + 10) return false;

      // Kiểm tra không trùng mã
      final finalCode = '${templateId}_$year';
      final existingSemesters = await _semesterRepository.getAllSemesters();
      final isDuplicate = existingSemesters.any((s) => s.code == finalCode);

      return !isDuplicate;
    } catch (e) {
      return false;
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
