import 'package:dio/dio.dart';

class AppError {
  static String userFriendly(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Koneksi terputus. Periksa kembali jaringan Anda.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Tidak dapat terhubung ke server. Pastikan jaringan Anda aktif.';
      }
      if (error.response != null) {
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          return data['message'].toString();
        }
        return 'Server sedang sibuk. Silakan coba beberapa saat lagi.';
      }
      return 'Koneksi gagal atau tidak ada internet.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
