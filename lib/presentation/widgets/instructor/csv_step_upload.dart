// presentation/widgets/instructor/csv_step_upload.dart
import 'package:flutter/material.dart';

class CsvStepUpload extends StatelessWidget {
  final String? selectedFileName;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const CsvStepUpload({
    super.key,
    this.selectedFileName,
    required this.onPickFile,
    required this.onClearFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Upload CSV File',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
              const Text(
                '📋 CSV format guide:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '✓ Required columns:\n'
                ' • email (example: sv001@example.com)\n'
                ' • name (example: Nguyen Van A)\n'
                ' • studentCode (example: SV001)\n\n'
                '✓ Optional columns:\n'
                ' • phone (10 digits)\n'
                ' • department (department name)\n\n'
                '✓ Column order: Not required\n'
                '✓ First row: Must be headers\n'
                '✓ Format: CSV with comma (,) as separator',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (selectedFileName == null)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onPickFile,
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
              color: Colors.green[900]?.withOpacity(0.3),
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
                        selectedFileName!,
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
                  onPressed: onClearFile,
                ),
              ],
            ),
          ),
      ],
    );
  }
}