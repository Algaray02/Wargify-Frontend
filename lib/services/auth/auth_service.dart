import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/user_model.dart';
import '../secure_session_storage.dart';

class AuthService {
  final SecureSessionStorage _sessionStorage = SecureSessionStorage();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    ),
  );

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = UserModel.fromJson(response.data['data']['user']);
        final token = response.data['data']['token'];

        await _sessionStorage.saveToken(token);
        await _sessionStorage.saveUserData(userData.toJson());

        return userData;
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ??
              'Server error (${e.response?.statusCode})',
        );
      } else {
        String message = 'Koneksi gagal';
        if (e.type == DioExceptionType.connectionTimeout) {
          message = 'Koneksi timeout';
        }
        if (e.type == DioExceptionType.connectionError) {
          message = 'Server tidak ditemukan/tidak aktif';
        }
        // Tambahkan detail error untuk debugging
        throw Exception('$message: ${e.error ?? e.message ?? e.type}');
      }
    }
  }

  Future<void> logout() async {
    try {
      final token = await _sessionStorage.getToken();

      if (token != null) {
        await _dio.post(
          ApiEndpoints.logout,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      // Log error but continue clearing local storage
    } finally {
      await _sessionStorage.clear();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _sessionStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserModel?> getCurrentUser() async {
    final userData = await _sessionStorage.getUserData();
    return userData == null ? null : UserModel.fromJson(userData);
  }

  Future<UserModel> getProfile() async {
    try {
      final token = await _sessionStorage.getToken();

      final response = await _dio.get(
        ApiEndpoints.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = UserModel.fromJson(response.data['data']);
        await _sessionStorage.saveUserData(userData.toJson());
        return userData;
      } else {
        throw Exception(
          response.data['message'] ?? 'Gagal mengambil data profil',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ??
              'Server error (${e.response?.statusCode})',
        );
      } else {
        throw Exception('Koneksi gagal atau tidak ada internet');
      }
    }
  }
}
