// FILE: cleanup_test_users.dart
// DESCRIPTION: Utility to safely clean up bulk imported test users while preserving important accounts

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class UserCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Protected accounts that should NEVER be deleted
  static const List<String> protectedEmails = [
    'admin@gmail.com',
    // Add any other important admin/instructor emails here
  ];

  // Protected roles that should NEVER be deleted
  static const List<String> protectedRoles = [
    'Instructor', // Your important user role
    'instructor',
    'admin',
    'Admin',
  ];

  // Preview users that will be deleted (for confirmation)
  Future<List<Map<String, dynamic>>> previewUsersToDelete({
    bool dryRun = true,
    List<String> emailPatterns = const ['student', '@test.com', '@gmail.com'],
  }) async {
    print('🔍 CLEANUP: Starting user cleanup preview...');

    final usersToDelete = <Map<String, dynamic>>[];
    final protectedUsers = <Map<String, dynamic>>[];

    try {
      // Get all users from Firestore
      final usersSnapshot = await _firestore.collection('users').get();

      print(
          '📊 CLEANUP: Found ${usersSnapshot.docs.length} total users in Firestore');

      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();
        final email = userData['email']?.toString() ?? '';
        final role = userData['role']?.toString() ?? 'student';
        final name = userData['name']?.toString() ?? 'Unknown';
        final uid = userData['uid']?.toString() ?? doc.id;

        // Check if user should be protected
        final isProtectedEmail = protectedEmails.contains(email.toLowerCase());
        final isProtectedRole = protectedRoles.contains(role.toLowerCase());

        if (isProtectedEmail || isProtectedRole) {
          protectedUsers.add({
            'uid': uid,
            'email': email,
            'name': name,
            'role': role,
            'reason': isProtectedEmail ? 'Protected Email' : 'Protected Role',
          });
          continue;
        }

        // Check if user matches deletion patterns
        final matchesPattern = emailPatterns.any(
            (pattern) => email.toLowerCase().contains(pattern.toLowerCase()));

        if (matchesPattern) {
          usersToDelete.add({
            'uid': uid,
            'email': email,
            'name': name,
            'role': role,
            'docId': doc.id,
          });
        }
      }

      // Print summary
      print('\n📋 CLEANUP SUMMARY:');
      print('   🛡️  Protected users: ${protectedUsers.length}');
      print('   🗑️  Users to delete: ${usersToDelete.length}');

      print('\n🛡️  PROTECTED USERS (will NOT be deleted):');
      for (final user in protectedUsers) {
        print(
            '   - ${user['email']} (${user['name']}) - Role: ${user['role']} - ${user['reason']}');
      }

      print('\n🗑️  USERS TO BE DELETED:');
      for (int i = 0; i < usersToDelete.length && i < 20; i++) {
        // Show first 20
        final user = usersToDelete[i];
        print(
            '   - ${user['email']} (${user['name']}) - Role: ${user['role']}');
      }

      if (usersToDelete.length > 20) {
        print('   ... and ${usersToDelete.length - 20} more users');
      }

      return usersToDelete;
    } catch (e) {
      print('❌ CLEANUP ERROR: $e');
      return [];
    }
  }

  // Execute the cleanup (delete users from both Firestore and Firebase Auth)
  Future<Map<String, int>> executeCleanup(
      List<Map<String, dynamic>> usersToDelete) async {
    print('\n🚀 CLEANUP: Starting deletion process...');

    int firestoreDeleted = 0;
    int authDeleted = 0;
    int errors = 0;

    // Create secondary app for admin operations
    FirebaseApp? adminApp;
    try {
      final currentOptions = Firebase.app().options;
      try {
        adminApp = Firebase.app('AdminApp');
      } catch (e) {
        adminApp = await Firebase.initializeApp(
          name: 'AdminApp',
          options: currentOptions,
        );
      }
    } catch (e) {
      print('❌ CLEANUP: Failed to create admin app: $e');
      return {'firestoreDeleted': 0, 'authDeleted': 0, 'errors': errors + 1};
    }

    for (int i = 0; i < usersToDelete.length; i++) {
      final user = usersToDelete[i];
      final email = user['email'];
      final uid = user['uid'];
      final docId = user['docId'];

      print(
          '🗑️  CLEANUP: Deleting user ${i + 1}/${usersToDelete.length}: $email');

      try {
        // Step 1: Delete from Firestore
        await _firestore.collection('users').doc(docId).delete();
        firestoreDeleted++;
        print('   ✅ Firestore: Deleted user document');

        // Step 2: Firebase Auth deletion note
        print(
            '   ⚠️  Auth: Not deleted (requires manual deletion from Firebase Console)');
        print('   📝 Auth deletion instructions:');
        print('      1. Go to Firebase Console > Authentication');
        print('      2. Search for: $email');
        print('      3. Select user and delete manually');
      } catch (e) {
        print('   ❌ Error deleting user $email: $e');
        errors++;
      }

      // Small delay to avoid overwhelming Firebase
      if (i % 10 == 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    print('\n📊 CLEANUP RESULTS:');
    print('   🗑️  Firestore deletions: $firestoreDeleted');
    print('   🔐 Auth deletions: $authDeleted');
    print('   ❌ Errors: $errors');

    return {
      'firestoreDeleted': firestoreDeleted,
      'authDeleted': authDeleted,
      'errors': errors,
    };
  }

  // Full cleanup workflow with confirmation
  Future<void> safeCleanup() async {
    print('🧹 STARTING SAFE USER CLEANUP...\n');

    // Step 1: Preview
    final usersToDelete = await previewUsersToDelete();

    if (usersToDelete.isEmpty) {
      print('\n✅ No users found matching deletion criteria.');
      return;
    }

    print(
        '\n⚠️  WARNING: This will permanently delete ${usersToDelete.length} users!');
    print('💡 Review the list above carefully before proceeding.\n');

    // In a real Flutter app, you'd show a confirmation dialog here
    // For now, we'll add a simple delay
    print('⏱️  Waiting 5 seconds before proceeding...');
    await Future.delayed(const Duration(seconds: 5));

    // Step 2: Execute
    final results = await executeCleanup(usersToDelete);

    print('\n🎉 CLEANUP COMPLETED!');
    print(
        'Summary: ${results['firestoreDeleted']} users deleted from Firestore');
    if (results['errors']! > 0) {
      print('⚠️  ${results['errors']} errors occurred during cleanup');
    }
  }
}

// Standalone function to run cleanup
Future<void> runUserCleanup() async {
  final cleanup = UserCleanupService();
  await cleanup.safeCleanup();
}
