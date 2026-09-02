import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.role,
    super.token,
    super.avatarUrl,
    super.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // If backend returns nested user object e.g. { user: {...}, token: '...' }
    final Map<String, dynamic> userMap =
        json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : json;

    final String tokenVal = (json['token'] ?? json['accessToken'] ?? userMap['token'] ?? '').toString();
    final String idVal = (userMap['_id'] ?? userMap['id'] ?? '').toString();
    final String nameVal = (userMap['name'] ?? userMap['username'] ?? 'Customer').toString();
    final String emailVal = (userMap['email'] ?? '').toString();
    final String phoneVal = (userMap['phone'] ?? userMap['phoneNumber'] ?? '').toString();
    final String roleVal = (userMap['role'] ?? 'user').toString();
    final bool isVerifiedVal = userMap['isVerified'] == true || userMap['requiresEmailVerification'] != true;
    final String avatarVal = (userMap['avatar'] ??
            userMap['avatarUrl'] ??
            userMap['picture'] ??
            userMap['photoUrl'] ??
            '')
        .toString();

    final normalized = <String, dynamic>{
      'id': idVal,
      'name': nameVal,
      'email': emailVal,
      'phone': phoneVal,
      'role': roleVal,
      'token': tokenVal.isNotEmpty ? tokenVal : null,
      'avatarUrl': avatarVal,
      'isVerified': isVerifiedVal,
    };

    return _$UserModelFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
