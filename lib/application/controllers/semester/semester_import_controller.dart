// ========================================
// FILE: semester_import_controller.dart
// MÔ TẢ: Controller cho semester CSV import business logic - BỘ NÃO của hệ thống
// Clean Architecture: Application Layer
// ========================================

import '../../../data/repositories/semester/semester_import_repository.dart';
import '../../../domain/models/semester_model.dart';
import '../../../domain/models/semester_template_model.dart';
import '../../../domain/models/semester_import_models.dart';
import 'semester_controller.dart';
import 'semester_template_controller.dart';

class SemesterImportController {
  final SemesterController _semesterController = SemesterController();
  final SemesterTemplateController _templateController =
      SemesterTemplateController();

  // ========================================
  // HÀM: preloadReferenceData()
  // MÔ TẢ: Pre-fetch reference data for optimization
  // ========================================
  Future<Map<String, dynamic>> preloadReferenceData() async {
    try {
      print('DEBUG: 🔥 Loading reference data...');

      // Load templates (S1, S2, S3)
      final templates = await _templateController.getTemplatesForDropdown();
      final templateMap = {for (var t in templates) t.id: t};

      // Load existing semester codes AND names for duplicate check
      final existingSemesters = await _semesterController.getAllSemesters();
      final existingCodes =
          existingSemesters.map((s) => s.code.toLowerCase()).toList();
      final existingNames =
          existingSemesters.map((s) => s.name.toLowerCase().trim()).toList();

      print(
          'DEBUG: ✅ Loaded ${templates.length} templates: ${templateMap.keys.join(", ")}');
      print('DEBUG: ✅ Loaded ${existingCodes.length} existing semester codes');
      print('DEBUG: ✅ Loaded ${existingNames.length} existing semester names');

      return {
        'templates': templates,
        'templateMap': templateMap,
        'existingCodes': existingCodes,
        'existingNames': existingNames,
        'existingSemesters': existingSemesters, // Pass full semester objects
      };
    } catch (e) {
      print('DEBUG: ❌ Failed to load reference data: $e');
      throw Exception('Failed to load reference data: $e');
    }
  }

  // ========================================
  // HÀM: processAndValidateCsv()
  // MÔ TẢ: Xử lý CSV và trả về dữ liệu sẵn sàng cho UI
  // ========================================
  Future<ImportSessionData> processAndValidateCsv(
    String csvContent,
    Map<String, dynamic> referenceData,
  ) async {
    try {
      print('DEBUG: 🔥 Processing CSV content...');

      // Bước 1: Parse CSV thành raw records (gọi Repository)
      final rawRecords =
          await SemesterImportRepository.parseCsvFile(csvContent);

      // Bước 2: Validate từng record và tạo SemesterImportItem
      final templateMap =
          referenceData['templateMap'] as Map<String, SemesterTemplateModel>;
      final existingCodes =
          (referenceData['existingCodes'] as List<String>).toSet();
      final existingNames =
          (referenceData['existingNames'] as List<String>).toSet();
      final existingSemesters =
          referenceData['existingSemesters'] as List<SemesterModel>;

      final validatedItems = <SemesterImportItem>[];

      for (final rawRecord in rawRecords) {
        final validatedItem = await _validateSingleRecord(rawRecord,
            templateMap, existingCodes, existingNames, existingSemesters);
        validatedItems.add(validatedItem);

        print(
            'DEBUG: Row ${rawRecord.rowIndex}: ${rawRecord.templateId}/${rawRecord.year} -> ${validatedItem.status.name}');
      }

      // Bước 3: Tạo ImportSessionData với đầy đủ thống kê
      final sessionData = ImportSessionData.fromItems(validatedItems);

      print(
          'DEBUG: ✅ Validation complete - New: ${sessionData.summary.newCount}, Exists: ${sessionData.summary.existingCount}, Invalid: ${sessionData.summary.invalidCount}');

      return sessionData;
    } catch (e) {
      print('DEBUG: ❌ Error processing CSV: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: _validateSingleRecord()
  // MÔ TẢ: Validate single raw record và trả về SemesterImportItem
  // ========================================
  Future<SemesterImportItem> _validateSingleRecord(
    RawCsvRecord rawRecord,
    Map<String, SemesterTemplateModel> templateMap,
    Set<String> existingCodes,
    Set<String> existingNames,
    List<SemesterModel> existingSemesters,
  ) async {
    final validationErrors = <String>[];

    // 🔄 Normalize templateId: Support both "S1" and "Semester 1" formats
    String normalizedTemplateId = rawRecord.templateId.trim();
    final lowerTemplate = normalizedTemplateId.toLowerCase();

    // Create mapping for user-friendly names (Semester 1 -> S1)
    final templateNameMap = <String, String>{
      'semester 1': 'S1',
      'semester 2': 'S2',
      'semester 3': 'S3',
      'summer semester': 'S3',
    };

    // Try to map user-friendly names to template IDs
    if (templateNameMap.containsKey(lowerTemplate)) {
      normalizedTemplateId = templateNameMap[lowerTemplate]!;
      print(
          '📝 DEBUG: Normalized "${rawRecord.templateId}" → "$normalizedTemplateId"');
    }

    // 1. Template validation
    final template = templateMap[normalizedTemplateId];
    if (rawRecord.templateId.isEmpty) {
      validationErrors.add('Template ID cannot be empty');
    } else if (template == null) {
      validationErrors.add(
          'Template "${rawRecord.templateId}" not found. Available: ${templateMap.keys.join(", ")}');
    }

    // 2. Year validation
    final year = int.tryParse(rawRecord.year);
    final currentYear = DateTime.now().year;
    if (rawRecord.year.isEmpty) {
      validationErrors.add('Year cannot be empty');
    } else if (year == null) {
      validationErrors.add('Year must be a valid integer');
    } else if (year < (currentYear - 5) || year > (currentYear + 10)) {
      validationErrors.add(
          'Year must be between ${currentYear - 5} and ${currentYear + 10}');
    }

    // 3. Xác định trạng thái và tạo preview semester
    String? generatedCode;
    ImportItemStatus status = ImportItemStatus.invalid;
    SemesterModel? previewSemester;

    if (template != null && year != null && validationErrors.isEmpty) {
      generatedCode = '${normalizedTemplateId}_$year'; // S1_2025
      final finalName = rawRecord.name?.isNotEmpty == true
          ? rawRecord.name!
          : template.generateSemesterName(year);

      // Check both code and name duplicates
      final isCodeDuplicate =
          existingCodes.contains(generatedCode.toLowerCase());
      final isNameDuplicate =
          existingNames.contains(finalName.toLowerCase().trim());

      // Debug validation
      print('DEBUG: 🔍 Validating: code="$generatedCode", name="$finalName"');
      print('DEBUG: 🔍 Existing codes: $existingCodes');
      print('DEBUG: 🔍 Existing names: $existingNames');
      print(
          'DEBUG: 🔍 Code duplicate: $isCodeDuplicate, Name duplicate: $isNameDuplicate');

      if (isCodeDuplicate || isNameDuplicate) {
        status = ImportItemStatus.exists;

        // Find and attach existing semester for display
        final codeToMatch = generatedCode.toLowerCase();
        final nameToMatch = finalName.toLowerCase().trim();

        previewSemester = existingSemesters.firstWhere(
          (s) =>
              s.code.toLowerCase() == codeToMatch ||
              s.name.toLowerCase().trim() == nameToMatch,
          orElse: () => SemesterModel(
            id: '',
            code: generatedCode ?? 'UNKNOWN',
            name: finalName,
            startDate: template.generateStartDate(year),
            endDate: template.generateEndDate(year),
            description: 'Unknown',
            createdAt: DateTime.now(),
            isActive: true,
          ),
        );

        if (isCodeDuplicate && isNameDuplicate) {
          validationErrors.add(
              'Both code "$generatedCode" and name "$finalName" already exist');
        } else if (isCodeDuplicate) {
          validationErrors.add('Semester code "$generatedCode" already exists');
        } else {
          validationErrors.add('Semester name "$finalName" already exists');
        }
      } else {
        status = ImportItemStatus.willBeAdded;

        // Tạo preview semester
        previewSemester = SemesterModel(
          id: '', // Will be generated by Firestore
          code: generatedCode,
          name: finalName,
          startDate: template.generateStartDate(year),
          endDate: template.generateEndDate(year),
          description: 'Imported from CSV - Template: ${template.name}',
          createdAt: DateTime.now(),
          isActive: true,
        );
      }
    }

    return SemesterImportItem(
      rawRecord: rawRecord,
      status: status,
      validationErrors: validationErrors,
      generatedCode: generatedCode,
      previewSemester: previewSemester,
      normalizedTemplateId: normalizedTemplateId, // Save normalized ID
    );
  }

  // ========================================
  // HÀM: importSemesters()
  // MÔ TẢ: Import và trả về ImportResult hoàn chỉnh
  // ========================================
  Future<ImportResult> importSemesters(ImportSessionData sessionData) async {
    try {
      final successfulSemesters = <SemesterModel>[];
      final failedImports = <ImportFailure>[];

      final itemsToImport = sessionData.newItems;

      print(
          'DEBUG: 🔥 Starting import of ${itemsToImport.length} semesters...');

      for (int i = 0; i < itemsToImport.length; i++) {
        final item = itemsToImport[i];
        try {
          final previewSemester = item.previewSemester!;

          print(
              'DEBUG: 🔄 Importing ${i + 1}/${itemsToImport.length}: ${previewSemester.code}');

          // Sử dụng SemesterController để tạo semester
          final semesterId = await _semesterController.handleCreateSemester(
            templateId: item.normalizedTemplateId ??
                item.rawRecord.templateId, // Use normalized ID
            year: int.parse(item.rawRecord.year),
            name: previewSemester.name,
          );

          // Lấy semester vừa tạo
          final createdSemester =
              await _semesterController.getSemesterById(semesterId);
          if (createdSemester != null) {
            successfulSemesters.add(createdSemester);
            print('DEBUG: ✅ Successfully created: ${createdSemester.code}');
          }
        } catch (e) {
          print('DEBUG: ❌ Failed to import ${item.generatedCode}: $e');
          failedImports.add(ImportFailure(
            item: item,
            errorMessage: e.toString(),
          ));
        }
      }

      final successRate = itemsToImport.isEmpty
          ? 0.0
          : (successfulSemesters.length / itemsToImport.length) * 100;

      print('DEBUG: 🏁 Import completed:');
      print('   ✅ Success: ${successfulSemesters.length}');
      print('   ❌ Failed: ${failedImports.length}');
      print('   📈 Success Rate: ${successRate.toStringAsFixed(1)}%');

      return ImportResult(
        totalProcessed: itemsToImport.length,
        successCount: successfulSemesters.length,
        failureCount: failedImports.length,
        successRate: successRate,
        successfulSemesters: successfulSemesters,
        failedImports: failedImports,
      );
    } catch (e) {
      print('DEBUG: ❌ Error during import: $e');
      rethrow;
    }
  }
}
