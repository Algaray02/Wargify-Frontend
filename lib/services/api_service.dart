import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import 'secure_session_storage.dart';
import 'session_expiry_handler.dart';

class ApiService {
  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      ) {
    final sessionStorage = SecureSessionStorage();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await sessionStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          if (statusCode == 401 || statusCode == 419) {
            await SessionExpiryHandler.forceLogout(
              message: 'Sesi berakhir. Silakan login kembali.',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  dynamic _unwrap(dynamic payload) {
    if (payload is Map<String, dynamic> && payload.containsKey('data')) {
      return payload['data'];
    }
    return payload;
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await _dio.get(path);
    final payload = _unwrap(response.data);

    if (payload is List) return payload;

    return const [];
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final response = await _dio.get(path);
    final payload = _unwrap(response.data);

    if (payload is Map<String, dynamic>) return payload;

    return {};
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(path, data: data);
    final payload = _unwrap(response.data);

    if (payload is Map<String, dynamic>) return payload;

    return {};
  }

  Future<Map<String, dynamic>> postMultipart(String path, FormData data) async {
    final response = await _dio.post(path, data: data);
    final payload = _unwrap(response.data);

    if (payload is Map<String, dynamic>) return payload;

    return {};
  }

  Future<Map<String, dynamic>> patchMultipart(
    String path,
    FormData data,
  ) async {
    final response = await _dio.patch(path, data: data);
    final payload = _unwrap(response.data);

    if (payload is Map<String, dynamic>) return payload;

    return {};
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(path, data: data);
    final payload = _unwrap(response.data);

    if (payload is Map<String, dynamic>) return payload;

    return {};
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
