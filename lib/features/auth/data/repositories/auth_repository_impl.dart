import 'dart:async';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource? localDataSource;
  UserEntity? _cachedUser;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  }) {
    _cachedUser = localDataSource?.getUser();
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    final user = await remoteDataSource.login(email, password);
    _cachedUser = user;
    if (localDataSource != null) {
      await localDataSource!.saveUser(user);
    }
    return user;
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return await remoteDataSource.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  @override
  Future<UserEntity> verifyRegistrationEmail(String email, String code) async {
    final user = await remoteDataSource.verifyRegistrationEmail(email, code);
    _cachedUser = user;
    if (localDataSource != null) {
      await localDataSource!.saveUser(user);
    }
    return user;
  }

  @override
  Future<Map<String, dynamic>> resendRegistrationVerification(String email) async {
    return await remoteDataSource.resendRegistrationVerification(email);
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await remoteDataSource.forgotPassword(email);
  }

  @override
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    return await remoteDataSource.verifyResetCode(email, code);
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await remoteDataSource.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }

  @override
  Future<UserEntity> loginWithGoogle({
    required String accessToken,
    String? idToken,
    String? email,
    String? name,
    String? avatar,
  }) async {
    final user = await remoteDataSource.loginWithGoogle(
      accessToken: accessToken,
      idToken: idToken,
      email: email,
      name: name,
      avatar: avatar,
    );
    _cachedUser = user;
    if (localDataSource != null) {
      await localDataSource!.saveUser(user);
    }
    return user;
  }

  @override
  Future<UserEntity> updateProfile({
    required String token,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updatedUser = await remoteDataSource.updateProfile(
        token: token,
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      final tokenToKeep = (updatedUser.token != null && updatedUser.token!.isNotEmpty)
          ? updatedUser.token
          : token;
      final mergedUser = updatedUser.copyWith(token: tokenToKeep);
      await saveUser(mergedUser);
      return mergedUser;
    } catch (_) {
      if (_cachedUser != null) {
        final localUpdated = _cachedUser!.copyWith(
          name: name ?? _cachedUser!.name,
          phone: phone ?? _cachedUser!.phone,
          avatarUrl: avatarUrl ?? _cachedUser!.avatarUrl,
        );
        await saveUser(localUpdated);
        return localUpdated;
      }
      rethrow;
    }
  }

  @override
  Future<void> saveUser(UserEntity user) async {
    _cachedUser = user;
    if (localDataSource != null) {
      final model = user is UserModel
          ? user
          : UserModel(
              id: user.id,
              name: user.name,
              email: user.email,
              phone: user.phone,
              role: user.role,
              token: user.token,
              avatarUrl: user.avatarUrl,
              isVerified: user.isVerified,
            );
      await localDataSource!.saveUser(model);
    }
  }

  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  void notifySessionExpired() {
    _cachedUser = null;
    localDataSource?.clearUser();
    if (!_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }
  }

  @override
  Future<String?> refreshToken() async {
    // If backend provides a refresh-token flow, it would be called here.
    // For now, return current cached user token if valid, or null.
    final token = _cachedUser?.token;
    if (token != null && token.isNotEmpty) {
      return token;
    }
    return null;
  }

  @override
  Future<void> logout() async {
    _cachedUser = null;
    if (localDataSource != null) {
      await localDataSource!.clearUser();
    }
  }

  @override
  UserEntity? getCachedUser() => _cachedUser ?? localDataSource?.getUser();
}
