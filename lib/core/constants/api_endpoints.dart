class ApiEndpoints {
  // Ganti dengan IP Local Komputer kamu (Cek via 'hostname -I' atau 'ip addr')
  // PENTING: Pastikan IP ini adalah IP server di jaringan lokal yang SAMA dengan hape
  // static const String baseUrl = 'http://172.16.163.250:8081/api/v1';
  static const String baseUrl = 'https://wargify.algaray.dev/api/v1';

  // MODUL AUTH & PROFIL
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
  static const String fcmToken = '/me/fcm-token';

  // MODUL WARGA
  static const String users = '/users';
  static const String citizenGroups = '/citizen-groups';
  static const String households = '/households';

  // MODUL IURAN & KAS
  static const String myIuran = '/me/iuran';
  static const String checkArrears = '/iuran/check-arrears';
  static const String iuranPeriods = '/iuran-periods';
  static const String iuranPayments = '/iuran-payments';
  static const String treasuryLogs = '/treasury-logs';
  static const String treasurySummary = '/treasury-summary';

  // MODUL SCANNER UTAMA
  static const String qrScan = '/qr/scan';

  // MODUL PENGUMUMAN & GALERI
  static const String announcements = '/announcements';
  static const String activities = '/activities';
  static const String galleries = '/galleries';

  // MODUL RONDA
  static const String rondaGroups = '/ronda/groups';
  static const String rondaSchedules = '/ronda/schedules';
  static const String rondaCheckpoints = '/ronda/checkpoints';
  static const String rondaAttendance = '/ronda/attendance';

  // MODUL LAPORAN & SOS
  static const String facilityReports = '/facility-reports';
  static const String emergencyAlerts = '/emergency-alerts';
}
