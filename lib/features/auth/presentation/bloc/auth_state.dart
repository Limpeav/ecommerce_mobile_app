import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic>? extraData;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.extraData,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null && user!.isAuthenticated;

  bool get isLoading => status == AuthStatus.loading;
  UserEntity? get currentUser => user;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    String? successMessage,
    Map<String, dynamic>? extraData,
    bool clearUser = false,
    bool clearMessages = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      extraData: extraData ?? this.extraData,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, successMessage, extraData];
}
