import '../../../../core/constants/auth_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<UserModel> verifyRegistrationEmail(String email, String code);
  Future<Map<String, dynamic>> resendRegistrationVerification(String email);
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<Map<String, dynamic>> verifyResetCode(String email, String code);
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  });
  Future<UserModel> loginWithGoogle({
    required String accessToken,
    String? idToken,
    String? email,
    String? name,
    String? avatar,
  });
  Future<UserModel> updateProfile({
    required String token,
    String? name,
    String? phone,
    String? avatarUrl,
  });
  Future<UserModel> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await apiClient.post(
      AuthConstants.login,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    if (response is Map<String, dynamic>) {
      if (response['requiresEmailVerification'] == true) {
        throw Exception(
          response['message'] ?? 'Please verify your email before logging in.',
        );
      }
      return UserModel.fromJson(response);
    }
    throw Exception('Invalid server response during login');
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await apiClient.post(
      AuthConstants.register,
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw Exception('Invalid server response during registration');
  }

  @override
  Future<UserModel> verifyRegistrationEmail(String email, String code) async {
    final response = await apiClient.post(
      AuthConstants.verifyRegistrationEmail,
      body: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      },
    );

    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Invalid verification code. Please check the code and try again.');
  }

  @override
  Future<Map<String, dynamic>> resendRegistrationVerification(String email) async {
    final response = await apiClient.post(
      AuthConstants.resendRegistrationVerification,
      body: {
        'email': email.trim().toLowerCase(),
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw Exception('Failed to resend verification code');
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await apiClient.post(
      AuthConstants.forgotPassword,
      body: {
        'email': email.trim().toLowerCase(),
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw Exception('Invalid server response for forgot password');
  }

  @override
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    final response = await apiClient.post(
      AuthConstants.verifyResetCode,
      body: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw Exception('Invalid verification code');
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await apiClient.post(
      AuthConstants.resetPassword,
      body: {
        'token': token.trim(),
        'password': newPassword,
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw Exception('Failed to reset password');
  }

  @override
  Future<UserModel> loginWithGoogle({
    required String accessToken,
    String? idToken,
    String? email,
    String? name,
    String? avatar,
  }) async {
    final response = await apiClient.post(
      AuthConstants.googleLogin,
      body: {
        'accessToken': accessToken,
        if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
        'token': accessToken,
        if (email != null && email.isNotEmpty) 'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
        if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
        if (avatar != null && avatar.isNotEmpty) 'picture': avatar,
      },
    );

    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Invalid server response from Google authentication');
  }

  @override
  Future<UserModel> updateProfile({
    required String token,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final response = await apiClient.put(
      AuthConstants.updateProfile,
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        if (name != null && name.isNotEmpty) 'name': name.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl.trim(),
      },
    );

    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Invalid server response from update profile');
  }

  @override
  Future<UserModel> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await apiClient.put(
      AuthConstants.updateProfile,
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'password': newPassword,
        'currentPassword': currentPassword,
        'oldPassword': currentPassword,
      },
    );

    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Invalid server response from change password');
  }
}
