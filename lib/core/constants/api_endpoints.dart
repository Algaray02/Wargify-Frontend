class ApiEndpoints {
  // Ganti dengan IP Local Komputer kamu (Cek via 'hostname -I' atau 'ip addr')
  // PENTING: Pastikan IP ini adalah IP server di jaringan lokal yang SAMA dengan hape
  static const String baseUrl = 'http://172.16.160.231:8081/api/v1'; 
  
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
}
