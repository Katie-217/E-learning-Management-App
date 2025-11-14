import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/group_provider.dart';

class GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool isTeacher;
  const GroupCard({super.key, required this.group, this.isTeacher = false});

  @override
  Widget build(BuildContext context) {
    final members = group["members"] as List<dynamic>;

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(group["name"],
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${group["course"]} • ${members.length} members",
          style: const TextStyle(color: Colors.grey),
        ),
        children: [
          for (var member in members)
            ListTile(
              leading: const Icon(Icons.person, color: Colors.cyanAccent),
              title: Text(member["name"],
                  style: const TextStyle(color: Colors.white)),
              trailing: isTeacher
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle,
                          color: Colors.redAccent),
                      onPressed: () {
                        // ref.read(groupProvider.notifier).removeMember(group["id"], member["id"]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Remove member feature coming soon')),
                        );
                      },
                    )
                  : null,
            )
        ],
      ),
    );
  }
}
