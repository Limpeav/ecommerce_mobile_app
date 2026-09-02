class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? token;
  final String avatarUrl;
  final bool isVerified;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'user',
    this.token,
    this.avatarUrl = '',
    this.isVerified = true,
  });

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? token,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      token: token ?? this.token,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
