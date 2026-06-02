import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureSessionStorage {
  static const _tokenKey = 'token';
  static const _userDataKey = 'user_data';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) return token;

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _storage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_tokenKey);
      return legacyToken;
    }

    return null;
  }

  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    var userJson = await _storage.read(key: _userDataKey);
    if (userJson == null || userJson.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      userJson = prefs.getString(_userDataKey);
      if (userJson != null && userJson.isNotEmpty) {
        await _storage.write(key: _userDataKey, value: userJson);
        await prefs.remove(_userDataKey);
      }
    }

    if (userJson == null || userJson.isEmpty) return null;
    final decoded = jsonDecode(userJson);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> saveUserData(Map<String, dynamic> userData) {
    return _storage.write(key: _userDataKey, value: jsonEncode(userData));
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userDataKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
  }
}
