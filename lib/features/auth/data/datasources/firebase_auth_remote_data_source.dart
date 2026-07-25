import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/app_user.dart';
import '../models/user_profile_model.dart';

class FirebaseAuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toAppUser);

  Future<void> signInWithEmail({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> registerWithEmail({required String email, required String password, required String displayName}) async {
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await credential.user?.updateDisplayName(displayName.trim());
    final User? user = _auth.currentUser;
    if (user != null) {
      await _upsertProfile(_toAppUser(user)!);
    }
  }

  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      return;
    }
    final GoogleSignInAuthentication googleAuth = await account.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential result = await _auth.signInWithCredential(credential);
    if (result.user != null) {
      await _upsertProfile(_toAppUser(result.user!)!);
    }
  }

  Future<void> sendPasswordResetEmail(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> _upsertProfile(AppUser user) async {
    final DocumentReference<Map<String, dynamic>> reference = _firestore.collection('users').doc(user.id);
    final DocumentSnapshot<Map<String, dynamic>> existing = await reference.get();
    final DateTime? createdAt = existing.data()?['createdAt'] is Timestamp
        ? (existing.data()!['createdAt'] as Timestamp).toDate()
        : null;
    await reference.set(UserProfileModel.fromUser(user, createdAt: createdAt).toJson(), SetOptions(merge: true));
  }

  AppUser? _toAppUser(User? user) => user == null
      ? null
      : AppUser(id: user.uid, email: user.email, displayName: user.displayName, photoUrl: user.photoURL);
}
