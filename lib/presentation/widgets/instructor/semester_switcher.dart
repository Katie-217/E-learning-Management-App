import 'package:flutter/material.dart';

class InstructorSemester {
  final String id;
  final String code;
  final String name;
  final DateTime startDate;

  const InstructorSemester({
    required this.id,
    required this.code,
    required this.name,
    required this.startDate,
  });
}

class InstructorSemesterSwitcher extends StatefulWidget {
  final List<InstructorSemester>? semesters;
  final InstructorSemester? initialSemester;
  final ValueChanged<InstructorSemester>? onSemesterChanged;

  const InstructorSemesterSwitcher({
    super.key,
    this.semesters,
    this.initialSemester,
    this.onSemesterChanged,
  });

  @override
  State<InstructorSemesterSwitcher> createState() =>
      _InstructorSemesterSwitcherState();
}

class _InstructorSemesterSwitcherState
    extends State<InstructorSemesterSwitcher> {
  late final List<InstructorSemester> _semesters;
  late InstructorSemester _selectedSemester;

  static final List<InstructorSemester> _defaultSemesters = [
    InstructorSemester(
      id: 'hk1_2025',
      code: 'HK1/25',
      name: 'Spring 2025',
      startDate: DateTime(2025, 1, 10),
    ),
    InstructorSemester(
      id: 'hk2_2024',
      code: 'HK2/24',
      name: 'Fall 2024',
      startDate: DateTime(2024, 9, 1),
    ),
    InstructorSemester(
      id: 'hk1_2024',
      code: 'HK1/24',
      name: 'Spring 2024',
      startDate: DateTime(2024, 1, 8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _semesters = (widget.semesters?.isNotEmpty == true)
        ? widget.semesters!
        : _defaultSemesters;
    _selectedSemester = widget.initialSemester ??
        _semesters.reduce((a, b) =>
            a.startDate.isAfter(b.startDate) ? a : b); // latest by startDate
  }

  void _onSelect(InstructorSemester semester) {
    if (_selectedSemester.id == semester.id) return;
    setState(() {
      _selectedSemester = semester;
    });
    widget.onSemesterChanged?.call(semester);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 10);
    final iconSize = isSmall ? 16.0 : 18.0;
    final spacing = isSmall ? 6.0 : 8.0;
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[700]!.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school, size: iconSize, color: Colors.white),
          SizedBox(width: spacing),
          Flexible(
            child: _buildDropdown(isSmall),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(bool isSmall) {
    final fontSize = isSmall ? 11.0 : 13.0;
    final iconSize = isSmall ? 16.0 : 18.0;
    
    return DropdownButtonHideUnderline(
      child: DropdownButton<InstructorSemester>(
        dropdownColor: const Color(0xFF1F2937),
        value: _selectedSemester,
        isExpanded: true, // Allow dropdown to expand to fill available space
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
        icon: Icon(Icons.expand_more, color: Colors.white70, size: iconSize),
        iconSize: iconSize + 2,
        onChanged: (value) {
          if (value != null) {
            _onSelect(value);
          }
        },
        items: _semesters
            .map(
              (semester) => DropdownMenuItem(
                value: semester,
                child: Text(
                  '${semester.code} • ${semester.name}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList(),
        selectedItemBuilder: (context) {
          return _semesters.map((semester) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${semester.code} • ${semester.name}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
