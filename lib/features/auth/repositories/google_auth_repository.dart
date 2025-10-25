import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/config/users-role.dart';

class GoogleAuthRepository {
  static GoogleAuthRepository? _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GoogleAuthRepository._internal();
  
  static GoogleAuthRepository defaultClient() {
    _instance ??= GoogleAuthRepository._internal();
    return _instance!;
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled the login
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Save user data to Firestore if new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'role': UserRole.student.name, // Default role
          'createdAt': FieldValue.serverTimestamp(),
          'photoURL': userCredential.user!.photoURL,
        });
      }
      
      return userCredential.user;
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Check if user is signed in with Google
  bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }
}

// final googleAuthRepositoryProvider = Provider<GoogleAuthRepository>((ref) {
//   return GoogleAuthRepository.defaultClient();
// });



