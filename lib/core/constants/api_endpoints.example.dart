class ApiEndpoints {
  // Ganti dengan IP Local Komputer kamu (Cek via 'hostname -I' atau 'ip addr')
  // PENTING: Pastikan IP ini adalah IP server di jaringan lokal yang SAMA dengan hape
  static const String baseUrl = 'http://[IP ADDRESS SERVER]:[PORT]/api/v1'; 

  
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
}
