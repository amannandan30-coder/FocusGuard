import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<void> signInWithEmail({required String email, required String password});
  Future<void> registerWithEmail({required String email, required String password, required String displayName});
  Future<void> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}
