import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_remote_data_source.dart';

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._remoteDataSource);

  final FirebaseAuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> authStateChanges() => _remoteDataSource.authStateChanges();

  @override
  Future<void> registerWithEmail({required String email, required String password, required String displayName}) =>
      _remoteDataSource.registerWithEmail(email: email, password: password, displayName: displayName);

  @override
  Future<void> sendPasswordResetEmail(String email) => _remoteDataSource.sendPasswordResetEmail(email);

  @override
  Future<void> signInWithEmail({required String email, required String password}) =>
      _remoteDataSource.signInWithEmail(email: email, password: password);

  @override
  Future<void> signInWithGoogle() => _remoteDataSource.signInWithGoogle();

  @override
  Future<void> signOut() => _remoteDataSource.signOut();
}
