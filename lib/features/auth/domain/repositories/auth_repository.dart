import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<UserEntity> verifyRegistrationEmail(String email, String code);
  Future<Map<String, dynamic>> resendRegistrationVerification(String email);
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<Map<String, dynamic>> verifyResetCode(String email, String code);
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  });
  Future<UserEntity> loginWithGoogle({
    required String accessToken,
    String? idToken,
    String? email,
    String? name,
    String? avatar,
  });
  Future<UserEntity> updateProfile({
    required String token,
    String? name,
    String? phone,
    String? avatarUrl,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> saveUser(UserEntity user);
  Future<void> logout();
  UserEntity? getCachedUser();
  Future<String?> refreshToken();
  Stream<void> get sessionExpiredStream;
}
