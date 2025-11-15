import 'package:flutter/material.dart';

class SidebarWidget extends StatefulWidget {
  final void Function(String key)? onSelect;
  final String activeKey;

  const SidebarWidget({super.key, this.onSelect, this.activeKey = 'dashboard'});

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SidebarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeKey != widget.activeKey) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sideWidth = 260.0;

    return Container(
      width: sideWidth,
      color: const Color(0xFF111827),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 10),
          _buildSidebarItem(
            icon: Icons.trending_up,
            title: 'Dashboard',
            isSelected: widget.activeKey == 'dashboard',
            onTap: () => widget.onSelect?.call('dashboard'),
          ),
          _buildSidebarItem(
            icon: Icons.book,
            title: 'Courses',
            isSelected: widget.activeKey == 'courses',
            onTap: () => widget.onSelect?.call('courses'),
          ),
          // const ListTile(
          //   leading: Icon(Icons.assignment),
          //   title: Text('Assignments'),
          // ),
          // const ListTile(
          //   leading: Icon(Icons.emoji_events),
          //   title: Text('Grades'),
          // ),
          // const ListTile(
          //   leading: Icon(Icons.people),
          //   title: Text('Forums'),
          // ),
          // const ListTile(
          //   leading: Icon(Icons.video_library),
          //   title: Text('Materials'),
          // ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purple.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
      child: ListTile(
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Icon(
            icon,
            color: isSelected
                ? Colors.purple
                : Colors.white.withOpacity(0.7),
            size: 24,
          ),
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          child: Text(title),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}
