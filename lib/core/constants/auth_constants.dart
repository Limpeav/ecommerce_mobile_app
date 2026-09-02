import 'api_constants.dart';

class AuthConstants {
  static const String login = '${ApiConstants.baseUrl}/api/users/login';
  static const String register = '${ApiConstants.baseUrl}/api/users/register';
  static const String verifyRegistrationEmail =
      '${ApiConstants.baseUrl}/api/users/verify-registration-email';
  static const String resendRegistrationVerification =
      '${ApiConstants.baseUrl}/api/users/resend-registration-verification';
  static const String forgotPassword = '${ApiConstants.baseUrl}/api/users/forgot-password';
  static const String verifyResetCode = '${ApiConstants.baseUrl}/api/users/verify-reset-code';
  static const String resetPassword = '${ApiConstants.baseUrl}/api/users/reset-password';
  static const String updateProfile = '${ApiConstants.baseUrl}/api/users/profile';
  static const String googleLogin = '${ApiConstants.baseUrl}/api/auth/google';
  static const String googleServerClientId =
      '114319681725-8fku26naudiu0ved83vrrllpb0q95tss.apps.googleusercontent.com';
  static const String googleIosClientId =
      '114319681725-s9lh8honou0fklulla6fsqe2v79ur45h.apps.googleusercontent.com';
}


