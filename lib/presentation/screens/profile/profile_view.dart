import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
            SizedBox(height: 16),
            Text('Username: admin'),
            Text('Role: Instructor/Student'),
          ],
        ),
      ),
    );
  }
}
