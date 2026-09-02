import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  UserModel? getUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _userKey = 'cached_user_session';
  final SharedPreferences? sharedPreferences;
  final Map<String, String> _memoryCache = {};

  AuthLocalDataSourceImpl({this.sharedPreferences});

  @override
  Future<void> saveUser(UserModel user) async {
    final encoded = json.encode(user.toJson());
    _memoryCache[_userKey] = encoded;
    try {
      final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
      await prefs.setString(_userKey, encoded);
    } catch (_) {}
  }

  @override
  UserModel? getUser() {
    try {
      String? jsonStr;
      if (sharedPreferences != null) {
        jsonStr = sharedPreferences!.getString(_userKey);
      }
      jsonStr ??= _memoryCache[_userKey];
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final Map<String, dynamic> map = json.decode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    _memoryCache.remove(_userKey);
    try {
      final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (_) {}
  }
}
