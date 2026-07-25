import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/datasources/firebase_auth_remote_data_source.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final Provider<FirebaseAuth> firebaseAuthProvider = Provider<FirebaseAuth>((Ref ref) => FirebaseAuth.instance);
final Provider<FirebaseFirestore> firestoreProvider = Provider<FirebaseFirestore>((Ref ref) => FirebaseFirestore.instance);
const _googleWebClientId = '1002253558776-bek4d1o203c8ncfgh9lvutvau1kh4rds.apps.googleusercontent.com';

final Provider<GoogleSignIn> googleSignInProvider = Provider<GoogleSignIn>(
  (Ref ref) => GoogleSignIn(clientId: kIsWeb ? _googleWebClientId : null),
);

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return FirebaseAuthRepository(FirebaseAuthRemoteDataSource(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  ));
});

final StreamProvider<AppUser?> authStateProvider = StreamProvider<AppUser?>((Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repository) : super(const AsyncData<void>(null));
  final AuthRepository _repository;

  Future<void> signIn(String email, String password) => _run(() => _repository.signInWithEmail(email: email, password: password));
  Future<void> register(String email, String password, String name) => _run(() => _repository.registerWithEmail(email: email, password: password, displayName: name));
  Future<void> signInWithGoogle() => _run(_repository.signInWithGoogle);
  Future<void> resetPassword(String email) => _run(() => _repository.sendPasswordResetEmail(email));
  Future<void> signOut() => _run(_repository.signOut);

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(action);
  }
}

final StateNotifierProvider<AuthController, AsyncValue<void>> authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((Ref ref) => AuthController(ref.watch(authRepositoryProvider)));
