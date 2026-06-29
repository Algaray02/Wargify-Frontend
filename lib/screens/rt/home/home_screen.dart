import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/models/user_model.dart';
import 'package:wargify/services/api_service.dart';
import '../sos/sos_trigger_screen.dart';
import '../sos/sos_dashboard_screen.dart';
import '../pengumuman/pengumuman_screen.dart';
import '../laporan/laporan_screen.dart';
import '../ronda/manage_ronda_screen.dart';
import '../keuangan/kas_activity_screen.dart';

class RTHomePage extends StatefulWidget {
  final UserModel user;
  const RTHomePage({super.key, required this.user});

  @override
  State<RTHomePage> createState() => _RTHomePageState();
}

class _RTHomePageState extends State<RTHomePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _activeAlert;
  double _currentBalance = 0;
  double _totalIncome = 0;
  bool _isLoadingSummary = true;

  UserModel get user => widget.user;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final results = await Future.wait([
        _apiService.getList(ApiEndpoints.emergencyAlerts),
        _apiService.getMap(ApiEndpoints.treasurySummary),
      ]);
      final alerts = results[0] as List<dynamic>;
      final summary = results[1] as Map<String, dynamic>;
      final activeAlerts = alerts
          .map((row) => Map<String, dynamic>.from(row as Map))
          .where((alert) => alert['status'] == 'ACTIVE')
          .toList();

      if (!mounted) return;
      setState(() {
        _activeAlert = activeAlerts.isNotEmpty ? activeAlerts.first : null;
        _currentBalance =
            double.tryParse('${summary['current_balance'] ?? 0}') ?? 0;
        _totalIncome = double.tryParse('${summary['total_income'] ?? 0}') ?? 0;
        _isLoadingSummary = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 19) return 'Sore';
    return 'Malam';
  }

  String _getFirstName() {
    return user.fullName.trim().split(' ')[0];
  }

  String _formatCurrency(double value) {
    final number = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
    return 'Rp $number';
  }

  String _elapsedLabel(String? value) {
    if (value == null) return '-';
    final createdAt = DateTime.tryParse(value);
    if (createdAt == null) return '-';
    final minutes = DateTime.now().difference(createdAt).inMinutes;
    if (minutes < 1) return 'Baru saja';
    if (minutes < 60) return '$minutes menit lalu';
    return '${(minutes / 60).floor()} jam lalu';
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveAlert = _activeAlert != null;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Greeting
            Text(
              'DASHBOARD KETUA RT',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_getGreeting()}, ${_getFirstName()}.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 24),
            // SOS Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasActiveAlert
                    ? const Color(0xFFFFF1F1)
                    : const Color(0xFFEAF8EA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasActiveAlert
                      ? AppColors.danger.withOpacity(0.1)
                      : Colors.green.withOpacity(0.14),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SOS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: hasActiveAlert
                              ? AppColors.danger
                              : Colors.green,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hasActiveAlert
                              ? AppColors.danger
                              : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hasActiveAlert ? 'LIVE' : 'AMAN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasActiveAlert
                              ? _elapsedLabel(
                                  _activeAlert?['created_at']?.toString(),
                                )
                              : 'Tidak ada SOS aktif',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasActiveAlert
                              ? '${(_activeAlert?['sender'] as Map?)?['full_name'] ?? 'Warga'}'
                              : 'Semua laporan darurat aman',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SosDashboardScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasActiveAlert
                                  ? AppColors.danger
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: Text(
                              'Lihat Detail SOS',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Emergency Button
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SosTriggerScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.report_problem_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tombol Darurat',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Gunakan jika ada situasi genting',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Total Iuran Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KasActivityScreen(),
                    ),
                  ).then((_) => _loadDashboard());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'SALDO KAS SAAT INI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoadingSummary
                            ? 'Memuat...'
                            : _formatCurrency(_currentBalance),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _totalIncome <= 0
                              ? 0
                              : (_currentBalance / _totalIncome).clamp(0, 1),
                          backgroundColor: const Color(0xFFD9E9F7),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.success,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoadingSummary
                            ? 'MENGAMBIL DATA KAS'
                            : 'TOTAL PEMASUKAN ${_formatCurrency(_totalIncome)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Management Cards
            _buildManagementCard(
              title: 'Manajemen Laporan',
              subtitle: 'KELOLA LAPORAN',
              icon: Icons.description_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LaporanScreen(user: user),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              title: 'Manajemen Pengumuman',
              subtitle: 'KELOLA PENGUMUMAN',
              icon: Icons.campaign_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PengumumanScreen(user: user),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildManagementCard(
              title: 'Atur Jadwal Ronda',
              subtitle: 'KELOLA JADWAL & CHECKPOINT RONDA',
              icon: Icons.security_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageRondaScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
