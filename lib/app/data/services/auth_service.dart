import 'package:duniakopi_project/app/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      // Step 1: Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('User created in Auth: ${userCredential.user!.uid}');

      // Step 2: Create user document in Firestore
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        role: 'customer', // Default role
      );

      try {
        await _db.collection('users').doc(userCredential.user!.uid).set(newUser.toMap());
        debugPrint('User document created in Firestore');
      } catch (firestoreError) {
        debugPrint('Firestore write error: $firestoreError');
        // If Firestore fails, delete the auth user to maintain consistency
        await userCredential.user!.delete();
        throw Exception('Gagal menyimpan data pengguna: $firestoreError');
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Helper method to check if user document exists
  Future<bool> userDocumentExists(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking user document: $e');
      return false;
    }
  }

  // Helper method to create missing user document
  Future<void> createUserDocument(User user) async {
    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          role: 'customer',
        );
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
        debugPrint('Created missing user document for ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        return doc.data()?['role'] ?? 'customer';
      } else {
        // If document doesn't exist, create it
        debugPrint('User document not found, creating...');
        await ref.read(authServiceProvider).createUserDocument(user);
        return 'customer';
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }
  return null;
});