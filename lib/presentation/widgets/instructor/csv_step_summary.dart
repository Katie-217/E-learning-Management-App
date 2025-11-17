// presentation/widgets/instructor/csv_step_summary.dart
import 'package:flutter/material.dart';
import '../../../application/controllers/csv/bulk_import_controller.dart';
class CsvStepSummary extends StatelessWidget {
  final ImportResult importResult;
  final int duplicateCount;
  final int invalidCount;
  final List<Map<String, dynamic>> failedRecords;

  const CsvStepSummary({
    super.key,
    required this.importResult,
    required this.duplicateCount,
    required this.invalidCount,
    required this.failedRecords,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4: Import Summary',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📊 Import Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: importResult.successCount > 0
                          ? Colors.green[900]
                          : Colors.red[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      importResult.successCount > 0
                          ? '✅ Success'
                          : '❌ Unsuccessful',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                '✅ New students added:',
                importResult.successCount.toString(),
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                '⏭️ Skipped (duplicates):',
                duplicateCount.toString(),
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                '⏭️ Skipped (data errors):',
                invalidCount.toString(),
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                '❌ Errors:',
                importResult.failureCount.toString(),
                Colors.red,
              ),
              const Divider(height: 20, color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total records:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${invalidCount + duplicateCount + importResult.successCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (importResult.failureCount > 0) ...[
          const Text(
            '❌ Error details:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 14,
            ),
          ),
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
              itemCount: failedRecords.length,
              itemBuilder: (context, index) {
                final record = failedRecords[index];
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['email'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        record['error'] ?? 'Unknown error',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[300],
                        ),
                      ),
                      if (index < failedRecords.length - 1)
                        const Divider(color: Colors.red, height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[400],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}