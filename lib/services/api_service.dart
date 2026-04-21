import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();
  
  // Gunakan 10.0.2.2 untuk Emulator Android
  // final String baseUrl = 'http://10.0.2.2:8000/api'; //ini kalau pakai android emulator
  // final String baseUrl = 'http://172.16.160.192:8000/api'; //ini kalau pakai hp asli
  final String baseUrl = 'http://localhost:8000/api'; //ini kalau pakai chrome

  Future<String> cekKoneksi() async {
    try {
      final response = await _dio.get('$baseUrl/halo');
      // Pastikan Laravel merespon dengan format JSON: {"message": "..."}
      return response.data['message']; 
    } catch (e) {
      return "Error: $e";
    }
  }
}