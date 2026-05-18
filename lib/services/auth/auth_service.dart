import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/user_model.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    },
  ));

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _dio.post(ApiEndpoints.login, data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = UserModel.fromJson(response.data['data']['user']);
        final token = response.data['data']['token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_data', jsonEncode(userData.toJson()));
        
        return userData;
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Server error (${e.response?.statusCode})');
      } else {
        String message = 'Koneksi gagal';
        if (e.type == DioExceptionType.connectionTimeout) message = 'Koneksi timeout';
        if (e.type == DioExceptionType.connectionError) message = 'Server tidak ditemukan/tidak aktif';
        // Tambahkan detail error untuk debugging
        throw Exception('$message: ${e.error ?? e.message ?? e.type}');
      }
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        await _dio.post(ApiEndpoints.logout,
            options: Options(headers: {'Authorization': 'Bearer $token'}));
      }
    } catch (e) {
      // Log error but continue clearing local storage
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_data');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<UserModel> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await _dio.get(
        ApiEndpoints.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = UserModel.fromJson(response.data['data']);
        // Simpan data user terbaru ke SharedPreferences
        await prefs.setString('user_data', jsonEncode(userData.toJson()));
        return userData;
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengambil data profil');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Server error (${e.response?.statusCode})');
      } else {
        throw Exception('Koneksi gagal atau tidak ada internet');
      }
    }
  }
}
