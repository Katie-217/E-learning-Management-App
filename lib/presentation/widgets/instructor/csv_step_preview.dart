// presentation/widgets/instructor/csv_step_preview.dart
import 'package:flutter/material.dart';
import '../../../data/repositories/csv/csv_import_service.dart';

class CsvStepPreview extends StatelessWidget {
  final List<StudentImportRecord> parsedRecords;
  final int newCount;
  final int duplicateCount;
  final int invalidCount;

  const CsvStepPreview({
    super.key,
    required this.parsedRecords,
    required this.newCount,
    required this.duplicateCount,
    required this.invalidCount,
  });

  @override
  Widget build(BuildContext context) {
    final newRecords = parsedRecords.where((r) => r.status == 'new').toList();
    final duplicateRecords = parsedRecords.where((r) => r.status == 'duplicate').toList();
    final invalidRecords = parsedRecords.where((r) => r.status == 'invalid').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Preview and Validate',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                title: 'New to add',
                count: newCount,
                color: Colors.green,
                icon: Icons.add_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                title: 'Already exists',
                count: duplicateCount,
                color: Colors.orange,
                icon: Icons.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                title: 'Data errors',
                count: invalidCount,
                color: Colors.red,
                icon: Icons.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (invalidRecords.isNotEmpty) ...[
          const Text(
            '❌ Invalid data (cannot import):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.red[900]?.withOpacity(0.2),
              border: Border.all(color: Colors.red[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      ...record.errorMessages.map((err) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '• $err',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[300],
                              ),
                            ),
                          )),
                      if (index < invalidRecords.length - 1)
                        const Divider(color: Colors.red, height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (duplicateRecords.isNotEmpty) ...[
          const Text(
            '⚠️ Existing students (will be skipped automatically):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange[900]?.withOpacity(0.2),
              border: Border.all(color: Colors.orange[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: duplicateRecords.length,
              itemBuilder: (context, index) {
                final record = duplicateRecords[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${record.data['name'] ?? 'N/A'} (${record.duplicateEmail})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (newRecords.isNotEmpty) ...[
          const Text(
            '✅ New students (ready to import):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.green[900]?.withOpacity(0.2),
              border: Border.all(color: Colors.green[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: newRecords.length,
              itemBuilder: (context, index) {
                final record = newRecords[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${record.data['name'] ?? 'N/A'} (${record.data['email'] ?? 'N/A'})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildStatBox({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
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
}