import 'package:flutter/material.dart';
import 'package:elearning_management_app/domain/models/assignment_model.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';

class GradeFilterBar extends StatelessWidget {
  final String searchQuery;
  final String? selectedGroup;
  final String? selectedType;
  final String? selectedItemId;
  final String? selectedStatus;
  final List<Assignment> assignments;
  final List<String> availableGroups;
  final List<dynamic>
      availableItems; // Changed to dynamic to support both Assignment and Quiz
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
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Responsive layout based on screen size
              if (isMobile)
                _buildMobileLayout()
              else if (isTablet)
                _buildTabletLayout()
              else
                _buildDesktopLayout(),
            ],
          ),
        );
      },
    );
  }

  // Mobile: Stacked vertical layout
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildFilterDropdown<String>(
          label: 'Type',
          value: selectedType,
          items: const ['assignment', 'quiz'],
          onChanged: onTypeChanged,
          displayText: (value) {
            if (value == null) return 'Choose type';
            return value == 'assignment'
                ? 'Assignment'
                : value == 'quiz'
                    ? 'Quiz'
                    : value;
          },
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: isItemDisabled ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: isItemDisabled,
            child: _buildFilterDropdown<String>(
              label: 'Item',
              value: selectedItemId,
              items: availableItems.map((item) {
                if (item is Assignment) {
                  return item.id;
                } else if (item is Quiz) {
                  return item.id;
                } else {
                  return item.toString();
                }
              }).toList(),
              onChanged: onItemChanged,
              displayText: (value) {
                if (value == null) return 'Choose item';
                try {
                  // Try finding in availableItems
                  final item = availableItems.firstWhere(
                    (item) =>
                        (item is Assignment && item.id == value) ||
                        (item is Quiz && item.id == value),
                  );
                  if (item is Assignment) {
                    return item.title;
                  } else if (item is Quiz) {
                    return item.title;
                  }
                } catch (e) {
                  // Fallback to showing value
                }
                return value;
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: selectedItemId == null ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: selectedItemId == null,
            child: _buildFilterDropdown<String>(
              label: 'Group',
              value: selectedGroup,
              items: ['All', ...availableGroups],
              onChanged: onGroupChanged,
              displayText: (value) {
                if (value == 'All' || value == null) return 'All Groups';
                return value; // Group name (not ID)
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: selectedItemId == null ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: selectedItemId == null,
            child: _buildFilterDropdown<String>(
              label: 'Status',
              value: selectedStatus ?? 'all',
              items: _getStatusItems(),
              onChanged: onStatusChanged,
              displayText: _getStatusDisplayText,
              iconBuilder: _getStatusIcon,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: onReset,
            tooltip: 'Reset filters',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  // Tablet: 2 columns layout
  Widget _buildTabletLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown<String>(
                label: 'Type',
                value: selectedType,
                items: const ['assignment', 'quiz'],
                onChanged: onTypeChanged,
                displayText: (value) {
                  if (value == null) return 'Choose type';
                  return value == 'assignment'
                      ? 'Assignment'
                      : value == 'quiz'
                          ? 'Quiz'
                          : value;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: isItemDisabled ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: isItemDisabled,
                  child: _buildFilterDropdown<String>(
                    label: 'Item',
                    value: selectedItemId,
                    items: availableItems.map((item) {
                      if (item is Assignment) return item.id;
                      if (item is Quiz) return item.id;
                      return item.toString();
                    }).toList(),
                    onChanged: onItemChanged,
                    displayText: (value) {
                      if (value == null) return 'Choose item';
                      try {
                        final item = availableItems.firstWhere(
                          (item) =>
                              (item is Assignment && item.id == value) ||
                              (item is Quiz && item.id == value),
                        );
                        if (item is Assignment) return item.title;
                        if (item is Quiz) return item.title;
                      } catch (e) {}
                      return value;
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: selectedItemId == null ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: selectedItemId == null,
                  child: _buildFilterDropdown<String>(
                    label: 'Group',
                    value: selectedGroup,
                    items: ['All', ...availableGroups],
                    onChanged: onGroupChanged,
                    displayText: (value) {
                      if (value == 'All' || value == null) return 'All Groups';
                      return value;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: selectedItemId == null ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: selectedItemId == null,
                  child: _buildFilterDropdown<String>(
                    label: 'Status',
                    value: selectedStatus ?? 'all',
                    items: _getStatusItems(),
                    onChanged: onStatusChanged,
                    displayText: _getStatusDisplayText,
                    iconBuilder: _getStatusIcon,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onReset,
              tooltip: 'Reset filters',
              icon: const Icon(Icons.refresh, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  // Desktop: All in one row (original layout)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterDropdown<String>(
            label: 'Type',
            value: selectedType,
            items: const ['assignment', 'quiz'],
            onChanged: onTypeChanged,
            displayText: (value) {
              if (value == null) return 'Choose type';
              return value == 'assignment'
                  ? 'Assignment'
                  : value == 'quiz'
                      ? 'Quiz'
                      : value;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Opacity(
            opacity: isItemDisabled ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: isItemDisabled,
              child: _buildFilterDropdown<String>(
                label: 'Item',
                value: selectedItemId,
                items: availableItems.map((item) {
                  if (item is Assignment) return item.id;
                  if (item is Quiz) return item.id;
                  return item.toString();
                }).toList(),
                onChanged: onItemChanged,
                displayText: (value) {
                  if (value == null) return 'Choose item';
                  try {
                    final item = availableItems.firstWhere(
                      (item) =>
                          (item is Assignment && item.id == value) ||
                          (item is Quiz && item.id == value),
                    );
                    if (item is Assignment) return item.title;
                    if (item is Quiz) return item.title;
                  } catch (e) {}
                  return value;
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Opacity(
            opacity: selectedItemId == null ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: selectedItemId == null,
              child: _buildFilterDropdown<String>(
                label: 'Group',
                value: selectedGroup,
                items: ['All', ...availableGroups],
                onChanged: onGroupChanged,
                displayText: (value) {
                  if (value == 'All' || value == null) return 'All Groups';
                  return value;
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Opacity(
            opacity: selectedItemId == null ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: selectedItemId == null,
              child: _buildFilterDropdown<String>(
                label: 'Status',
                value: selectedStatus ?? 'all',
                items: _getStatusItems(),
                onChanged: onStatusChanged,
                displayText: _getStatusDisplayText,
                iconBuilder: _getStatusIcon,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onReset,
          tooltip: 'Reset filters',
          icon: const Icon(Icons.refresh, color: AppColors.primary),
        ),
      ],
    );
  }

  String _getStatusDisplayText(String value) {
    // Assignment statuses
    if (selectedType == 'assignment') {
      switch (value) {
        case 'all':
          return 'All';
        case 'missing':
          return 'Missing';
        case 'submitted':
          return 'Submitted';
        case 'late':
          return 'Late';
        case 'graded':
          return 'Graded';
        default:
          return value;
      }
    }

    // Quiz statuses
    if (selectedType == 'quiz') {
      switch (value) {
        case 'all':
          return 'All';
        case 'not_started':
          return 'Not Started';
        case 'in_progress':
          return 'In Progress';
        case 'completed':
          return 'Completed';
        default:
          return value;
      }
    }

    return value;
  }

  Widget? _getStatusIcon(String value) {
    if (value == 'all') return null;

    // Assignment icons
    if (selectedType == 'assignment') {
      switch (value) {
        case 'missing':
          return const Icon(Icons.cancel, color: Colors.red, size: 20);
        case 'submitted':
          return const Icon(Icons.check_circle, color: Colors.blue, size: 20);
        case 'late':
          return const Icon(Icons.warning, color: Colors.orange, size: 20);
        case 'graded':
          return const Icon(Icons.grade, color: Colors.green, size: 20);
        default:
          return null;
      }
    }

    // Quiz icons
    if (selectedType == 'quiz') {
      switch (value) {
        case 'not_started':
          return const Icon(Icons.play_circle_outline,
              color: Colors.grey, size: 20);
        case 'in_progress':
          return const Icon(Icons.pending, color: Colors.orange, size: 20);
        case 'completed':
          return const Icon(Icons.check_circle, color: Colors.green, size: 20);
        default:
          return null;
      }
    }

    return null;
  }

  /// Get status items based on selected type
  List<String> _getStatusItems() {
    if (selectedType == 'assignment') {
      return const ['all', 'missing', 'submitted', 'late', 'graded'];
    } else if (selectedType == 'quiz') {
      return const ['all', 'not_started', 'in_progress', 'completed'];
    }
    return const ['all'];
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    String Function(T)? displayText,
    Widget? Function(T)? iconBuilder,
  }) {
    // Don't auto-select first item, allow null to show hint
    return _CustomDropdownButton<T>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
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
  State<_CustomDropdownButton<T>> createState() =>
      _CustomDropdownButtonState<T>();
}

class _CustomDropdownButtonState<T> extends State<_CustomDropdownButton<T>> {
  final GlobalKey _buttonKey = GlobalKey();

  void _showMenu(BuildContext context) {
    final RenderBox? button =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final OverlayState? overlay = Overlay.of(context);
    if (overlay == null) return;

    final RenderBox? overlayBox =
        overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlayBox);
    final Size buttonSize = button.size;

    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + buttonSize.height + 4, // Hiá»ƒn thá»‹ ngay bÃªn dÆ°á»›i button
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
        final icon =
            widget.iconBuilder != null ? widget.iconBuilder!(item) : null;
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              : widget.label, // Show label as hint when null
          style: TextStyle(
            color: widget.value != null
                ? AppColors.textPrimary
                : AppColors.textSecondary, // Gray hint color when null
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
