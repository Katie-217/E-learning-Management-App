import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  final String activeTab;
  final Function(String tab) onTabSelected;

  const SidebarWidget({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF111827),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildSidebarItem('Dashboard', Icons.dashboard, 'dashboard'),
          _buildSidebarItem('Teaching', Icons.book, 'courses'),
          _buildSidebarItem('Students', Icons.people, 'students'),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String label, IconData icon, String tabKey) {
    final bool isActive = activeTab == tabKey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.indigo[600]?.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: Colors.indigo[600]!, width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.indigo[400] : Colors.grey[400],
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[300],
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => onTabSelected(tabKey),
      ),
    );
  }
}
