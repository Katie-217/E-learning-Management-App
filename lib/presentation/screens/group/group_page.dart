//danh sách nhóm (dùng chung)
import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/group_provider.dart';
// import '../widgets/group_card.dart';

class GroupsPage extends StatelessWidget {
  final bool isTeacher;
  const GroupsPage({super.key, this.isTeacher = false});

  @override
  Widget build(BuildContext context) {
    // final groupsAsync = ref.watch(groupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Groups"),
        backgroundColor: Colors.black,
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () {
                Navigator.pushNamed(context, '/manage-group');
              },
            )
        ],
      ),
      backgroundColor: Colors.black,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Groups feature coming soon', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}




















