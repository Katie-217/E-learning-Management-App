import 'package:flutter/material.dart';

class InstructorSemester {
  final String id;
  final String code;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;

  const InstructorSemester({
    required this.id,
    required this.code,
    required this.name,
    required this.startDate,
    this.endDate,
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
  final GlobalKey _dropdownKey = GlobalKey();

  static final List<InstructorSemester> _defaultSemesters = [
    InstructorSemester(
      id: 'hk1_2025',
      code: 'HK1/25',
      name: 'Spring 2025',
      startDate: DateTime(2025, 1, 10),
      endDate: DateTime(2025, 5, 31),
    ),
    InstructorSemester(
      id: 'hk2_2024',
      code: 'HK2/24',
      name: 'Fall 2024',
      startDate: DateTime(2024, 9, 1),
      endDate: DateTime(2024, 12, 31),
    ),
    InstructorSemester(
      id: 'hk1_2024',
      code: 'HK1/24',
      name: 'Spring 2024',
      startDate: DateTime(2024, 1, 8),
      endDate: DateTime(2024, 5, 31),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Ưu tiên dùng data thật từ widget, chỉ dùng default khi widget.semesters là null hoặc empty
    // Nhưng nếu widget.semesters là empty list (đang load), vẫn dùng default tạm thời
    _semesters = (widget.semesters != null && widget.semesters!.isNotEmpty)
        ? widget.semesters!
        : _defaultSemesters;
    _selectedSemester = widget.initialSemester ??
        _semesters.reduce((a, b) =>
            a.startDate.isAfter(b.startDate) ? a : b); // latest by startDate
  }

  @override
  void didUpdateWidget(InstructorSemesterSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update semesters khi widget.semesters thay đổi (khi data thật được load)
    if (widget.semesters != oldWidget.semesters) {
      // Luôn ưu tiên dùng data thật từ widget khi có
      // Nếu widget.semesters là empty list, giữ nguyên _semesters hiện tại (không revert về default)
      if (widget.semesters != null && widget.semesters!.isNotEmpty) {
        setState(() {
          _semesters = widget.semesters!;
          // Update selected semester nếu initialSemester thay đổi
          if (widget.initialSemester != null) {
            _selectedSemester = widget.initialSemester!;
          } else if (!_semesters.any((s) => s.id == _selectedSemester.id)) {
            // Nếu selected semester không còn trong list, chọn semester mới nhất
            _selectedSemester = _semesters.reduce((a, b) =>
                a.startDate.isAfter(b.startDate) ? a : b);
          }
        });
      }
    }
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
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150, maxWidth: 300),
            child: _buildDropdown(isSmall),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(bool isSmall) {
    final fontSize = isSmall ? 11.0 : 13.0;
    final iconSize = isSmall ? 16.0 : 18.0;
    
    return Builder(
      builder: (BuildContext buttonContext) {
        return InkWell(
          onTap: () => _showDropdownMenu(buttonContext, isSmall, fontSize),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            key: _dropdownKey,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    '${_selectedSemester.code} • ${_selectedSemester.name}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(Icons.expand_more, color: Colors.white70, size: iconSize),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDropdownMenu(BuildContext context, bool isSmall, double fontSize) {
    final RenderBox? button = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null || !button.attached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showDropdownMenu(context, isSmall, fontSize);
        }
      });
      return;
    }

    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final Offset buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size buttonSize = button.size;

    showMenu<InstructorSemester>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx, // Align với left edge của button
        buttonPosition.dy + buttonSize.height + 15, // Ngay bên dưới button, không có khoảng cách
        buttonPosition.dx + buttonSize.width,
        buttonPosition.dy + buttonSize.height,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: const Color(0xFF1F2937),
      elevation: 8,
      items: _semesters.map((semester) {
        final isSelected = semester.id == _selectedSemester.id;
        return PopupMenuItem<InstructorSemester>(
          value: semester,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${semester.code} • ${semester.name}',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        _onSelect(value);
      }
    });
  }
}
