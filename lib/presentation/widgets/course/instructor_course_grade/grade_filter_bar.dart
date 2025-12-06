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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmall = screenWidth < 600;
        final padding = isSmall 
            ? const EdgeInsets.all(12)
            : const EdgeInsets.all(16);
        final spacing = isSmall ? 8.0 : 12.0;
        final fontSize = isSmall ? 13.0 : 14.0;
        final iconSize = isSmall ? 18.0 : 20.0;
        
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              TextField(
                onChanged: onSearchChanged,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: fontSize,
                ),
                decoration: InputDecoration(
                  hintText: isSmall 
                      ? 'Search...' 
                      : 'Search by name, ID, or group...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: fontSize,
                  ),
                  prefixIcon: Icon(
                    Icons.search, 
                    color: AppColors.textSecondary,
                    size: iconSize,
                  ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 12 : 16,
                    vertical: isSmall ? 12 : 16,
                  ),
                  isDense: isSmall,
                ),
              ),
              SizedBox(height: spacing),
              isSmall
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFilterDropdown<String>(
                          label: 'Type',
                          value: selectedType ?? 'All',
                          items: const ['All', 'assignment', 'quiz'],
                          onChanged: onTypeChanged,
                          isSmall: isSmall,
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
                        SizedBox(height: spacing),
                        Opacity(
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
                              isSmall: isSmall,
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
                        SizedBox(height: spacing),
                        Opacity(
                          opacity: selectedItemId == null || selectedItemId == 'All' ? 0.5 : 1.0,
                          child: IgnorePointer(
                            ignoring: selectedItemId == null || selectedItemId == 'All',
                            child: _buildFilterDropdown<String>(
                              label: 'Group',
                              value: selectedGroup,
                              items: availableGroups,
                              onChanged: onGroupChanged,
                              isSmall: isSmall,
                            ),
                          ),
                        ),
                        SizedBox(height: spacing),
                        Opacity(
                          opacity: selectedItemId == null || selectedItemId == 'All' ? 0.5 : 1.0,
                          child: IgnorePointer(
                            ignoring: selectedItemId == null || selectedItemId == 'All',
                            child: _buildFilterDropdown<String>(
                              label: 'Status',
                              value: selectedStatus ?? 'all',
                              items: ['all', 'submitted', 'late', 'not_submitted'],
                              onChanged: onStatusChanged,
                              isSmall: isSmall,
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
                                if (value == 'all') return null;
                                switch (value) {
                                  case 'submitted':
                                    return Icon(Icons.check_circle, color: Colors.blue, size: iconSize);
                                  case 'late':
                                    return Icon(Icons.warning, color: Colors.orange, size: iconSize);
                                  case 'not_submitted':
                                    return Icon(Icons.cancel, color: Colors.red, size: iconSize);
                                  default:
                                    return null;
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: spacing),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: onReset,
                            tooltip: 'Reset filters',
                            icon: Icon(
                              Icons.refresh, 
                              color: AppColors.primary,
                              size: iconSize,
                            ),
                            padding: EdgeInsets.all(isSmall ? 4 : 8),
                            constraints: BoxConstraints(
                              minWidth: isSmall ? 32 : 48,
                              minHeight: isSmall ? 32 : 48,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown<String>(
                            label: 'Type',
                            value: selectedType ?? 'All',
                            items: const ['All', 'assignment', 'quiz'],
                            onChanged: onTypeChanged,
                            isSmall: isSmall,
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
                        SizedBox(width: spacing),
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
                                isSmall: isSmall,
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
                        SizedBox(width: spacing),
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
                                isSmall: isSmall,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: spacing),
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
                                isSmall: isSmall,
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
                                  if (value == 'all') return null;
                                  switch (value) {
                                    case 'submitted':
                                      return Icon(Icons.check_circle, color: Colors.blue, size: iconSize);
                                    case 'late':
                                      return Icon(Icons.warning, color: Colors.orange, size: iconSize);
                                    case 'not_submitted':
                                      return Icon(Icons.cancel, color: Colors.red, size: iconSize);
                                    default:
                                      return null;
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: spacing),
                        IconButton(
                          onPressed: onReset,
                          tooltip: 'Reset filters',
                          icon: Icon(
                            Icons.refresh, 
                            color: AppColors.primary,
                            size: iconSize,
                          ),
                          padding: EdgeInsets.all(isSmall ? 4 : 8),
                          constraints: BoxConstraints(
                            minWidth: isSmall ? 32 : 48,
                            minHeight: isSmall ? 32 : 48,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required bool isSmall,
    String Function(T)? displayText,
    Widget? Function(T)? iconBuilder,
  }) {
    final effectiveValue = value ?? (items.isNotEmpty ? items.first : null);
    
    return _CustomDropdownButton<T>(
      label: label,
      value: effectiveValue,
      items: items,
      onChanged: onChanged,
      isSmall: isSmall,
      displayText: displayText,
      iconBuilder: iconBuilder,
    );
  }
}

class _CustomDropdownButton<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final bool isSmall;
  final String Function(T)? displayText;
  final Widget? Function(T)? iconBuilder;

  const _CustomDropdownButton({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isSmall,
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
    final fontSize = widget.isSmall ? 13.0 : 14.0;
    final iconSize = widget.isSmall ? 18.0 : 20.0;
    final padding = widget.isSmall 
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    
    return InkWell(
      key: _buttonKey,
      onTap: () => _showMenu(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: fontSize,
          ),
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
          contentPadding: padding,
          isDense: widget.isSmall,
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
            size: iconSize,
          ),
        ),
        child: Text(
          widget.value != null
              ? (widget.displayText != null
                  ? widget.displayText!(widget.value!)
                  : widget.value.toString())
              : '',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: fontSize,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}


