import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DefaultAccountSeeder {
  static const _accounts = [
    _DefaultAccount(
      username: 'admin',
      email: 'admin@demo.local',
      password: 'admin',
      role: 'instructor',
      displayName: 'Admin Instructor',
    ),
    _DefaultAccount(
      username: 'student',
      email: 'student@demo.local',
      password: 'student',
      role: 'student',
      displayName: 'Student Learner',
    ),
  ];

  static Future<void> ensureDefaults() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    for (final account in _accounts) {
      try {
        final credential = await auth.signInWithEmailAndPassword(
          email: account.email,
          password: account.password,
        );
        await _upsertUserDoc(
          firestore,
          credential.user!,
          account,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          final credential = await auth.createUserWithEmailAndPassword(
            email: account.email,
            password: account.password,
          );
          await credential.user?.updateDisplayName(account.displayName);
          await _upsertUserDoc(
            firestore,
            credential.user!,
            account,
          );
        } else if (e.code == 'wrong-password') {
          // Ensure Firestore doc still exists even if password changed manually
          final snapshot = await _findUserByEmail(firestore, account.email);
          if (snapshot != null) {
            await snapshot.reference.set({
              'role': account.role,
              'username': account.username,
              'displayName': account.displayName,
            }, SetOptions(merge: true));
          }
        }
      } catch (_) {
        // ignore errors to avoid blocking app start
      } finally {
        await auth.signOut();
      }
    }
  }

  static Future<void> _upsertUserDoc(
    FirebaseFirestore firestore,
    User user,
    _DefaultAccount account,
  ) async {
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': account.email,
      'username': account.username,
      'displayName': account.displayName,
      'role': account.role,
      'createdAt': FieldValue.serverTimestamp(),
      'settings': {
        'language': 'vi',
        'theme': 'light',
        'status': 'active',
      },
    }, SetOptions(merge: true));
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?> _findUserByEmail(
    FirebaseFirestore firestore,
    String email,
  ) async {
    final snapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
  }
}

class _DefaultAccount {
  final String username;
  final String email;
  final String password;
  final String role;
  final String displayName;

  const _DefaultAccount({
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.displayName,
  });
}

