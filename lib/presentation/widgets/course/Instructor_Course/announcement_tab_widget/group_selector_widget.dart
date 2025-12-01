import 'package:flutter/material.dart';

/// Widget cho phép instructor chọn groups để gửi announcement
class GroupSelectorWidget extends StatefulWidget {
  final List<String> availableGroups;
  final List<String> selectedGroups;
  final ValueChanged<List<String>> onSelectionChanged;

  const GroupSelectorWidget({
    super.key,
    required this.availableGroups,
    required this.selectedGroups,
    required this.onSelectionChanged,
  });

  @override
  State<GroupSelectorWidget> createState() => _GroupSelectorWidgetState();
}

class _GroupSelectorWidgetState extends State<GroupSelectorWidget> {
  late List<String> _selectedGroups;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _selectedGroups = List.from(widget.selectedGroups);
    _selectAll = _selectedGroups.isEmpty || 
                 _selectedGroups.length == widget.availableGroups.length;
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedGroups.clear(); // Empty = all groups
      } else {
        _selectedGroups = List.from(widget.availableGroups);
      }
      widget.onSelectionChanged(_selectedGroups);
    });
  }

  void _toggleGroup(String groupId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedGroups.add(groupId);
      } else {
        _selectedGroups.remove(groupId);
      }
      
      // Update select all status
      _selectAll = _selectedGroups.isEmpty;
      
      widget.onSelectionChanged(_selectedGroups);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.people, color: Colors.indigo[400], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Target Groups *',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select which groups will receive this announcement',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Select All Option
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _selectAll 
                  ? Colors.indigo.withOpacity(0.2) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _selectAll 
                    ? Colors.indigo 
                    : Colors.grey.shade700,
                width: 1.5,
              ),
            ),
            child: CheckboxListTile(
              value: _selectAll,
              onChanged: _toggleSelectAll,
              title: const Text(
                'All Groups (Everyone in the course)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'This announcement will be visible to all ${widget.availableGroups.length} groups',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              activeColor: Colors.indigo,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.grey),
          const SizedBox(height: 12),

          // Individual Groups
          if (widget.availableGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No groups available in this course',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Column(
              children: widget.availableGroups.map((groupId) {
                final isSelected = !_selectAll && _selectedGroups.contains(groupId);
                final isDisabled = _selectAll;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.purple.withOpacity(0.15) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.purple 
                          : Colors.grey.shade800,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: isDisabled ? null : (value) => _toggleGroup(groupId, value),
                    title: Text(
                      groupId,
                      style: TextStyle(
                        color: isDisabled ? Colors.grey[600] : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Students in $groupId will receive this announcement',
                      style: TextStyle(
                        color: isDisabled ? Colors.grey[700] : Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                    activeColor: Colors.purple,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[400], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectAll
                        ? 'This announcement will be sent to ALL groups'
                        : _selectedGroups.isEmpty
                            ? 'Please select at least one group'
                            : 'Selected ${_selectedGroups.length} group(s): ${_selectedGroups.join(", ")}',
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontSize: 12,
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
}