import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/auth_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  late final GoogleSignIn _googleSignIn;

  AuthBloc({required this.authRepository})
      : super(const AuthState()) {
    _googleSignIn = GoogleSignIn(
      clientId: AuthConstants.googleIosClientId,
      serverClientId: AuthConstants.googleServerClientId,
      scopes: ['email', 'profile'],
    );

    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthGoogleSignInRequested>(_onAuthGoogleSignInRequested);
    on<AuthGoogleTokenLoginRequested>(_onAuthGoogleTokenLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthVerifyRegistrationEmailRequested>(_onAuthVerifyRegistrationEmailRequested);
    on<AuthResendVerificationRequested>(_onAuthResendVerificationRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthVerifyResetCodeRequested>(_onAuthVerifyResetCodeRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
    on<AuthUpdatePhoneRequested>(_onAuthUpdatePhoneRequested);
    on<AuthUpdateProfileRequested>(_onAuthUpdateProfileRequested);
    on<AuthChangePasswordRequested>(_onAuthChangePasswordRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthClearMessages>(_onAuthClearMessages);

    // Initial check on creation
    add(const AuthCheckRequested());
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final cached = authRepository.getCachedUser();
    if (cached != null && cached.isAuthenticated) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: cached,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      ));
      // Try silent Google Sign-In in the background
      try {
        final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
        if (account != null) {
          final GoogleSignInAuthentication auth = await account.authentication;
          final accessToken = auth.accessToken ?? '';
          final idToken = auth.idToken ?? '';
          final tokenToSend = accessToken.isNotEmpty ? accessToken : idToken;

          if (tokenToSend.isNotEmpty) {
            try {
              final user = await authRepository.loginWithGoogle(
                accessToken: tokenToSend,
                idToken: idToken.isNotEmpty ? idToken : null,
                email: account.email,
                name: account.displayName,
                avatar: account.photoUrl,
              );
              await authRepository.saveUser(user);
              emit(state.copyWith(
                status: AuthStatus.authenticated,
                user: user,
              ));
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      final user = await authRepository.login(event.email, event.password);
      await authRepository.saveUser(user);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        successMessage: 'Welcome back, ${user.name}!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled account picker
        emit(state.copyWith(
          status: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        ));
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      var accessToken = auth.accessToken ?? '';
      final idToken = auth.idToken ?? '';

      if (accessToken.isEmpty) {
        try {
          final headers = await account.authHeaders;
          final bearer = headers['Authorization'] ?? headers['authorization'] ?? '';
          if (bearer.startsWith('Bearer ')) {
            accessToken = bearer.substring(7).trim();
          }
        } catch (e) {
          debugPrint('⚠️ authHeaders resolution error: $e');
        }
      }

      final tokenToSend = accessToken.isNotEmpty ? accessToken : idToken;
      if (tokenToSend.isEmpty) {
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Could not obtain Google authentication token. Please try again.',
        ));
        return;
      }

      try {
        final user = await authRepository.loginWithGoogle(
          accessToken: tokenToSend,
          idToken: idToken.isNotEmpty ? idToken : null,
          email: account.email,
          name: account.displayName,
          avatar: account.photoUrl,
        );
        await authRepository.saveUser(user);
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          successMessage: 'Signed in as ${user.name}',
        ));
      } catch (e) {
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Backend failed to save Google user: ${_cleanErrorMessage(e)}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthGoogleTokenLoginRequested(
    AuthGoogleTokenLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      final tokenToSend = (event.accessToken != null && event.accessToken!.isNotEmpty)
          ? event.accessToken!
          : (event.idToken ?? '');

      if (tokenToSend.isEmpty) {
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Google access token is required',
        ));
        return;
      }

      final user = await authRepository.loginWithGoogle(
        accessToken: tokenToSend,
        idToken: event.idToken,
        email: event.email,
        name: event.name,
        avatar: event.avatarUrl,
      );
      await authRepository.saveUser(user);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        successMessage: 'Signed in as ${user.name}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      final result = await authRepository.register(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
      );
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: result['message'] ?? 'Account created successfully!',
        extraData: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthVerifyRegistrationEmailRequested(
    AuthVerifyRegistrationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      final user = await authRepository.verifyRegistrationEmail(event.email, event.code);
      await authRepository.saveUser(user);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        successMessage: 'Email verified successfully! Welcome, ${user.name}!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthResendVerificationRequested(
    AuthResendVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      final result = await authRepository.resendRegistrationVerification(event.email);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: result['message'] ?? 'Verification code resent successfully.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      final result = await authRepository.forgotPassword(event.email);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: result['message'] ?? 'Verification code sent to your email.',
        extraData: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthVerifyResetCodeRequested(
    AuthVerifyResetCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      final result = await authRepository.verifyResetCode(event.email, event.code);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: 'Code verified successfully!',
        extraData: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      final result = await authRepository.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: result['message'] ?? 'Password reset successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthUpdatePhoneRequested(
    AuthUpdatePhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state.user;
    if (current == null) return;

    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    final cleanPhone = event.phone.trim();
    final userEmail = current.email.trim().toLowerCase();
    final userName = current.name.trim().isNotEmpty ? current.name.trim() : 'Customer';
    final token = current.token ?? '';

    var updatedUser = current;
    bool remoteSaved = false;

    if (token.isNotEmpty && !token.startsWith('google_')) {
      try {
        final updated = await authRepository.updateProfile(
          token: token,
          name: userName,
          phone: cleanPhone,
          avatarUrl: current.avatarUrl,
        );
        updatedUser = updated;
        remoteSaved = true;
      } catch (e) {
        debugPrint('⚠️ updateProfile notice: $e');
      }
    }

    if (!remoteSaved) {
      try {
        final response = await authRepository.register(
          name: userName,
          email: userEmail,
          phone: cleanPhone,
          password: 'GoogleAuth!_${userEmail.hashCode.abs()}',
        );
        final responseId = (response['_id'] ?? response['id'] ?? '').toString();
        final responsePhone = (response['phone'] ?? cleanPhone).toString();

        updatedUser = current.copyWith(
          id: responseId.isNotEmpty ? responseId : current.id,
          phone: responsePhone,
          name: userName,
          role: 'user',
        );
      } catch (e) {
        debugPrint('⚠️ Register customer notice: $e');
        updatedUser = current.copyWith(phone: cleanPhone);
      }
    }

    await authRepository.saveUser(updatedUser);
    emit(state.copyWith(
      status: AuthStatus.authenticated,
      user: updatedUser,
      successMessage: 'Phone number saved successfully!',
    ));
  }

  Future<void> _onAuthUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state.user;
    if (current == null) return;

    final token = current.token ?? '';
    var updatedUser = current;

    try {
      final updated = await authRepository.updateProfile(
        token: token,
        name: event.name.trim(),
        phone: event.phone.trim(),
        avatarUrl: event.avatarUrl ?? current.avatarUrl,
      );
      updatedUser = updated;
    } catch (_) {
      updatedUser = current.copyWith(
        name: event.name.trim(),
        phone: event.phone.trim(),
        avatarUrl: event.avatarUrl ?? current.avatarUrl,
      );
      await authRepository.saveUser(updatedUser);
    }

    emit(state.copyWith(
      status: AuthStatus.authenticated,
      user: updatedUser,
      successMessage: 'Profile updated successfully!',
    ));
  }

  Future<void> _onAuthChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearMessages: true,
    ));

    try {
      await authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        successMessage: 'Password updated successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _cleanErrorMessage(e),
      ));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await authRepository.logout();
    emit(const AuthState(
      status: AuthStatus.unauthenticated,
      successMessage: 'Logged out successfully.',
    ));
  }

  void _onAuthClearMessages(
    AuthClearMessages event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(clearMessages: true));
  }

  String _cleanErrorMessage(Object error) {
    var str = error.toString();
    if (str.startsWith('Exception: ')) {
      str = str.substring(11);
    }
    if (str.contains('"message":"')) {
      final start = str.indexOf('"message":"') + 11;
      final end = str.indexOf('"', start);
      if (end != -1) {
        return str.substring(start, end);
      }
    }
    return str;
  }
}
