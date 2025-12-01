import 'package:flutter/material.dart';

class ChooseGroupCreate extends StatefulWidget {
  final List<String> availableGroups;
  final List<String> selectedGroups;
  final Function(List<String>) onSelectionChanged;
  final FormFieldValidator<String>? validator;

  const ChooseGroupCreate({
    super.key,
    required this.availableGroups,
    required this.selectedGroups,
    required this.onSelectionChanged,
    this.validator,
  });

  @override
  State<ChooseGroupCreate> createState() => _ChooseGroupCreateState();
}

class _ChooseGroupCreateState extends State<ChooseGroupCreate> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FormFieldState> _formKey = GlobalKey<FormFieldState>();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _filteredGroups = [];
  List<String> _tempSelectedGroups = [];
  bool _isMenuOpen = false;
  bool _hasInteracted = false; // Track if user has interacted

  @override
  void initState() {
    super.initState();
    _filteredGroups = List.from(widget.availableGroups);
    _tempSelectedGroups = List.from(widget.selectedGroups);

    _searchController.addListener(_filterGroups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _hideOverlay();
    } else {
      _showOverlay();
      _focusNode.requestFocus();
    }
  }

  void _filterGroups() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredGroups = List.from(widget.availableGroups);
      } else {
        _filteredGroups = widget.availableGroups
            .where((group) => group.toLowerCase().contains(query))
            .toList();
      }
    });
    _updateOverlay();
  }

  void _showOverlay() {
    if (_isMenuOpen) return;

    _isMenuOpen = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (!_isMenuOpen) return;

    _isMenuOpen = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _focusNode.unfocus();
    setState(() {});
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Don't close when clicking inside menu
        },
        child: Stack(
          children: [
            // Invisible barrier to detect outside clicks
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            // The actual menu
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height + 5.0),
                child: Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF1E293B),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 180, // ~3 items height
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!, width: 1.5),
                    ),
                    child: _filteredGroups.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No groups found',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            itemCount: _filteredGroups.length,
                            itemBuilder: (context, index) {
                              final group = _filteredGroups[index];
                              final isSelected =
                                  _tempSelectedGroups.contains(group);
                              final isAllGroups = group == 'All Groups';

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _handleGroupSelection(
                                        group, isSelected, isAllGroups);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.indigo
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.indigo
                                                  : Colors.grey[600]!,
                                              width: 2,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            group,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGroupSelection(String group, bool isSelected, bool isAllGroups) {
    _hasInteracted = true;
    setState(() {
      if (isAllGroups) {
        if (isSelected) {
          _tempSelectedGroups.clear();
        } else {
          _tempSelectedGroups = List.from(widget.availableGroups);
        }
      } else {
        if (isSelected) {
          _tempSelectedGroups.remove(group);
          _tempSelectedGroups.remove('All Groups');
        } else {
          _tempSelectedGroups.add(group);
          // Check if all groups selected
          if (_tempSelectedGroups.length == widget.availableGroups.length - 1 &&
              !_tempSelectedGroups.contains('All Groups')) {
            _tempSelectedGroups.add('All Groups');
          }
        }
      }
      widget.onSelectionChanged(List.from(_tempSelectedGroups));
      // Trigger validation to update error state
      Future.microtask(() => _formKey.currentState?.validate());
    });
    _updateOverlay();
  }

  String _getDisplayText() {
    if (_tempSelectedGroups.isEmpty) {
      return '';
    } else if (_tempSelectedGroups.contains('All Groups')) {
      return 'All Groups';
    } else if (_tempSelectedGroups.length == 1) {
      return _tempSelectedGroups.first;
    } else {
      return _tempSelectedGroups.join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (!_isMenuOpen) {
            _toggleMenu();
          }
        },
        child: AbsorbPointer(
          absorbing: false, // Allow suffix icons to receive taps
          child: Form(
            key: _formKey,
            child: TextFormField(
              controller: _searchController,
              focusNode: _focusNode,
              readOnly: false, // Allow typing to search groups
              onChanged: (value) {
                _filterGroups();
                if (!_isMenuOpen) {
                  _showOverlay();
                }
              },
              style: const TextStyle(color: Colors.white, fontSize: 14),
              autovalidateMode: _hasInteracted
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              decoration: InputDecoration(
                hintText: _tempSelectedGroups.isEmpty
                    ? 'Choose groups...'
                    : _getDisplayText(),
                hintStyle: TextStyle(
                  color: _tempSelectedGroups.isEmpty
                      ? Colors.grey[600]
                      : Colors.white,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                prefixIcon: Icon(
                  Icons.groups_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                suffixIcon: _tempSelectedGroups.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                print('DEBUG: X button clicked!');
                                _hasInteracted = true;
                                setState(() {
                                  _tempSelectedGroups.clear();
                                  _searchController.clear();
                                  widget.onSelectionChanged([]);
                                });
                                Future.microtask(
                                    () => _formKey.currentState?.validate());
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.clear,
                                    size: 18, color: Colors.grey[400]),
                              ),
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _toggleMenu,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  _isMenuOpen
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _toggleMenu,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _isMenuOpen
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: widget.validator ??
                  (value) {
                    if (_tempSelectedGroups.isEmpty) {
                      return 'Please select at least one group';
                    }
                    return null;
                  },
            ),
          ),
        ),
      ),
    );
  }
}
