import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_endpoints.dart';

class TreasuryService {
  // Konfigurasi Dio disamakan dengan AuthService kamu
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    },
  ));

  // Helper untuk mengambil token Sanctum yang disimpan pas login
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // =====================================================
  // 1. AMBIL RINGKASAN KAS (Untuk Widget Dashboard)
  // =====================================================
  Future<Map<String, dynamic>> getTreasurySummary() async {
    try {
      final token = await _getToken();
      
      final response = await _dio.get(
        '/treasury-summary',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Mengembalikan data ringkasan seperti total_saldo, pemasukan, pengeluaran
        return response.data['data']; 
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengambil ringkasan kas');
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // =====================================================
  // 2. CATAT TRANSAKSI KAS BARU (Pemasukan / Pengeluaran)
  // =====================================================
  Future<bool> storeTreasuryLog({
    required String type,        // 'INCOME' atau 'EXPENSE'
    required String source,      // 'IURAN_WARGA', 'PENGELUARAN_RUTIN', dll.
    required double amount,
    required String description,
  }) async {
    try {
      final token = await _getToken();
      
      final response = await _dio.post(
        '/treasury-logs',
        data: {
          'type': type,
          'source': source,
          'amount': amount,
          'description': description,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  // =====================================================
  // 3. HANDLER ERROR (Sama dengan milik AuthService)
  // =====================================================
  void _handleDioError(DioException e) {
    if (e.response != null) {
      throw Exception(e.response?.data['message'] ?? 'Server error (${e.response?.statusCode})');
    } else {
      String message = 'Koneksi gagal';
      if (e.type == DioExceptionType.connectionTimeout) message = 'Koneksi timeout';
      if (e.type == DioExceptionType.connectionError) message = 'Server tidak ditemukan/tidak aktif';
      throw Exception('$message: ${e.error ?? e.message ?? e.type}');
    }
  }
}