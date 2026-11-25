import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/activity.dart';
import '../models/routine_blueprint.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class FirebaseSyncService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  FirebaseSyncService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser?.isAnonymous == false;

  User _requireRegisteredUser() {
    final user = currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Masuk ke akun untuk menyinkronkan data.');
    }
    return user;
  }

  /// Real Sign in with Google (Web & Mobile)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final cred = await _auth.signInWithPopup(googleProvider);
        debugPrint('Firebase Google Sign-In succeeded.');
        return cred;
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null;
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final cred = await _auth.signInWithCredential(credential);
        debugPrint('Firebase Google Sign-In succeeded.');
        return cred;
      }
    } catch (e) {
      debugPrint('Firebase signInWithGoogle failed (${e.runtimeType}).');
      rethrow;
    }
  }

  /// Sign in with Email & Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Firebase signInWithEmail failed (${e.runtimeType}).');
      rethrow;
    }
  }

  /// Register with Email & Password
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Firebase registerWithEmail failed (${e.runtimeType}).');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Firebase signOut failed (${e.runtimeType}).');
      rethrow;
    }
  }

  /// Sync an Activity to Firestore
  Future<void> syncActivity(Activity activity) async {
    final user = _requireRegisteredUser();

    try {
      final docRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .doc('${activity.id}');

      await docRef.set({
        'id': activity.id,
        'habitId': activity.habitId,
        'title': activity.title,
        'description': activity.description,
        'startMinute': activity.startMinute,
        'endMinute': activity.endMinute,
        'ampmHalf': activity.ampmHalf.index,
        'date': activity.date.toIso8601String(),
        'colorValue': activity.colorValue,
        'iconKey': activity.iconKey,
        'recurrence': activity.recurrence,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firebase syncActivity failed (${e.runtimeType}).');
      rethrow;
    }
  }

  /// Sync a RoutineBlueprint to Firestore
  Future<void> syncBlueprint(RoutineBlueprint blueprint) async {
    final user = _requireRegisteredUser();

    try {
      final docRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('blueprints')
          .doc('${blueprint.id}');

      await docRef.set(blueprint.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firebase syncBlueprint failed (${e.runtimeType}).');
      rethrow;
    }
  }

  /// Stream of user activities from Firestore
  Stream<List<Map<String, dynamic>>> streamActivities() {
    final user = currentUser;
    if (user == null || user.isAnonymous) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}

final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  return FirebaseSyncService(
    auth: ref.watch(firebaseAuthProvider),
    db: ref.watch(firestoreProvider),
  );
});
