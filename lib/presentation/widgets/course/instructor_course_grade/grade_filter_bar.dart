import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';

class GradeFilterBar extends StatelessWidget {
  final String searchQuery;
  final String? selectedGroup;
  final String? selectedType;
  final String? selectedItemId;
  final String? selectedStatus;
  final List<Assignment> assignments;
  final List<String> availableGroups;
  final List<Assignment> availableItems;
  final bool isItemDisabled;
  final Function(String) onSearchChanged;
  final Function(String?) onGroupChanged;
  final Function(String?) onTypeChanged;
  final Function(String?) onItemChanged;
  final Function(String?) onStatusChanged;
  final VoidCallback onReset;

  const GradeFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedGroup,
    required this.selectedType,
    required this.selectedItemId,
    required this.selectedStatus,
    required this.assignments,
    required this.availableGroups,
    required this.availableItems,
    required this.isItemDisabled,
    required this.onSearchChanged,
    required this.onGroupChanged,
    required this.onTypeChanged,
    required this.onItemChanged,
    required this.onStatusChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name, ID, or group...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filters row: Type | Item (Assignment) | Group | Status | Reset
          Row(
            children: [
              // Type filter: All | Assignment | Quiz
              Expanded(
                child: _buildFilterDropdown<String>(
                  label: 'Type',
                  value: selectedType ?? 'All',
                  items: const ['All', 'assignment', 'quiz'],
                  onChanged: onTypeChanged,
                  displayText: (value) {
                    if (value == 'All' || value == null) return 'All';
                    switch (value) {
                      case 'assignment':
                        return 'Assignment';
                      case 'quiz':
                        return 'Quiz';
                      default:
                        return value;
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Item filter: Assignment/Quiz - phụ thuộc vào Type
              Expanded(
                child: Opacity(
                  opacity: isItemDisabled ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: isItemDisabled,
                    child: _buildFilterDropdown<String>(
                      label: 'Item',
                      value: selectedItemId,
                      items: [
                        'All',
                        ...availableItems.map((a) => a.id),
                      ],
                      onChanged: onItemChanged,
                      displayText: (value) {
                        if (value == 'All' || value == null) {
                          if (selectedType == 'assignment') return 'All Assignments';
                          if (selectedType == 'quiz') return 'All Quizzes';
                          return 'All';
                        }
                        try {
                          final assignment = assignments.firstWhere((a) => a.id == value);
                          return assignment.title;
                        } catch (e) {
                          return value;
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Group filter: phụ thuộc vào Item đã chọn
              Expanded(
                child: Opacity(
                  opacity: selectedItemId == null || selectedItemId == 'All' ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: selectedItemId == null || selectedItemId == 'All',
                    child: _buildFilterDropdown<String>(
                      label: 'Group',
                      value: selectedGroup,
                      items: availableGroups,
                      onChanged: onGroupChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Status filter: phụ thuộc vào Item đã chọn
              Expanded(
                child: Opacity(
                  opacity: selectedItemId == null || selectedItemId == 'All' ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: selectedItemId == null || selectedItemId == 'All',
                    child: _buildFilterDropdown<String>(
                      label: 'Status',
                      value: selectedStatus ?? 'all',
                      items: ['all', 'submitted', 'late', 'not_submitted'],
                      onChanged: onStatusChanged,
                      displayText: (value) {
                        switch (value) {
                          case 'all':
                            return 'All';
                          case 'submitted':
                            return 'Submitted';
                          case 'late':
                            return 'Late';
                          case 'not_submitted':
                            return 'Not Submitted';
                          default:
                            return value;
                        }
                      },
                      iconBuilder: (value) {
                        // Only show icon in dropdown items, not in prefixIcon
                        if (value == 'all') return null; // Don't show icon for "all"
                        switch (value) {
                          case 'submitted':
                            return const Icon(Icons.check_circle, color: Colors.blue, size: 20);
                          case 'late':
                            return const Icon(Icons.warning, color: Colors.orange, size: 20);
                          case 'not_submitted':
                            return const Icon(Icons.cancel, color: Colors.red, size: 20);
                          default:
                            return null;
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Reset filters button
              IconButton(
                onPressed: onReset,
                tooltip: 'Reset filters',
                icon: const Icon(Icons.refresh, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    String Function(T)? displayText,
    Widget? Function(T)? iconBuilder,
  }) {
    final effectiveValue = value ?? (items.isNotEmpty ? items.first : null);
    
    return _CustomDropdownButton<T>(
      label: label,
      value: effectiveValue,
      items: items,
      onChanged: onChanged,
      displayText: displayText,
      iconBuilder: iconBuilder,
    );
  }
}

// Custom dropdown widget để force menu hiển thị bên dưới
class _CustomDropdownButton<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final String Function(T)? displayText;
  final Widget? Function(T)? iconBuilder;

  const _CustomDropdownButton({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.displayText,
    this.iconBuilder,
  });

  @override
  State<_CustomDropdownButton<T>> createState() => _CustomDropdownButtonState<T>();
}

class _CustomDropdownButtonState<T> extends State<_CustomDropdownButton<T>> {
  final GlobalKey _buttonKey = GlobalKey();

  void _showMenu(BuildContext context) {
    final RenderBox? button = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final OverlayState? overlay = Overlay.of(context);
    if (overlay == null) return;

    final RenderBox? overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlayBox);
    final Size buttonSize = button.size;

    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + buttonSize.height + 4, // Hiển thị ngay bên dưới button
        position.dx + buttonSize.width,
        position.dy + buttonSize.height + 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: AppColors.surface,
      elevation: 8,
      constraints: const BoxConstraints(
        maxHeight: 250,
        minWidth: 200,
      ),
      items: widget.items.map((item) {
        final icon = widget.iconBuilder != null ? widget.iconBuilder!(item) : null;
        return PopupMenuItem<T>(
          value: item,
          child: SizedBox(
            height: 48.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.displayText != null 
                        ? widget.displayText!(item) 
                        : item.toString(),
                    style: const TextStyle(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ).then((selectedValue) {
      if (selectedValue != null) {
        widget.onChanged(selectedValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: _buttonKey,
      onTap: () => _showMenu(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
          ),
        ),
        child: Text(
          widget.value != null
              ? (widget.displayText != null
                  ? widget.displayText!(widget.value!)
                  : widget.value.toString())
              : '',
          style: const TextStyle(color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}


