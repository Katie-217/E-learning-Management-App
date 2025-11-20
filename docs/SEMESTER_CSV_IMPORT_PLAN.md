# 🎯 Semester CSV Import Implementation Plan

## 📌 Executive Summary
Dựa trên analysis của Student CSV Import workflow, đây là kế hoạch đơn giản để implement Semester CSV Import sử dụng existing models và architecture.

---

## 🗂️ Required CSV Format cho Semester

### **CSV Structure:**
```csv
templateId,year,name
S1,2025,Semester 1 (2025-2026)
S2,2025,Semester 2 (2025-2026)  
S3,2025,Summer Semester (2025)
S1,2026,Semester 1 (2026-2027)
```

### **Field Specifications:**
- **templateId** (Required): Must exist in system (S1, S2, S3)
- **year** (Required): Integer > 2000, reasonable range (currentYear-5 to currentYear+10)
- **name** (Optional): Custom name, auto-generated from template if empty

---

## 🏗️ Simplified Architecture Design

### **File Structure:**
```
lib/
├── application/controllers/semester/
│   └── semester_import_controller.dart           # New - Business logic
├── data/repositories/semester/
│   └── semester_import_repository.dart           # New - CSV parsing & validation
└── presentation/screens/instructor/csv_import/
    └── csv_import_semester.dart                  # New - UI only
```

### **No New Models Required - Use Existing:**
- **SemesterModel**: Already exists, perfect for our needs
- **SemesterTemplateModel**: Already exists with S1, S2, S3 templates
- **CsvValidationResult**: Reuse from student import (simple class)

---

## 🔄 Detailed Implementation Plan

### **🔸 A. Tầng Data (Repositories)**

#### **File: `lib/data/repositories/semester/semester_import_repository.dart`**
```dart
class SemesterImportRepository {
  // Parse CSV file và basic validation
  static Future<List<Map<String, dynamic>>> parseCsvFile(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.isEmpty) throw Exception('CSV file is empty');
    
    final headers = rows.first.cast<String>().map((h) => h.trim()).toList();
    
    // Validate required columns
    final requiredColumns = ['templateId', 'year'];
    final missingColumns = requiredColumns.where((col) => !headers.contains(col)).toList();
    if (missingColumns.isNotEmpty) {
      throw Exception('Missing required columns: ${missingColumns.join(", ")}. Required: ${requiredColumns.join(", ")}');
    }
    
    final records = <Map<String, dynamic>>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
        continue; // Skip empty rows
      }
      
      final record = <String, dynamic>{'rowIndex': i};
      for (int j = 0; j < headers.length; j++) {
        final header = headers[j];
        final value = j < row.length ? row[j]?.toString().trim() ?? '' : '';
        record[header] = value;
      }
      records.add(record);
    }
    
    return records;
  }
}
```

---

### **🔸 B. Tầng Application (Controllers)**

#### **File: `lib/application/controllers/semester/semester_import_controller.dart`**
```dart
class SemesterImportController {
  final SemesterController _semesterController = SemesterController();
  final SemesterTemplateController _templateController = SemesterTemplateController();

  // Step 1: Pre-fetch reference data for optimization
  Future<Map<String, dynamic>> preloadReferenceData() async {
    try {
      // Load templates (S1, S2, S3)
      final templates = await _templateController.getTemplatesForDropdown();
      final templateMap = {for (var t in templates) t.id: t};
      
      // Load existing semester codes for duplicate check
      final existingSemesters = await _semesterController.getAllSemesters();
      final existingCodes = existingSemesters.map((s) => s.code.toLowerCase()).toList();
      
      return {
        'templates': templates,
        'templateMap': templateMap,
        'existingCodes': existingCodes,
      };
    } catch (e) {
      throw Exception('Failed to load reference data: $e');
    }
  }

  // Step 2: Validate and classify CSV records
  Future<List<Map<String, dynamic>>> validateCsvRecords(
    List<Map<String, dynamic>> csvRecords,
    Map<String, dynamic> referenceData,
  ) async {
    final templateMap = referenceData['templateMap'] as Map<String, SemesterTemplateModel>;
    final existingCodes = (referenceData['existingCodes'] as List<String>).toSet();
    
    final processedRecords = <Map<String, dynamic>>[];
    
    for (final record in csvRecords) {
      final result = await _validateSingleRecord(record, templateMap, existingCodes);
      processedRecords.add(result);
    }
    
    return processedRecords;
  }

  Future<Map<String, dynamic>> _validateSingleRecord(
    Map<String, dynamic> record,
    Map<String, SemesterTemplateModel> templateMap,
    Set<String> existingCodes,
  ) async {
    final validationErrors = <String>[];
    
    // 1. Template validation
    final templateId = record['templateId']?.toString().trim() ?? '';
    final template = templateMap[templateId];
    if (templateId.isEmpty) {
      validationErrors.add('Template ID cannot be empty');
    } else if (template == null) {
      validationErrors.add('Template "$templateId" not found. Available: ${templateMap.keys.join(", ")}');
    }
    
    // 2. Year validation
    final yearStr = record['year']?.toString().trim() ?? '';
    final year = int.tryParse(yearStr);
    final currentYear = DateTime.now().year;
    if (yearStr.isEmpty) {
      validationErrors.add('Year cannot be empty');
    } else if (year == null) {
      validationErrors.add('Year must be a valid integer');
    } else if (year < (currentYear - 5) || year > (currentYear + 10)) {
      validationErrors.add('Year must be between ${currentYear - 5} and ${currentYear + 10}');
    }
    
    // 3. Generate code and check duplicate
    String? generatedCode;
    String status = 'invalid';
    SemesterModel? previewSemester;
    
    if (template != null && year != null && validationErrors.isEmpty) {
      generatedCode = '${templateId}_$year'; // S1_2025
      final isDuplicate = existingCodes.contains(generatedCode.toLowerCase());
      
      if (isDuplicate) {
        status = 'exists';
      } else {
        status = 'willBeAdded';
        
        // Create preview semester using existing SemesterModel
        final customName = record['name']?.toString().trim();
        final finalName = customName?.isNotEmpty == true 
          ? customName! 
          : template.generateSemesterName(year);
          
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
    
    return {
      ...record,
      'validationErrors': validationErrors,
      'isValid': validationErrors.isEmpty && status == 'willBeAdded',
      'status': status, // 'willBeAdded', 'exists', 'invalid'
      'generatedCode': generatedCode,
      'previewSemester': previewSemester,
    };
  }

  // Step 3: Import valid semesters
  Future<Map<String, dynamic>> importSemesters(List<Map<String, dynamic>> validRecords) async {
    final successfulSemesters = <SemesterModel>[];
    final failedRecords = <Map<String, dynamic>>[];
    
    final recordsToImport = validRecords.where((r) => r['status'] == 'willBeAdded').toList();
    
    for (final record in recordsToImport) {
      try {
        final previewSemester = record['previewSemester'] as SemesterModel;
        
        // Use existing SemesterController business logic
        final semesterId = await _semesterController.handleCreateSemester(
          templateId: previewSemester.templateId,
          year: previewSemester.year,
          name: previewSemester.name,
        );
        
        // Retrieve created semester
        final createdSemester = await _semesterController.getSemesterById(semesterId);
        if (createdSemester != null) {
          successfulSemesters.add(createdSemester);
        }
      } catch (e) {
        failedRecords.add({
          'record': record,
          'error': e.toString(),
        });
      }
    }
    
    return {
      'totalProcessed': recordsToImport.length,
      'successCount': successfulSemesters.length,
      'failureCount': failedRecords.length,
      'successfulSemesters': successfulSemesters,
      'failedRecords': failedRecords,
      'successRate': recordsToImport.isEmpty ? 0.0 : (successfulSemesters.length / recordsToImport.length) * 100,
    };
  }
}
```

---

### **🔸 C. Tầng Presentation (UI)**

#### **File: `lib/presentation/screens/instructor/csv_import/csv_import_semester.dart`**

**Following exactly the same 4-step pattern as Student Import:**

#### **Step 1: Upload CSV File**
```dart
class CsvImportSemesterScreen extends StatefulWidget {
  final VoidCallback? onImportComplete;
  final VoidCallback? onCancel;
  
  const CsvImportSemesterScreen({super.key, this.onImportComplete, this.onCancel});
  
  @override
  State<CsvImportSemesterScreen> createState() => _CsvImportSemesterScreenState();
}

class _CsvImportSemesterScreenState extends State<CsvImportSemesterScreen> {
  final SemesterImportController _importController = SemesterImportController();
  
  // UI State Management (same pattern as Student Import)
  int _currentStep = 1;
  String? _selectedFileName;
  String? _fileContent;
  Map<String, dynamic>? _referenceData;
  List<Map<String, dynamic>>? _processedRecords;
  Map<String, dynamic>? _importResult;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _preloadData();
  }
  
  Future<void> _preloadData() async {
    try {
      _referenceData = await _importController.preloadReferenceData();
      setState(() {});
    } catch (e) {
      _showError('Failed to load system data: $e');
    }
  }

  Widget _buildStep1Upload() {
    final templates = _referenceData?['templates'] as List<SemesterTemplateModel>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(1, 'Upload Semester CSV File'),
        const SizedBox(height: 16),
        
        // CSV Format Guide
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[900]?.withOpacity(0.2),
            border: Border.all(color: Colors.blue[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📋 Semester CSV Format Guide:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                '✓ Required columns:\n'
                ' • templateId (${templates.map((t) => t.id).join(', ')})\n'
                ' • year (example: 2025)\n\n'
                '✓ Optional columns:\n'
                ' • name (custom name, auto-generated if empty)\n\n'
                '✓ Available Templates:\n'
                '${templates.map((t) => ' • ${t.id}: ${t.name}').join('\n')}\n\n'
                '✓ Example CSV:\n'
                'templateId,year,name\n'
                'S1,2025,Semester 1 (2025-2026)\n'
                'S2,2025,Semester 2 (2025-2026)\n'
                'S3,2025,Summer Semester (2025)',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // File Selection (reuse same pattern as Student Import)
        // ...
      ],
    );
  }
```

#### **Step 2: Preview and Validate**
```dart
Widget _buildStep2Preview() {
  final newRecords = _processedRecords!.where((r) => r['status'] == 'willBeAdded').toList();
  final existingRecords = _processedRecords!.where((r) => r['status'] == 'exists').toList();
  final invalidRecords = _processedRecords!.where((r) => r['status'] == 'invalid').toList();
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildStepHeader(2, 'Preview and Validate Semesters'),
      const SizedBox(height: 16),
      
      // Statistics Row
      Row(
        children: [
          Expanded(child: _buildStatBox(
            title: 'New Semesters',
            count: newRecords.length,
            color: Colors.green,
            icon: Icons.add_circle,
          )),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(
            title: 'Already Exists',
            count: existingRecords.length,
            color: Colors.orange,
            icon: Icons.warning,
          )),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(
            title: 'Invalid Data',
            count: invalidRecords.length,
            color: Colors.red,
            icon: Icons.error,
          )),
        ],
      ),
      
      const SizedBox(height: 20),
      
      // Invalid Records Detail
      if (invalidRecords.isNotEmpty) ...[
        const Text('❌ Invalid data (cannot import):', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          decoration: BoxDecoration(
            color: Colors.red[900]?.withOpacity(0.2),
            border: Border.all(color: Colors.red[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: invalidRecords.length,
            itemBuilder: (context, index) {
              final record = invalidRecords[index];
              final errors = (record['validationErrors'] as List<String>).join(', ');
              return ListTile(
                dense: true,
                leading: const Icon(Icons.error, color: Colors.red, size: 16),
                title: Text('Row ${record['rowIndex']}: ${record['templateId']}_${record['year']}',
                  style: const TextStyle(fontSize: 12, color: Colors.white)),
                subtitle: Text(errors, style: const TextStyle(fontSize: 10, color: Colors.red)),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
      
      // Existing Records Detail
      if (existingRecords.isNotEmpty) ...[
        const Text('⚠️ Already exists (will be skipped):', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 120),
          decoration: BoxDecoration(
            color: Colors.orange[900]?.withOpacity(0.2),
            border: Border.all(color: Colors.orange[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: existingRecords.length,
            itemBuilder: (context, index) {
              final record = existingRecords[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.warning, color: Colors.orange, size: 16),
                title: Text('${record['generatedCode']}', 
                  style: const TextStyle(fontSize: 12, color: Colors.white)),
                subtitle: Text('Already exists in system', 
                  style: const TextStyle(fontSize: 10, color: Colors.orange)),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
      
      // New Records Preview
      const Text('✅ New semesters to be created:', 
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
      const SizedBox(height: 8),
      Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.green[900]?.withOpacity(0.2),
          border: Border.all(color: Colors.green[700]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: newRecords.take(5).length,
          itemBuilder: (context, index) {
            final record = newRecords[index];
            final semester = record['previewSemester'] as SemesterModel;
            final duration = semester.endDate.difference(semester.startDate).inDays;
            
            return ExpansionTile(
              dense: true,
              leading: const Icon(Icons.school, color: Colors.green, size: 16),
              title: Text('${semester.code}: ${semester.name}', 
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Duration: $duration days', 
                style: const TextStyle(fontSize: 10, color: Colors.green)),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📅 Start: ${DateFormat('dd/MM/yyyy').format(semester.startDate)}', 
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('📅 End: ${DateFormat('dd/MM/yyyy').format(semester.endDate)}', 
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      if (semester.description?.isNotEmpty == true)
                        Text('📝 ${semester.description}', 
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      
      if (newRecords.length > 5)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('... and ${newRecords.length - 5} more semesters', 
            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ),
    ],
  );
}
```

#### **Step 3: Confirm Import**
```dart
Widget _buildStep3Confirm() {
  final newRecords = _processedRecords!.where((r) => r['status'] == 'willBeAdded').toList();
  final totalDuration = newRecords
    .map((r) => (r['previewSemester'] as SemesterModel).endDate.difference((r['previewSemester'] as SemesterModel).startDate).inDays)
    .fold(0, (sum, days) => sum + days);
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildStepHeader(3, 'Confirm Semester Import'),
      const SizedBox(height: 16),
      
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[900]?.withOpacity(0.2),
          border: Border.all(color: Colors.blue[700]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Import Summary:', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            const SizedBox(height: 12),
            
            _buildConfirmRow('New semesters to create:', newRecords.length, Colors.green),
            const SizedBox(height: 6),
            _buildConfirmRow('Total academic days:', totalDuration, Colors.blue),
            const SizedBox(height: 6),
            _buildConfirmRow('Year range:', _getYearRange(newRecords), Colors.purple),
            
            const SizedBox(height: 16),
            const Text('⚠️ Important Notes:', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
            const SizedBox(height: 8),
            const Text(
              '• Created semesters will be active immediately\n'
              '• Dates are calculated based on template patterns (S1, S2, S3)\n'
              '• Custom names will override auto-generated names\n'
              '• This action cannot be undone easily',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    ],
  );
}
```

#### **Step 4: Import Results**
```dart
Widget _buildStep4Summary() {
  final result = _importResult!;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildStepHeader(4, 'Import Results'),
      const SizedBox(height: 20),
      
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          border: Border.all(color: Colors.grey[700]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Rate Display
            Row(
              children: [
                Icon(
                  result.successRate >= 80 ? Icons.check_circle : Icons.warning,
                  color: result.successRate >= 80 ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Import Completed', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${result.successRate.toStringAsFixed(1)}% Success Rate', 
                        style: TextStyle(
                          fontSize: 14, 
                          color: result.successRate >= 80 ? Colors.green : Colors.orange
                        )),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Statistics
            _buildSummaryRow('Total processed:', '${result.totalRecords}', Colors.blue),
            const SizedBox(height: 8),
            _buildSummaryRow('Successfully created:', '${result.successfulSemesters.length}', Colors.green),
            const SizedBox(height: 8),
            _buildSummaryRow('Failed to create:', '${result.failedRecords.length}', Colors.red),
            
            if ((_importResult!['successfulSemesters'] as List).isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('✅ Created Semesters:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: (_importResult!['successfulSemesters'] as List<SemesterModel>).length,
                  itemBuilder: (context, index) {
                    final semester = (_importResult!['successfulSemesters'] as List<SemesterModel>)[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      title: Text('${semester.code}: ${semester.name}', 
                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                      subtitle: Text('${DateFormat('dd/MM/yyyy').format(semester.startDate)} - ${DateFormat('dd/MM/yyyy').format(semester.endDate)}', 
                        style: const TextStyle(fontSize: 10, color: Colors.green)),
                    );
                  },
                ),
              ),
            ],
            
            if (result.failedRecords.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('❌ Failed Records:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.failedRecords.length,
                  itemBuilder: (context, index) {
                    final failed = result.failedRecords[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.error, color: Colors.red, size: 16),
                      title: Text('${failed['code'] ?? 'Unknown'}', 
                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                      subtitle: Text('${failed['error']}', 
                        style: const TextStyle(fontSize: 10, color: Colors.red)),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
```

---

### **🔸 D. Integration with Instructor Dashboard**

#### **Integration Steps:**

1. **Wire Import Button** in `instructor_courses_page.dart`:
```dart
// In the Import CSV dropdown menu
MenuItemButton(
  child: const Text('Import Semesters'),
  onPressed: () => _showSemesterImportDialog(),
),

Future<void> _showSemesterImportDialog() async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: CsvImportSemesterScreen(
          onImportComplete: _handleImportComplete,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
}

void _handleImportComplete() {
  Navigator.of(context).pop();
  // ⚠️ CRITICAL: Refresh semester list
  _refreshSemesterList();
  _showSuccessMessage('Semesters imported successfully! Semester list has been refreshed.');
}

void _refreshSemesterList() {
  // Trigger semester filter widget to reload data
  // This ensures the dropdown shows new semesters
  setState(() {
    // Force rebuild of semester filter component
  });
}
```

2. **Auto-refresh Semester List** after import completion to show newly imported semesters.

---

## 🎯 Key Advantages of This Simplified Approach

### **1. Reuse Existing Architecture**
- **No New Models**: Use existing `SemesterModel` and `SemesterTemplateModel`
- **Leverage Existing Business Logic**: Use `SemesterController.handleCreateSemester()`
- **Consistent Validation**: Same validation rules as manual semester creation

### **2. Correct Template IDs**
- **S1, S2, S3**: Use actual existing templates, not fictional HK1, HK2
- **Template Mapping**: Direct lookup from existing `SemesterTemplates.allTemplates`
- **No Template Discovery Issues**: Work with what's already implemented

### **3. Clean Separation of Concerns**
- **Repository**: Only CSV parsing and basic validation
- **Controller**: Business logic, duplicate checking, complex validation
- **UI**: Pure presentation layer following student import pattern

### **4. English User Messages**
- All error messages, validation feedback, and user notifications in English
- Consistent with professional software development practices
- Better for international users and development team

---

## 📋 Simple Implementation Checklist

### **Phase 1: Core Files**
- [ ] Create `semester_import_repository.dart` - CSV parsing only
- [ ] Create `semester_import_controller.dart` - Business logic only
- [ ] Create `csv_import_semester.dart` - UI only

### **Phase 2: Integration**
- [ ] Add "Import Semesters" to instructor dashboard dropdown
- [ ] Wire import completion to refresh semester list
- [ ] Test with S1, S2, S3 templates

### **Phase 3: User Experience**
- [ ] English error messages and notifications
- [ ] Preview shows correct template names and dates
- [ ] Auto-refresh semester dropdown after import

---

## 🚀 Expected Workflow

1. **User clicks "Import Semesters"** from Import CSV dropdown
2. **Dialog opens** with 4-step CSV import process
3. **User uploads CSV** with S1,2025 / S2,2025 / S3,2025 format
4. **System validates** against existing S1, S2, S3 templates
5. **Preview shows** generated semesters with correct dates
6. **Import executes** using existing `SemesterController` logic
7. **Dialog closes** and semester list auto-refreshes
8. **User sees new semesters** immediately in semester dropdown

### **Sample CSV Data:**
```csv
templateId,year,name
S1,2025,Fall Semester 2025
S2,2026,Spring Semester 2026
S3,2025,Summer Semester 2025
S1,2026,Fall Semester 2026
```

---

*This simplified approach leverages existing architecture, avoids unnecessary complexity, and provides a clean, maintainable solution for semester bulk import.*