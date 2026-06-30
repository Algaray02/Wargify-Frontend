import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/common/sos/sos_detail_screen.dart';
import 'package:wargify/services/api_service.dart';

class ActivityLog {
  final String title;
  final String content;
  final DateTime? createdAt;
  final String type;
  final IconData icon;
  final String? refId;

  ActivityLog({
    required this.title,
    required this.content,
    required this.createdAt,
    required this.type,
    required this.icon,
    this.refId,
  });
}

class NotifikasiLogScreen extends StatefulWidget {
  const NotifikasiLogScreen({super.key});

  @override
  State<NotifikasiLogScreen> createState() => _NotifikasiLogScreenState();
}

class _NotifikasiLogScreenState extends State<NotifikasiLogScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<ActivityLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getList(ApiEndpoints.announcements),
        _apiService.getList(ApiEndpoints.activities),
        _apiService.getList(ApiEndpoints.emergencyAlerts),
        _apiService.getList(ApiEndpoints.rondaSchedules),
      ]);

      final logs =
          <ActivityLog>[
            ..._announcementLogs(results[0]),
            ..._activityLogs(results[1]),
            ..._sosLogs(results[2]),
            ..._rondaLogs(results[3]),
          ]..sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

      if (!mounted) return;
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengambil notifikasi dari backend.';
        _isLoading = false;
      });
    }
  }

  List<ActivityLog> _announcementLogs(List<dynamic> rows) {
    return rows.whereType<Map>().map((row) {
      final item = Map<String, dynamic>.from(row);
      final status = _formatTitle(item['status']);
      final creator = (item['creator'] as Map?)?['full_name']?.toString();
      return ActivityLog(
        title: item['title']?.toString() ?? 'Pengumuman',
        content:
            '${status == '-' ? 'Pengumuman' : status} oleh ${creator ?? 'pengurus'}: ${item['content'] ?? ''}',
        createdAt: _parseDate(item['published_at'] ?? item['updated_at']),
        type: 'announcement',
        icon: Icons.campaign_rounded,
      );
    }).toList();
  }

  List<ActivityLog> _activityLogs(List<dynamic> rows) {
    return rows.whereType<Map>().map((row) {
      final item = Map<String, dynamic>.from(row);
      return ActivityLog(
        title: item['title']?.toString() ?? 'Kegiatan',
        content:
            '${_formatTitle(item['type'])} di ${item['location_name'] ?? '-'} pada ${_formatDate(item['activity_date'])}.',
        createdAt: _parseDate(item['updated_at'] ?? item['created_at']),
        type: 'activity',
        icon: Icons.event_note_rounded,
      );
    }).toList();
  }

  List<ActivityLog> _sosLogs(List<dynamic> rows) {
    return rows.whereType<Map>().map((row) {
      final item = Map<String, dynamic>.from(row);
      final sender = (item['sender'] as Map?)?['full_name']?.toString();
      return ActivityLog(
        title: item['status'] == 'ACTIVE' ? 'Darurat SOS Aktif' : 'SOS Selesai',
        content:
            '${sender ?? 'Warga'} mengirim SOS: ${item['message'] ?? 'Butuh bantuan segera.'}',
        createdAt: _parseDate(item['created_at']),
        type: 'sos',
        icon: Icons.warning_rounded,
        refId: item['alert_id']?.toString(),
      );
    }).toList();
  }

  List<ActivityLog> _rondaLogs(List<dynamic> rows) {
    return rows.whereType<Map>().map((row) {
      final item = Map<String, dynamic>.from(row);
      final group = (item['group'] as Map?)?['name']?.toString();
      return ActivityLog(
        title: 'Jadwal Ronda',
        content:
            '${group ?? 'Regu ronda'} dijadwalkan pada ${_formatDate(item['schedule_date'])} dengan status ${_formatTitle(item['status'])}.',
        createdAt: _parseDate(item['updated_at'] ?? item['created_at']),
        type: 'ronda',
        icon: Icons.security_rounded,
      );
    }).toList();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTitle(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return '-';
    return raw
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  String _relativeTime(DateTime? value) {
    if (value == null) return '-';
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return _formatDate(value.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Aktivitas & Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLogs,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _buildLogList(),
      ),
    );
  }

  Widget _buildLogList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Text(
          'LOG AKTIVITAS TERBARU',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey[500],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        if (_logs.isEmpty)
          _buildEmptyState()
        else
          ..._logs.take(50).map(_buildLogCard),
      ],
    );
  }

  Widget _buildLogCard(ActivityLog log) {
    final isSos = log.type == 'sos';
    final isSystem = log.type == 'announcement' || log.type == 'activity';
    final cardBgColor = isSos
        ? const Color(0xFFFFEBEE)
        : isSystem
        ? const Color(0xFFE3F2FD)
        : Colors.white;
    final iconBgColor = isSos ? AppColors.danger : AppColors.primary;

    return InkWell(
      onTap: isSos && (log.refId?.isNotEmpty ?? false)
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SosDetailScreen(alertId: log.refId!),
              ),
            )
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSos
                ? const Color(0xFFFADBD8)
                : isSystem
                ? const Color(0xFFD4E6F1)
                : Colors.grey.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(log.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSos
                                ? AppColors.danger
                                : const Color(0xFF0D1B2A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(log.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isSos ? AppColors.danger : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    log.content,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 42,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada notifikasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadLogs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
