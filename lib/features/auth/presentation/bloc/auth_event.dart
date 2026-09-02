import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthGoogleTokenLoginRequested extends AuthEvent {
  final String? accessToken;
  final String? idToken;
  final String? name;
  final String? email;
  final String? avatarUrl;

  const AuthGoogleTokenLoginRequested({
    this.accessToken,
    this.idToken,
    this.name,
    this.email,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [accessToken, idToken, name, email, avatarUrl];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, phone, password];
}

class AuthVerifyRegistrationEmailRequested extends AuthEvent {
  final String email;
  final String code;

  const AuthVerifyRegistrationEmailRequested({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

class AuthResendVerificationRequested extends AuthEvent {
  final String email;

  const AuthResendVerificationRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthVerifyResetCodeRequested extends AuthEvent {
  final String email;
  final String code;

  const AuthVerifyResetCodeRequested({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;

  const AuthResetPasswordRequested({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [token, newPassword];
}

class AuthUpdatePhoneRequested extends AuthEvent {
  final String phone;

  const AuthUpdatePhoneRequested({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class AuthUpdateProfileRequested extends AuthEvent {
  final String name;
  final String phone;
  final String? avatarUrl;

  const AuthUpdateProfileRequested({
    required this.name,
    required this.phone,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [name, phone, avatarUrl];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthClearMessages extends AuthEvent {
  const AuthClearMessages();
}
