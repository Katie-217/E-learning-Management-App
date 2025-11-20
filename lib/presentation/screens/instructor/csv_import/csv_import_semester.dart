// ========================================
// FILE: csv_import_semester.dart
// MÔ TẢ: UI cho semester CSV import - 4 steps workflow
// Clean Architecture: Presentation Layer
// ========================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../../application/controllers/semester/semester_import_controller.dart';
import '../../../../domain/models/semester_template_model.dart';
import '../../../../domain/models/semester_import_models.dart';

typedef ImportCompleteCallback = void Function(bool success, String message);

class CsvImportSemesterScreen extends StatefulWidget {
  final ImportCompleteCallback? onImportComplete;
  final VoidCallback? onCancel;

  const CsvImportSemesterScreen({
    super.key,
    this.onImportComplete,
    this.onCancel,
  });

  @override
  State<CsvImportSemesterScreen> createState() =>
      _CsvImportSemesterScreenState();
}

class _CsvImportSemesterScreenState extends State<CsvImportSemesterScreen> {
  final SemesterImportController _importController = SemesterImportController();

  // UI State Management - CHỈ chứa dữ liệu hiển thị
  int _currentStep = 1;
  String? _selectedFileName;
  String? _fileContent;
  Map<String, dynamic>? _referenceData;
  ImportSessionData? _sessionData;
  ImportResult? _importResult;
  bool _isLoading = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      _referenceData = await _importController.preloadReferenceData();
      setState(() {});
      print('DEBUG: ✅ Reference data loaded');
    } catch (e) {
      _showError('Failed to load system data: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true, // Ensure we get bytes data
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? content;

        // Handle different platforms for file reading
        if (file.bytes != null) {
          // Web or data available
          content = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
          // Windows/Desktop - read from path
          try {
            final fileHandle = File(file.path!);
            content = await fileHandle.readAsString();
          } catch (pathError) {
            _showError('Cannot read file from path: $pathError');
            return;
          }
        } else {
          _showError(
              'File data not available. Please try selecting the file again.');
          return;
        }

        if (content.isNotEmpty) {
          setState(() {
            _selectedFileName = file.name;
            _fileContent = content;
            _sessionData = null;
            _importResult = null;
          });
          print(
              'DEBUG: ✅ File loaded: ${file.name}, ${content.length} characters');
        } else {
          _showError('File appears to be empty or unreadable.');
        }
      }
    } catch (e) {
      _showError('File selection error: $e');
    }
  }

  Future<void> _validateAndParse() async {
    if (_fileContent == null || _referenceData == null) {
      _showError('Missing file content or system data. Please try again.');
      return;
    }

    setState(() => _isValidating = true);

    try {
      print('DEBUG: 🔄 Starting CSV processing...');
      print('DEBUG: File content length: ${_fileContent!.length} characters');

      // Gọi Controller để xử lý toàn bộ logic
      final sessionData = await _importController.processAndValidateCsv(
          _fileContent!, _referenceData!);

      // Check if we got any results
      if (sessionData.summary.totalRecords == 0) {
        _showError(
            'No data found in CSV file. Please check if the file contains valid semester data.');
        return;
      }

      setState(() {
        _sessionData = sessionData;
        _currentStep = 2;
      });

      print('DEBUG: ✅ Processed ${sessionData.summary.totalRecords} records');
      print(
          'DEBUG: New: ${sessionData.summary.newCount}, Existing: ${sessionData.summary.existingCount}, Invalid: ${sessionData.summary.invalidCount}');
    } catch (e) {
      print('DEBUG: ❌ CSV processing failed: $e');
      _showError('CSV processing error: $e');
    } finally {
      setState(() => _isValidating = false);
    }
  }

  Future<void> _importData() async {
    if (_sessionData == null) {
      _showError('No data to import');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_sessionData!.newItems.isEmpty) {
        _showError('No new semesters to add');
        setState(() => _isLoading = false);
        return;
      }

      print(
          'DEBUG: 🔥 Importing ${_sessionData!.newItems.length} new semesters...');

      final result = await _importController.importSemesters(_sessionData!);

      setState(() {
        _importResult = result;
        _currentStep = 4;
      });

      print(
          'DEBUG: ✅ Import completed - Success: ${result.successCount}, Failed: ${result.failureCount}');
    } catch (e) {
      _showError('Import error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  void _handleComplete() {
    final success = _importResult != null && _importResult!.hasSuccesses;
    final message = success
        ? 'Successfully imported ${_importResult!.successCount} semesters!'
        : 'Import completed with issues';

    if (widget.onImportComplete != null) {
      widget.onImportComplete!(success, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111827),
      child: Column(
        children: [
          // Header area with title and back button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _handleCancel,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.school, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Semesters from CSV',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Bulk import semesters using CSV file format',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1F2937),
            child: _buildProgressIndicator(),
          ),
          // Main content area - expanded to use full space
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStep(),
                ],
              ),
            ),
          ),
          // Action buttons at the bottom - Hidden in Step 1 for cleaner UI
          if (_currentStep > 1 ||
              (_currentStep == 1 && _selectedFileName != null))
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
              child: _buildActionButtons(),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        final stepNum = index + 1;
        final isActive = _currentStep >= stepNum;
        final isCompleted = _currentStep > stepNum;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.blue : Colors.grey[700],
                  border: Border.all(
                    color: isActive ? Colors.blue : Colors.grey[600]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          stepNum.toString(),
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    color:
                        _currentStep > stepNum ? Colors.blue : Colors.grey[700],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Upload();
      case 2:
        return _buildStep2Preview();
      case 3:
        return _buildStep3Confirm();
      case 4:
        return _buildStep4Summary();
      default:
        return _buildStep1Upload();
    }
  }

  Widget _buildStep1Upload() {
    final templates =
        _referenceData?['templates'] as List<SemesterTemplateModel>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(1, 'Upload Semester CSV File'),
        const SizedBox(height: 16),

        // CSV Format Guide
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[900]?.withValues(alpha: 0.2),
            border: Border.all(color: Colors.blue[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📋 Semester CSV Format Guide:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue),
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
                'S1,2025,Fall Semester 2025\n'
                'S2,2025,Spring Semester 2025\n'
                'S3,2025,Summer Semester 2025',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // File selection - Clean and simple
        if (_selectedFileName == null)
          Center(
            child: SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Select CSV File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[900]?.withValues(alpha: 0.3),
              border: Border.all(color: Colors.green[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        '✅ File selected',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedFileName = null;
                      _fileContent = null;
                      _sessionData = null;
                      _importResult = null;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStep2Preview() {
    if (_sessionData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final newItems = _sessionData!.newItems;
    final existingItems = _sessionData!.existingItems;
    final invalidItems = _sessionData!.invalidItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(2, 'Preview and Validate Semesters'),
        const SizedBox(height: 16),

        // Statistics Row
        Row(
          children: [
            Expanded(
                child: _buildStatBox(
              title: 'New Semesters',
              count: _sessionData!.summary.newCount,
              color: Colors.green,
              icon: Icons.add_circle,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatBox(
              title: 'Already Exists',
              count: _sessionData!.summary.existingCount,
              color: Colors.orange,
              icon: Icons.warning,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatBox(
              title: 'Invalid Data',
              count: _sessionData!.summary.invalidCount,
              color: Colors.red,
              icon: Icons.error,
            )),
          ],
        ),

        const SizedBox(height: 20),

        // Invalid Records Detail
        if (invalidItems.isNotEmpty) ...[
          const Text('❌ Invalid data (cannot import):',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.red[900]?.withValues(alpha: 0.2),
              border: Border.all(color: Colors.red[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: invalidItems.length,
              itemBuilder: (context, index) {
                final item = invalidItems[index];
                final errors = item.validationErrors.join(', ');
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.error, color: Colors.red, size: 16),
                  title: Text(
                      'Row ${item.rawRecord.rowIndex}: ${item.rawRecord.templateId}_${item.rawRecord.year}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white)),
                  subtitle: Text(errors,
                      style: const TextStyle(fontSize: 10, color: Colors.red)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Existing Records Detail
        if (existingItems.isNotEmpty) ...[
          const Text('⚠️ Already exists (will be skipped):',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: Colors.orange[900]?.withValues(alpha: 0.2),
              border: Border.all(color: Colors.orange[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: existingItems.length,
              itemBuilder: (context, index) {
                final item = existingItems[index];
                return ListTile(
                  dense: true,
                  leading:
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                  title: Text('${item.generatedCode}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white)),
                  subtitle: const Text('Already exists in system',
                      style: TextStyle(fontSize: 10, color: Colors.orange)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // New Records Preview - Full Table Layout
        const Text('✅ New semesters to be created:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 14)),
        const SizedBox(height: 12),

        // Full-width data table for better visualization
        Container(
          decoration: BoxDecoration(
            color: Colors.green[900]?.withValues(alpha: 0.1),
            border: Border.all(color: Colors.green[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[800]?.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('Semester Code',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12))),
                    Expanded(
                        flex: 3,
                        child: Text('Name',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12))),
                    Expanded(
                        flex: 2,
                        child: Text('Start Date',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12))),
                    Expanded(
                        flex: 2,
                        child: Text('End Date',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12))),
                    Expanded(
                        flex: 1,
                        child: Text('Days',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12))),
                  ],
                ),
              ),
              // Table Body with scrollable content
              Container(
                constraints: const BoxConstraints(
                    maxHeight: 400), // Increased height for more rows
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: newItems.length, // Show all records
                  itemBuilder: (context, index) {
                    final item = newItems[index];
                    final semester = item.previewSemester!;
                    final duration =
                        semester.endDate.difference(semester.startDate).inDays;
                    final isEven = index % 2 == 0;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.green[900]?.withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text(semester.code,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 3,
                              child: Text(semester.name,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white))),
                          Expanded(
                              flex: 2,
                              child: Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(semester.startDate),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey))),
                          Expanded(
                              flex: 2,
                              child: Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(semester.endDate),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey))),
                          Expanded(
                              flex: 1,
                              child: Text('$duration',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.green))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Confirm() {
    if (_sessionData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _sessionData!.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(3, 'Confirm Semester Import'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[900]?.withValues(alpha: 0.2),
            border: Border.all(color: Colors.blue[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📊 Import Summary:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue)),
              const SizedBox(height: 12),
              _buildConfirmRow(
                  'New semesters to create:', summary.newCount, Colors.green),
              const SizedBox(height: 6),
              _buildConfirmRow('Total academic days:',
                  summary.totalDurationDays, Colors.blue),
              const SizedBox(height: 6),
              _buildConfirmRow('Year range:', summary.yearRange, Colors.purple),
              const SizedBox(height: 16),
              const Text('⚠️ Important Notes:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange)),
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

  Widget _buildStep4Summary() {
    if (_importResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final result = _importResult!;
    final successRate = result.successRate;

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
                    successRate >= 80 ? Icons.check_circle : Icons.warning,
                    color: successRate >= 80 ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Import Completed',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('${successRate.toStringAsFixed(1)}% Success Rate',
                            style: TextStyle(
                                fontSize: 14,
                                color: successRate >= 80
                                    ? Colors.green
                                    : Colors.orange)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Statistics
              _buildSummaryRow(
                  'Total processed:', '${result.totalProcessed}', Colors.blue),
              const SizedBox(height: 8),
              _buildSummaryRow('Successfully created:',
                  '${result.successCount}', Colors.green),
              const SizedBox(height: 8),
              _buildSummaryRow(
                  'Failed to create:', '${result.failureCount}', Colors.red),

              if (result.successfulSemesters.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('✅ Created Semesters:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: result.successfulSemesters.length,
                    itemBuilder: (context, index) {
                      final semester = result.successfulSemesters[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                        title: Text('${semester.code}: ${semester.name}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white)),
                        subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(semester.startDate)} - ${DateFormat('dd/MM/yyyy').format(semester.endDate)}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.green)),
                      );
                    },
                  ),
                ),
              ],

              if (result.failedImports.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('❌ Failed Records:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.red)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: result.failedImports.length,
                    itemBuilder: (context, index) {
                      final failure = result.failedImports[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.error,
                            color: Colors.red, size: 16),
                        title: Text(
                            '${failure.item.generatedCode ?? 'Unknown'}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white)),
                        subtitle: Text(failure.errorMessage,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.red)),
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

  Widget _buildStepHeader(int step, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $step: $title',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 2,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, dynamic value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  if (_currentStep == 2) {
                    _currentStep = 1;
                  } else if (_currentStep == 3) {
                    _currentStep = 2;
                  }
                });
              },
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 12),
        if (_currentStep == 1)
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedFileName != null && !_isValidating
                  ? _validateAndParse
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Validate & Parse'),
            ),
          ),
        if (_currentStep == 2)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() => _currentStep = 3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ),
        if (_currentStep == 3)
          Expanded(
            child: ElevatedButton(
              onPressed: !_isLoading ? _importData : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Import Semesters'),
            ),
          ),
        if (_currentStep == 4)
          Expanded(
            child: ElevatedButton(
              onPressed: _handleComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ),
      ],
    );
  }
}
