// FILE: admin_cleanup_screen.dart
// DESCRIPTION: Admin screen for safely cleaning up test users

import 'package:flutter/material.dart';
import '../../../core/utils/cleanup_test_users.dart';

class AdminCleanupScreen extends StatefulWidget {
  const AdminCleanupScreen({super.key});

  @override
  State<AdminCleanupScreen> createState() => _AdminCleanupScreenState();
}

class _AdminCleanupScreenState extends State<AdminCleanupScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>>? _previewUsers;
  Map<String, int>? _cleanupResults;

  Future<void> _previewCleanup() async {
    setState(() => _isLoading = true);

    try {
      final cleanup = UserCleanupService();
      final users = await cleanup.previewUsersToDelete();

      setState(() {
        _previewUsers = users;
        _cleanupResults = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _executeCleanup() async {
    if (_previewUsers == null || _previewUsers!.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirm Deletion'),
        content: Text(
            'This will permanently delete ${_previewUsers!.length} users from Firestore.\n\n'
            'This action CANNOT be undone!\n\n'
            'Are you absolutely sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final cleanup = UserCleanupService();
      final results = await cleanup.executeCleanup(_previewUsers!);

      setState(() {
        _cleanupResults = results;
        _previewUsers = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cleanup completed: ${results['firestoreDeleted']} users deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧹 Admin User Cleanup'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Card
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          'DANGER ZONE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool will delete bulk imported test users.\n'
                      'Protected accounts (admin@gmail.com, instructors) will NOT be deleted.\n'
                      'Always preview before executing!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _previewCleanup,
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview Users to Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_previewUsers != null && !_isLoading)
                        ? _executeCleanup
                        : null,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Execute Cleanup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Processing...'),
                  ],
                ),
              ),

            // Preview Results
            if (_previewUsers != null && !_isLoading) ...[
              Text(
                '📋 Users to be deleted: ${_previewUsers!.length}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: _previewUsers!.length,
                    itemBuilder: (context, index) {
                      final user = _previewUsers![index];
                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.red),
                        title: Text(user['email'] ?? 'Unknown'),
                        subtitle:
                            Text('${user['name']} - Role: ${user['role']}'),
                        trailing: const Icon(Icons.delete, color: Colors.red),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Cleanup Results
            if (_cleanupResults != null && !_isLoading) ...[
              const Text(
                '✅ Cleanup Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '🗑️ Firestore deletions: ${_cleanupResults!['firestoreDeleted']}'),
                      Text(
                          '🔐 Auth deletions: ${_cleanupResults!['authDeleted']}'),
                      Text('❌ Errors: ${_cleanupResults!['errors']}'),
                      const SizedBox(height: 12),
                      const Divider(),
                      const Text(
                        '⚠️ Manual Firebase Auth Cleanup Required:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Go to Firebase Console > Authentication\n'
                        '2. Search for test user emails (student1@gmail.com, etc.)\n'
                        '3. Select and delete users manually\n'
                        '4. DO NOT delete admin@gmail.com or instructor accounts!',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
