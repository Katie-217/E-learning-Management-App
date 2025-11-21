import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../data/repositories/csv/csv_import_repository.dart';
import '../../../../application/controllers/csv/bulk_import_controller.dart';
import '../../../../data/repositories/student/student_repository.dart';

typedef ImportCompleteCallback = void Function(bool success, String message);

class CsvImportScreen extends StatefulWidget {
  final String dataType;
  final ImportCompleteCallback? onImportComplete;
  final VoidCallback? onCancel;

  const CsvImportScreen({
    super.key,
    required this.dataType,
    this.onImportComplete,
    this.onCancel,
  });

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  int _currentStep = 1;
  String? _selectedFileName;
  String? _fileContent;
  Map<String, dynamic>? _structureValidation;
  List<StudentImportRecord>? _parsedRecords;
  List<String> _existingEmails = [];
  bool _isLoading = false;
  bool _isValidating = false;
  ImportResult? _importResult;
  int _newCount = 0;
  int _duplicateCount = 0;
  int _invalidCount = 0;

  @override
  void initState() {
    super.initState();
    _loadExistingEmails();
  }

  Future<void> _loadExistingEmails() async {
    try {
      final students = await StudentRepository.getAllStudents();
      setState(() {
        _existingEmails = students.map((s) => s.email.toLowerCase()).toList();
      });
    } catch (e) {
      // Silent fail – no debug print
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final content = String.fromCharCodes(file.bytes!);

        setState(() {
          _selectedFileName = file.name;
          _fileContent = content;
          _structureValidation = null;
          _parsedRecords = null;
        });
      }
    } catch (e) {
      _showError('File selection error: $e');
    }
  }

  Future<void> _validateAndParse() async {
    if (_fileContent == null) return;

    setState(() => _isValidating = true);

    try {
      // Only email & name are required now
      final validation = CsvImportService.validateCsvStructure(
        _fileContent!,
        ['email', 'name'],
      );

      if (validation['isValid'] != true) {
        _showError('CSV structure error: ${validation['error']}');
        setState(() => _isValidating = false);
        return;
      }

      final records = await CsvImportService.parseAndValidateStudentsCsv(
        _fileContent!,
        _existingEmails,
      );

      _newCount = records.where((r) => r.status == 'new').length;
      _duplicateCount = records.where((r) => r.status == 'duplicate').length;
      _invalidCount = records.where((r) => r.status == 'invalid').length;

      setState(() {
        _structureValidation = validation;
        _parsedRecords = records;
        _currentStep = 2;
      });
    } catch (e) {
      _showError('CSV parsing error: $e');
    } finally {
      setState(() => _isValidating = false);
    }
  }

  Future<void> _importData() async {
    if (_parsedRecords == null || _parsedRecords!.isEmpty) {
      _showError('No data to import');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = BulkImportController();

      final recordsToImport = _parsedRecords!
          .where((r) => r.status == 'new')
          .map((r) => r.data)
          .toList();

      if (recordsToImport.isEmpty) {
        _showError('No new students to add');
        setState(() => _isLoading = false);
        return;
      }

      final result = await controller.importStudents(recordsToImport);

      await _loadExistingEmails();

      setState(() {
        _importResult = result;
        _currentStep = 4;
      });
    } catch (e) {
      _showError('Import error: $e');
    } finally {
      setState(() => _isLoading = false);
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

  Widget _buildStep1Upload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(1, 'Upload CSV File'),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[900]?.withValues(alpha: 0.2),
            border: Border.all(color: Colors.blue[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CSV format guide:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Required columns:\n'
                ' • email (example: sv001@example.com)\n'
                ' • name (example: Nguyen Van A)\n\n'
                'Optional columns:\n'
                ' • phone (10 digits)\n\n'
                'Column order: Not required\n'
                'First row: Must be headers\n'
                'Format: CSV with comma (,) as separator',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_selectedFileName == null)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select CSV File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
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
                        'File selected',
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
                      _structureValidation = null;
                      _parsedRecords = null;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  // The rest of the UI widgets remain exactly the same as in your final version
  // (Preview, Confirm, Summary, buttons, etc.) – only the required changes above were applied

  Widget _buildStep2Preview() {
    if (_parsedRecords == null || _parsedRecords!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final newRecords = _parsedRecords!.where((r) => r.status == 'new').toList();
    final duplicateRecords = _parsedRecords!.where((r) => r.status == 'duplicate').toList();
    final invalidRecords = _parsedRecords!.where((r) => r.status == 'invalid').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(2, 'Preview and Validate'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                title: 'New to add',
                count: newRecords.length,
                color: Colors.green,
                icon: Icons.add_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                title: 'Already exists',
                count: duplicateRecords.length,
                color: Colors.orange,
                icon: Icons.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                title: 'Data errors',
                count: invalidRecords.length,
                color: Colors.red,
                icon: Icons.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (invalidRecords.isNotEmpty) ...[
          const Text(
            'Invalid data (cannot import):',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
          ),
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
              itemCount: invalidRecords.length,
              itemBuilder: (context, index) {
                final record = invalidRecords[index];
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Row ${record.rowIndex}: ${record.data['email'] ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      ...record.errorMessages.map((err) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('• $err', style: TextStyle(fontSize: 12, color: Colors.red[300])),
                          )),
                      if (index < invalidRecords.length - 1) const Divider(color: Colors.red, height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'New students to be added:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          decoration: BoxDecoration(
            color: Colors.green[900]?.withValues(alpha: 0.2),
            border: Border.all(color: Colors.green[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: newRecords.take(5).length,
            itemBuilder: (context, index) {
              final record = newRecords[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '${index + 1}. ${record.data['name']} (${record.data['email']})',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
        if (newRecords.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... and ${newRecords.length - 5} other students',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildStep3Confirm() {
    final newRecords = _parsedRecords!.where((r) => r.status == 'new').toList();
    final duplicateCount = _parsedRecords!.where((r) => r.status == 'duplicate').length;
    final invalidCount = _parsedRecords!.where((r) => r.status == 'invalid').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(3, 'Confirm Import'),
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
              const Text(
                'Summary:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              _buildConfirmRow('New students to add:', newRecords.length, Colors.green),
              const SizedBox(height: 8),
              _buildConfirmRow('Will skip (duplicates):', duplicateCount, Colors.orange),
              const SizedBox(height: 8),
              _buildConfirmRow('Will skip (data errors):', invalidCount, Colors.red),
              const Divider(height: 16, color: Colors.blue),
              const Text(
                'Note: The system will:\n'
                ' • Create accounts only for new students\n'
                ' • Automatically skip existing students\n'
                ' • Automatically skip records with data errors',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Summary() {
    if (_importResult == null) return const Center(child: CircularProgressIndicator());

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Import Statistics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _importResult!.successCount > 0 ? Colors.green[900] : Colors.red[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _importResult!.successCount > 0 ? 'Success' : 'Unsuccessful',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('New students added:', _importResult!.successCount.toString(), Colors.green),
              const SizedBox(height: 12),
              _buildSummaryRow('Skipped (duplicates):', _duplicateCount.toString(), Colors.orange),
              const SizedBox(height: 12),
              _buildSummaryRow('Skipped (data errors):', _invalidCount.toString(), Colors.orange),
              const SizedBox(height: 12),
              _buildSummaryRow('Errors:', _importResult!.failureCount.toString(), Colors.red),
              const Divider(height: 20, color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total records:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  Text(
                    '${_invalidCount + _duplicateCount + _importResult!.successCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 24),
            if (_currentStep == 1) _buildStep1Upload(),
            if (_currentStep == 2 && !_isValidating) _buildStep2Preview(),
            if (_currentStep == 2 && _isValidating)
              const Center(child: CircularProgressIndicator(color: Colors.blue)),
            if (_currentStep == 3) _buildStep3Confirm(),
            if (_currentStep == 4) _buildStep4Summary(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // Helper widgets remain unchanged (progress indicator, headers, stat boxes, buttons, etc.)
  // Only the parts you asked to modify have been updated.

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        final stepNum = index + 1;
        final isActive = _currentStep >= stepNum;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$stepNum', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              if (index < 3)
                Expanded(
                  child: Container(height: 2, color: _currentStep > stepNum ? Colors.blue : Colors.grey[700]),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepHeader(int step, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step $step: $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Container(width: 40, height: 2, color: Colors.blue),
      ],
    );
  }

  Widget _buildStatBox({required String title, required int count, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.2), border: Border.all(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 6), Expanded(child: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[400])))]),
          const SizedBox(height: 8),
          Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.2), border: Border.all(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(6)),
          child: Text(value.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
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
          decoration: BoxDecoration(color: color.withOpacity(0.2), border: Border.all(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(6)),
          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_currentStep > 1 && _currentStep < 4)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey[600]!)),
            ),
          ),
        if (_currentStep > 1 && _currentStep < 4) const SizedBox(width: 12),
        if (_currentStep == 1)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _selectedFileName == null || _isValidating ? null : _validateAndParse,
              icon: _isValidating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(_isValidating ? 'Checking...' : 'Continue', style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        if (_currentStep == 2)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => setState(() => _currentStep = 3),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to confirm', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        if (_currentStep == 3)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _importData,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload),
              label: Text(_isLoading ? 'Importing...' : 'Import now', style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        if (_currentStep == 4)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onImportComplete != null) {
                  final success = _importResult!.successCount > 0;
                  final message = success
                      ? 'Import successful: ${_importResult!.successCount} students added'
                      : 'Import completed: No new students added';
                  widget.onImportComplete!(success, message);
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Done', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
      ],
    );
  }
}
