class ApiEndpoints {
  // Ganti dengan IP Local Komputer kamu (Cek via 'hostname -I' atau 'ip addr')
  // PENTING: Pastikan IP ini adalah IP server di jaringan lokal yang SAMA dengan hape
  static const String baseUrl = 'http://172.16.95.214:8081/api/v1';

  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
  static const String fcmToken = '/me/fcm-token';
  static const String qrScan = '/qr/scan';
  static const String myIuran = '/me/iuran';
  static const String users = '/users';
  static const String citizenGroups = '/citizen-groups';
  static const String households = '/households';
  static const String treasuryLogs = '/treasury-logs';
  static const String treasurySummary = '/treasury-summary';
  static const String announcements = '/announcements';
  static const String activities = '/activities';
  static const String galleries = '/galleries';
  static const String rondaGroups = '/ronda/groups';
  static const String rondaSchedules = '/ronda/schedules';
  static const String rondaCheckpoints = '/ronda/checkpoints';
  static const String rondaAttendance = '/ronda/attendance';
  static const String facilityReports = '/facility-reports';
  static const String emergencyAlerts = '/emergency-alerts';
}
