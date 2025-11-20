// ========================================
// FILE: quiz_results_table.dart
// MÔ TẢ: Quiz Results Table cho instructor dashboard - MOCK DATA
// ========================================

import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

// Model cho quiz results data
class QuizResultsData {
  final String studentName;
  final String group;
  final double score;
  final int attemptCount;
  final DateTime? completionTime;
  final bool passed; // true = Passed, false = Failed
  final double passScore; // Pass threshold

  QuizResultsData({
    required this.studentName,
    required this.group,
    required this.score,
    required this.attemptCount,
    this.completionTime,
    required this.passed,
    required this.passScore,
  });
}

class QuizResultsTable extends StatefulWidget {
  const QuizResultsTable({super.key});

  @override
  State<QuizResultsTable> createState() => _QuizResultsTableState();
}

class _QuizResultsTableState extends State<QuizResultsTable> {
  // Mock data
  final List<QuizResultsData> _allData = [
    QuizResultsData(
      studentName: 'Nguyen Van A',
      group: 'Group 1',
      score: 8.5,
      attemptCount: 2,
      completionTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      passed: true,
      passScore: 6.5,
    ),
    QuizResultsData(
      studentName: 'Tran Thi B',
      group: 'Group 1',
      score: 5.0,
      attemptCount: 1,
      completionTime: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      passed: false,
      passScore: 6.5,
    ),
    QuizResultsData(
      studentName: 'Le Van C',
      group: 'Group 2',
      score: 9.0,
      attemptCount: 3,
      completionTime: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      passed: true,
      passScore: 6.5,
    ),
    QuizResultsData(
      studentName: 'Pham Thi D',
      group: 'Group 2',
      score: 7.5,
      attemptCount: 1,
      completionTime: DateTime.now().subtract(const Duration(days: 4, hours: 1)),
      passed: true,
      passScore: 6.5,
    ),
    QuizResultsData(
      studentName: 'Hoang Van E',
      group: 'Group 3',
      score: 6.0,
      attemptCount: 2,
      completionTime: DateTime.now().subtract(const Duration(hours: 12)),
      passed: false,
      passScore: 6.5,
    ),
    QuizResultsData(
      studentName: 'Vu Thi F',
      group: 'Group 3',
      score: 9.5,
      attemptCount: 1,
      completionTime: DateTime.now().subtract(const Duration(hours: 6)),
      passed: true,
      passScore: 6.5,
    ),
    QuizResultsData(
      studentName: 'Dang Van G',
      group: 'Group 1',
      score: 4.5,
      attemptCount: 2,
      completionTime: DateTime.now().subtract(const Duration(days: 5)),
      passed: false,
      passScore: 6.5,
    ),
    QuizResultsData(
      studentName: 'Bui Thi H',
      group: 'Group 2',
      score: 8.0,
      attemptCount: 1,
      completionTime: DateTime.now().subtract(const Duration(days: 1)),
      passed: true,
      passScore: 6.5,
    ),
  ];

  List<QuizResultsData> _filteredData = [];
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _groupFilter = 'All';
  String _sortColumn = 'studentName';
  bool _sortAscending = true;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(_allData);
    _applyFilters();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredData = List.from(_allData);

      // Search filter
      if (_searchQuery.isNotEmpty) {
        _filteredData = _filteredData.where((data) {
          return data.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              data.group.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }

      // Status filter
      if (_statusFilter != 'All') {
        _filteredData = _filteredData.where((data) {
          if (_statusFilter == 'Passed') {
            return data.passed;
          } else if (_statusFilter == 'Failed') {
            return !data.passed;
          }
          return true;
        }).toList();
      }

      // Group filter
      if (_groupFilter != 'All') {
        _filteredData = _filteredData.where((data) {
          return data.group == _groupFilter;
        }).toList();
      }

      // Sort
      _filteredData.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'studentName':
            comparison = a.studentName.compareTo(b.studentName);
            break;
          case 'group':
            comparison = a.group.compareTo(b.group);
            break;
          case 'score':
            comparison = a.score.compareTo(b.score);
            break;
          case 'attemptCount':
            comparison = a.attemptCount.compareTo(b.attemptCount);
            break;
          case 'completionTime':
            final aTime = a.completionTime ?? DateTime(1970);
            final bTime = b.completionTime ?? DateTime(1970);
            comparison = aTime.compareTo(bTime);
            break;
          case 'status':
            comparison = a.passed.toString().compareTo(b.passed.toString());
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _applyFilters();
    });
  }

  Future<void> _exportToCSV() async {
    try {
      // Create CSV data
      final List<List<dynamic>> csvData = [];
      
      // Header row
      csvData.add([
        'Student Name',
        'Group',
        'Score',
        'Attempt Count',
        'Status',
        'Completion Time',
      ]);

      // Data rows
      for (final data in _filteredData) {
        csvData.add([
          data.studentName,
          data.group,
          data.score.toStringAsFixed(1),
          data.attemptCount,
          data.passed ? 'Passed' : 'Failed',
          data.completionTime != null
              ? '${data.completionTime!.day}/${data.completionTime!.month}/${data.completionTime!.year} ${data.completionTime!.hour}:${data.completionTime!.minute.toString().padLeft(2, '0')}'
              : '',
        ]);
      }

      // Convert to CSV string
      const converter = ListToCsvConverter();
      final csvString = converter.convert(csvData);

      // Save file
      final fileName = 'quiz_results_${DateTime.now().millisecondsSinceEpoch}.csv';
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Quiz Results CSV',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: utf8.encode(csvString),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully to: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _allData.map((e) => e.group).toSet().toList()..sort();
    final statuses = ['All', 'Passed', 'Failed'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Export Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quiz Results',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exportToCSV,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search and Filters
          Row(
            children: [
              // Search
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by student name or group...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF1F2937),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Status Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Status:',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      underline: const SizedBox(),
                      items: statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _statusFilter = value;
                          _applyFilters();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Group Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Group:',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _groupFilter,
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      underline: const SizedBox(),
                      items: ['All', ...groups].map((group) {
                        return DropdownMenuItem(
                          value: group,
                          child: Text(group),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _groupFilter = value;
                          _applyFilters();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table with fixed header
          Expanded(
            child: Column(
              children: [
                // Fixed Header
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F2937),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _horizontalScrollController,
                    child: DataTable(
                      headingRowHeight: 48,
                      headingRowColor: MaterialStateProperty.all(
                        const Color(0xFF1F2937),
                      ),
                      columns: [
                        _buildDataColumn('Student Name', 'studentName'),
                        _buildDataColumn('Group', 'group'),
                        _buildDataColumn('Score', 'score'),
                        _buildDataColumn('Attempt Count', 'attemptCount'),
                        _buildDataColumn('Completion Time', 'completionTime'),
                        _buildDataColumn('Status', 'status'),
                      ],
                      rows: const [], // Empty rows for header only
                    ),
                  ),
                ),
                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _horizontalScrollController,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 0,
                        dataRowColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return const Color(0xFF1F2937);
                          }
                          return Colors.transparent;
                        }),
                        columns: [
                          _buildDataColumn('Student Name', 'studentName'),
                          _buildDataColumn('Group', 'group'),
                          _buildDataColumn('Score', 'score'),
                          _buildDataColumn('Attempt Count', 'attemptCount'),
                          _buildDataColumn('Completion Time', 'completionTime'),
                          _buildDataColumn('Status', 'status'),
                        ],
                        rows: _filteredData.map((data) {
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          data.studentName,
                          style: const TextStyle(color: Colors.white),
                        )),
                        DataCell(Text(
                          data.group,
                          style: const TextStyle(color: Colors.white70),
                        )),
                        DataCell(Text(
                          data.score.toStringAsFixed(1),
                          style: TextStyle(
                            color: _getScoreColor(data.score),
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        DataCell(Text(
                          data.attemptCount.toString(),
                          style: const TextStyle(color: Colors.white70),
                        )),
                        DataCell(Text(
                          data.completionTime != null
                              ? '${data.completionTime!.day}/${data.completionTime!.month}/${data.completionTime!.year} ${data.completionTime!.hour}:${data.completionTime!.minute.toString().padLeft(2, '0')}'
                              : '-',
                          style: const TextStyle(color: Colors.white70),
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (data.passed
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFFF6B6B))
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: data.passed
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFFF6B6B),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              data.passed ? 'Passed' : 'Failed',
                              style: TextStyle(
                                color: data.passed
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFFF6B6B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(String label, String columnName) {
    final isSorted = _sortColumn == columnName;
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isSorted)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: Colors.white70,
            ),
        ],
      ),
      onSort: (columnIndex, ascending) => _onSort(columnName),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) {
      return const Color(0xFF34D399); // Green
    } else if (score >= 6.5) {
      return const Color(0xFFFFB347); // Orange
    } else {
      return const Color(0xFFFF6B6B); // Red
    }
  }
}

