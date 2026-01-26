import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      UserModel userModel;

      if (!userDoc.exists) {
        // Create new user in Firestore
        userModel = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName ?? 'User',
          photoURL: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestore());
      } else {
        // Load existing user and update profile data from Google
        userModel = UserModel.fromFirestore(userDoc);

        // Refresh profile data if changed
        if (userModel.photoURL != userCredential.user!.photoURL ||
            userModel.displayName != userCredential.user!.displayName) {
          userModel = userModel.copyWith(
            photoURL: userCredential.user!.photoURL,
            displayName: userCredential.user!.displayName,
          );
          await updateUserData(userModel);
        }
      }

      return userModel;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromFirestore(doc);

        // Always sync photoURL and displayName from current auth user
        final currentAuthUser = _auth.currentUser;
        if (currentAuthUser != null && currentAuthUser.uid == uid) {
          // Check if we need to update
          if (userModel.photoURL != currentAuthUser.photoURL ||
              userModel.displayName != currentAuthUser.displayName) {
            final updatedModel = userModel.copyWith(
              photoURL: currentAuthUser.photoURL,
              displayName: currentAuthUser.displayName ?? userModel.displayName,
            );
            // Update Firestore in background
            updateUserData(updatedModel);
            return updatedModel;
          }
        }

        return userModel;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(user.toFirestore());
    } catch (e) {
      debugPrint('Error updating user data: $e');
    }
  }

  // Update user XP and level
  Future<UserModel?> addXP(String uid, int xp) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;

      final user = UserModel.fromFirestore(userDoc);
      int newXP = user.xp + xp;
      int newLevel = user.level;

      // Check if leveled up
      while (newXP >= newLevel * 500) {
        newXP -= newLevel * 500;
        newLevel++;
      }

      final updatedUser = user.copyWith(xp: newXP, level: newLevel);
      await updateUserData(updatedUser);

      return updatedUser;
    } catch (e) {
      debugPrint('Error adding XP: $e');
      return null;
    }
  }

  // Update streak
  Future<void> updateStreak(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final user = UserModel.fromFirestore(userDoc);
      final updatedUser = user.copyWith(streak: user.streak + 1);
      await updateUserData(updatedUser);
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
    }
  }
}
