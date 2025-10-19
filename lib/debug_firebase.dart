import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class FirebaseDebugger {
  static Future<void> debugFirebaseSetup() async {
    print("🔍 === FIREBASE DEBUG START ===");
    
    try {
      // 1. Test Firebase initialization
      print("1. Testing Firebase initialization...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Firebase initialized successfully");
      
      // 2. Test Auth instance
      print("2. Testing Firebase Auth...");
      FirebaseAuth auth = FirebaseAuth.instance;
      print("✅ Auth instance created");
      print("   - Current user: ${auth.currentUser?.uid ?? 'No user'}");
      
      // 3. Test Firestore instance
      print("3. Testing Firestore...");
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      print("✅ Firestore instance created");
      
      // 4. Test Firestore connection with a simple read
      print("4. Testing Firestore connection...");
      try {
        await firestore.collection('test').limit(1).get();
        print("✅ Firestore read test successful");
      } catch (e) {
        print("❌ Firestore read test failed: $e");
      }
      
      // 5. Test Firestore write (this might fail due to rules)
      print("5. Testing Firestore write...");
      try {
        await firestore.collection('test').doc('debug').set({
          'timestamp': FieldValue.serverTimestamp(),
          'message': 'Debug test',
        });
        print("✅ Firestore write test successful");
        
        // Clean up
        await firestore.collection('test').doc('debug').delete();
        print("✅ Test document cleaned up");
      } catch (e) {
        print("❌ Firestore write test failed: $e");
        print("   This might be due to Firestore security rules");
      }
      
      // 6. Test Auth sign up (this will fail if email exists)
      print("6. Testing Auth sign up...");
      try {
        final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final testPassword = 'testpassword123';
        
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        print("✅ Auth sign up test successful");
        print("   - User ID: ${userCredential.user?.uid}");
        
        // Clean up - delete test user
        await userCredential.user?.delete();
        print("✅ Test user cleaned up");
      } catch (e) {
        print("❌ Auth sign up test failed: $e");
      }
      
    } catch (e) {
      print("❌ Firebase setup failed: $e");
    }
    
    print("🔍 === FIREBASE DEBUG END ===");
  }
}








