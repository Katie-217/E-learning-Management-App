// ========================================
// FILE: csv_import_group.dart
// MÔ TẢ: UI cho group CSV import - 4 steps workflow
// Clean Architecture: Presentation Layer
// ========================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../application/controllers/group/group_import_controller.dart';
import '../../../../domain/models/group_import_models.dart';

typedef ImportCompleteCallback = void Function(bool success, String message);

class CsvImportGroupScreen extends StatefulWidget {
  final String courseId;
  final String courseName;
  final ImportCompleteCallback? onImportComplete;
  final VoidCallback? onCancel;

  const CsvImportGroupScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    this.onImportComplete,
    this.onCancel,
  });

  @override
  State<CsvImportGroupScreen> createState() => _CsvImportGroupScreenState();
}

class _CsvImportGroupScreenState extends State<CsvImportGroupScreen> {
  final GroupImportController _importController = GroupImportController();

  // UI State Management
  int _currentStep = 1;
  String? _selectedFileName;
  String? _fileContent;
  GroupImportSessionData? _sessionData;
  GroupImportResult? _importResult;
  bool _isLoading = false;
  bool _isValidating = false;

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
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? content;

        if (file.bytes != null) {
          content = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
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

        if (content.isEmpty) {
          _showError('Selected file is empty');
          return;
        }

        setState(() {
          _selectedFileName = file.name;
          _fileContent = content;
        });

        await _validateFile();
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _validateFile() async {
    if (_fileContent == null) return;

    setState(() {
      _isValidating = true;
    });

    try {
      final sessionData = await _importController.parseAndValidate(
        csvContent: _fileContent!,
        courseId: widget.courseId,
      );

      setState(() {
        _sessionData = sessionData;
        _currentStep = 2;
        _isValidating = false;
      });
    } catch (e) {
      _showError('Validation failed: $e');
      setState(() {
        _isValidating = false;
        _selectedFileName = null;
        _fileContent = null;
      });
    }
  }

  Future<void> _executeImport() async {
    if (_sessionData == null || !_sessionData!.hasValidRows) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _importController.importGroups(
        courseId: widget.courseId,
        rows: _sessionData!.rows,
      );

      setState(() {
        _importResult = result;
        _currentStep = 4;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Import failed: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleComplete() {
    final success = _importResult != null && _importResult!.hasSuccesses;
    final message = success
        ? 'Successfully imported ${_importResult!.successCount} groups!'
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
          // Header
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
                const Icon(Icons.group, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Groups from CSV',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Course: ${widget.courseName}',
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
          // Main content
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
          // Action buttons
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
              Expanded(
                child: Column(
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
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStepTitle(stepNum),
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? Colors.white : Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (index < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? Colors.blue : Colors.grey[700],
                    margin: const EdgeInsets.only(bottom: 30),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Upload';
      case 2:
        return 'Preview';
      case 3:
        return 'Confirm';
      case 4:
        return 'Summary';
      default:
        return '';
    }
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
        return const SizedBox();
    }
  }

  Widget _buildStep1Upload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(1, 'Upload CSV File'),
        const SizedBox(height: 24),

        // File format instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'CSV File Format',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Your CSV file must have the following columns:',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              SizedBox(height: 8),
              _buildFormatItem(
                  'code', 'Required', 'Unique group code (e.g., G01, G02)'),
              _buildFormatItem(
                  'name', 'Required', 'Group name (e.g., Group 1)'),
              _buildFormatItem('description', 'Optional', 'Group description'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF111827),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example:',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'code,name,description\nG01,Group 1,First group\nG02,Group 2,Second group',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // File upload button
        Center(
          child: _isValidating
              ? Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Validating file...',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                )
              : _selectedFileName != null
                  ? Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File selected:',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                              Text(
                                _selectedFileName!,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedFileName = null;
                                _fileContent = null;
                              });
                            },
                            child: Text('Change'),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: Icon(Icons.upload_file),
                      label: Text('Select CSV File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFormatItem(String column, String required, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: required == 'Required'
                  ? Colors.red.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              column,
              style: TextStyle(
                color:
                    required == 'Required' ? Colors.red[300] : Colors.grey[300],
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: required == 'Required'
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              required,
              style: TextStyle(
                color: required == 'Required'
                    ? Colors.orange[300]
                    : Colors.blue[300],
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Preview() {
    if (_sessionData == null) return SizedBox();

    final hasDuplicates = _sessionData!.duplicateCodes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(2, 'Preview & Validation'),
        SizedBox(height: 24),

        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Rows',
                '${_sessionData!.rows.length}',
                Icons.list_alt,
                Colors.blue,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Valid',
                '${_sessionData!.validCount}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Errors',
                '${_sessionData!.errorCount}',
                Icons.error,
                Colors.red,
              ),
            ),
          ],
        ),

        SizedBox(height: 24),

        // Duplicate warning
        if (hasDuplicates)
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Existing Group Codes Found',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'The following group codes already exist in this course: ${_sessionData!.duplicateCodes.join(", ")}',
                        style:
                            TextStyle(color: Colors.orange[200], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Data table
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF111827),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text('#',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Code',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('Name',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('Description',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Status',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              // Table rows
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _sessionData!.rows.length,
                itemBuilder: (context, index) {
                  final row = _sessionData!.rows[index];
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[800]!),
                      ),
                      color: row.isValid ? null : Colors.red.withOpacity(0.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                '${row.rowNumber}',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                row.code,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                row.name,
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                row.description ?? '-',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Icon(
                                    row.isValid
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color:
                                        row.isValid ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    row.isValid ? 'Valid' : 'Error',
                                    style: TextStyle(
                                      color: row.isValid
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!row.isValid) ...[
                          SizedBox(height: 8),
                          ...row.validationErrors.map((error) => Padding(
                                padding: EdgeInsets.only(left: 60),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.orange, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      error,
                                      style: TextStyle(
                                          color: Colors.orange, fontSize: 12),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Confirm() {
    if (_sessionData == null) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(3, 'Confirm Import'),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Ready to import groups',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildConfirmItem('Course', widget.courseName),
              _buildConfirmItem(
                  'Groups to import', '${_sessionData!.validCount}'),
              if (_sessionData!.errorCount > 0)
                _buildConfirmItem('Rows with errors (will be skipped)',
                    '${_sessionData!.errorCount}'),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This action will create ${_sessionData!.validCount} new group(s) in the course. Please confirm to proceed.',
                        style:
                            TextStyle(color: Colors.amber[200], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Summary() {
    if (_importResult == null) return SizedBox();

    final hasSuccess = _importResult!.hasSuccesses;
    final hasFailures = _importResult!.hasFailures;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(4, 'Import Summary'),
        SizedBox(height: 24),

        // Success/Failure summary
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSuccess ? Colors.green : Colors.red,
            ),
          ),
          child: Column(
            children: [
              Icon(
                hasSuccess ? Icons.check_circle : Icons.error,
                color: hasSuccess ? Colors.green : Colors.red,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                hasSuccess ? 'Import Completed!' : 'Import Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultCard(
                    'Successfully Imported',
                    '${_importResult!.successCount}',
                    Colors.green,
                  ),
                  if (hasFailures)
                    _buildResultCard(
                      'Failed',
                      '${_importResult!.failureCount}',
                      Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),

        // Failure details
        if (hasFailures) ...[
          SizedBox(height: 24),
          Text(
            'Failed Imports:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _importResult!.failures.length,
              itemBuilder: (context, index) {
                final failure = _importResult!.failures[index];
                return Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[800]!),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Row ${failure.rowNumber}: ${failure.code} - ${failure.name}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Error: ${failure.error}',
                        style: TextStyle(color: Colors.red[300], fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepHeader(int step, String title) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        if (_currentStep > 1 && _currentStep < 4)
          TextButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      if (_currentStep == 3) {
                        _currentStep = 2;
                      } else if (_currentStep == 2) {
                        _currentStep = 1;
                        _sessionData = null;
                      }
                    });
                  },
            icon: Icon(Icons.arrow_back),
            label: Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
            ),
          ),
        if (_currentStep == 4)
          TextButton.icon(
            onPressed: _handleCancel,
            icon: Icon(Icons.close),
            label: Text('Close'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
            ),
          ),

        Spacer(),

        // Next/Import button
        if (_currentStep == 2)
          ElevatedButton.icon(
            onPressed: _sessionData != null && _sessionData!.hasValidRows
                ? () {
                    setState(() {
                      _currentStep = 3;
                    });
                  }
                : null,
            icon: Icon(Icons.arrow_forward),
            label: Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[700],
              disabledForegroundColor: Colors.grey[500],
            ),
          ),
        if (_currentStep == 3)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _executeImport,
            icon: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.upload),
            label: Text(_isLoading ? 'Importing...' : 'Import Groups'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        if (_currentStep == 4)
          ElevatedButton.icon(
            onPressed: _handleComplete,
            icon: Icon(Icons.check),
            label: Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
