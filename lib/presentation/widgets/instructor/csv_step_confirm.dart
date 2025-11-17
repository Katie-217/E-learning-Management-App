// presentation/widgets/instructor/csv_step_confirm.dart
import 'package:flutter/material.dart';

class CsvStepConfirm extends StatelessWidget {
  final int newCount;
  final int duplicateCount;
  final int invalidCount;
  final int totalRecords;

  const CsvStepConfirm({
    super.key,
    required this.newCount,
    required this.duplicateCount,
    required this.invalidCount,
    required this.totalRecords,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Confirm Import',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Please review the import summary below. Only new records will be imported. Duplicates and invalid data will be skipped.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[900]?.withOpacity(0.2),
            border: Border.all(color: Colors.blue[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildConfirmRow('✅ New students to add:', newCount, Colors.green),
              const SizedBox(height: 12),
              _buildConfirmRow('⏭️ Skipped (duplicates):', duplicateCount, Colors.orange),
              const SizedBox(height: 12),
              _buildConfirmRow('⏭️ Skipped (data errors):', invalidCount, Colors.orange),
              const Divider(height: 20, color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total records in file:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    totalRecords.toString(),
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
      ],
    );
  }

  Widget _buildConfirmRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
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
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}