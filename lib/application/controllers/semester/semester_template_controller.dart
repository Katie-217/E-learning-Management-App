// ========================================
// FILE: semester_template_controller.dart
// MÔ TẢ: Controller cho phần "Khuôn Mẫu" (Read-Only)
// Clean Architecture: Application Layer
// ========================================

import '../../../data/repositories/semester/semester_template_repository.dart';
import '../../../domain/models/semester_template_model.dart';

class SemesterTemplateController {
  final SemesterTemplateRepository _repository;

  SemesterTemplateController({
    SemesterTemplateRepository? repository,
  }) : _repository = repository ?? SemesterTemplateRepository();

  // ========================================
  // HÀM: getTemplatesForDropdown()
  // MÔ TẢ: Lấy danh sách templates cho UI Dropdown "Chọn Mã HK"
  // Được gọi từ UI để hiển thị options
  // ========================================
  Future<List<SemesterTemplateModel>> getTemplatesForDropdown() async {
    try {
      return await _repository.getSemesterTemplates();
    } catch (e) {
      // Log error and return empty list or fallback
      print('Error loading templates: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getTemplateForPreview()
  // MÔ TẢ: Lấy template để preview khi user chọn trong dropdown
  // ========================================
  Future<SemesterTemplateModel?> getTemplateForPreview(String templateId) async {
    try {
      return await _repository.getTemplateById(templateId);
    } catch (e) {
      print('Error loading template $templateId: $e');
      return null;
    }
  }

  // ========================================
  // HÀM: validateTemplateExists()
  // MÔ TẢ: Kiểm tra template có tồn tại không trước khi tạo semester
  // ========================================
  Future<bool> validateTemplateExists(String templateId) async {
    try {
      final template = await _repository.getTemplateById(templateId);
      return template != null && template.isActive;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // HÀM: getTemplateDisplayInfo()
  // MÔ TẢ: Lấy thông tin hiển thị cho UI preview
  // Input: templateId + year
  // Output: Map với code, name, dates để hiển thị
  // ========================================
  Future<Map<String, dynamic>> getTemplateDisplayInfo({
    required String templateId,
    required int year,
  }) async {
    try {
      final template = await _repository.getTemplateById(templateId);
      if (template == null) {
        return {'error': 'Template không tồn tại'};
      }

      return {
        'code': template.generateSemesterCode(year),
        'name': template.generateSemesterName(year),
        'startDate': template.generateStartDate(year),
        'endDate': template.generateEndDate(year),
        'templateName': template.name,
        'description': template.description,
        'isValid': template.isValidTemplate,
      };
    } catch (e) {
      return {'error': 'Lỗi lấy thông tin template: $e'};
    }
  }

  // ========================================
  // HÀM: listenToTemplates()
  // MÔ TẢ: Stream để UI có thể listen real-time changes
  // ========================================
  Stream<List<SemesterTemplateModel>> listenToTemplates() {
    return _repository.listenToTemplates();
  }

  // ========================================
  // HÀM: setupDefaultTemplates()
  // MÔ TẢ: Khởi tạo templates mặc định (chỉ dùng lần đầu setup)
  // ========================================
  Future<void> setupDefaultTemplates() async {
    try {
      await _repository.initializeDefaultTemplates();
    } catch (e) {
      throw Exception('Lỗi setup templates: $e');
    }
  }
}