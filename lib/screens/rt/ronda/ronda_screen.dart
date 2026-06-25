import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'manage_ronda_screen.dart';
import 'live_ronda_screen.dart';

class RondaScreen extends StatefulWidget {
  const RondaScreen({super.key});

  @override
  State<RondaScreen> createState() => _RondaScreenState();
}

class _RondaScreenState extends State<RondaScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _facilityReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRonda();
  }

  Future<void> _fetchRonda() async {
    try {
      final results = await Future.wait([
        _apiService.getList(ApiEndpoints.rondaSchedules),
        _apiService.getList(ApiEndpoints.facilityReports),
      ]);
      final rows = results[0];
      final reports = results[1];
      if (!mounted) return;
      setState(() {
        _schedules = rows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _facilityReports = reports
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? get _activeSchedule {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final sorted = List<Map<String, dynamic>>.from(_schedules);
    sorted.sort((a, b) {
      final aDate = DateTime.tryParse('${a['schedule_date']}') ?? now;
      final bDate = DateTime.tryParse('${b['schedule_date']}') ?? now;
      final cmp = aDate.compareTo(bDate);
      if (cmp != 0) return cmp;
      final aStart = DateTime.tryParse('${a['shift_start']}') ?? now;
      final bStart = DateTime.tryParse('${b['shift_start']}') ?? now;
      return aStart.compareTo(bStart);
    });

    for (final s in sorted) {
      if (s['status'] == 'ONGOING') return s;
    }

    for (final s in sorted) {
      final date = DateTime.tryParse('${s['schedule_date']}');
      final start = DateTime.tryParse('${s['shift_start']}');
      final end = DateTime.tryParse('${s['shift_end']}');
      if (date == null || start == null || end == null) continue;
      if (DateTime(date.year, date.month, date.day) == today &&
          now.isAfter(start) &&
          now.isBefore(end))
        return s;
    }

    for (final s in sorted) {
      final date = DateTime.tryParse('${s['schedule_date']}');
      final start = DateTime.tryParse('${s['shift_start']}');
      if (date == null || start == null) continue;
      if (DateTime(date.year, date.month, date.day) == today &&
          start.isAfter(now))
        return s;
    }

    for (final s in sorted) {
      final date = DateTime.tryParse('${s['schedule_date']}');
      if (date == null) continue;
      if (DateTime(date.year, date.month, date.day).isAfter(today)) return s;
    }

    return null;
  }

  Map<String, dynamic>? get _activeSession {
    final now = DateTime.now();

    for (final s in _schedules) {
      if (s['status'] == 'ONGOING') return s;
    }

    for (final s in _schedules) {
      final date = DateTime.tryParse('${s['schedule_date']}');
      final start = DateTime.tryParse('${s['shift_start']}');
      final end = DateTime.tryParse('${s['shift_end']}');
      if (date == null || start == null || end == null) continue;
      final today = DateTime(now.year, now.month, now.day);
      if (DateTime(date.year, date.month, date.day) == today &&
          now.isAfter(start) &&
          now.isBefore(end))
        return s;
    }

    return null;
  }

  int get _activeMembers {
    final schedule = _activeSchedule;
    if (schedule == null) return 0;
    final group = Map<String, dynamic>.from((schedule['group'] ?? {}) as Map);
    final members = group['members'];
    return members is List ? members.length : 0;
  }

  int get _totalCheckpoints {
    final schedule = _activeSchedule;
    final checkpoints = schedule?['checkpoints'];
    return checkpoints is List ? checkpoints.length : 0;
  }

  int get _scannedCheckpoints {
    final schedule = _activeSchedule;
    final logs = schedule?['checkpoint_logs'];
    if (logs is! List) return 0;
    final now = DateTime.now();
    return logs.whereType<Map>().where((log) {
      final timestampStr = log['scanned_at'] ?? log['created_at'];
      if (timestampStr == null) return true;
      final date = DateTime.tryParse(timestampStr.toString());
      if (date == null) return true;
      final localDate = date.toLocal();
      return localDate.year == now.year &&
          localDate.month == now.month &&
          localDate.day == now.day;
    }).length;
  }

  String _formatScheduleDate(Map<String, dynamic> schedule) {
    final date = DateTime.tryParse('${schedule['schedule_date']}');
    return date == null ? '-' : DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  String _formatShift(Map<String, dynamic> schedule) {
    final start = DateTime.tryParse('${schedule['shift_start']}');
    final end = DateTime.tryParse('${schedule['shift_end']}');
    if (start == null || end == null) return '-';
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  List<Map<String, dynamic>> get _shiftFacilityReports {
    final schedule = _activeSchedule;
    if (schedule == null) return [];
    final shiftStart = DateTime.tryParse('${schedule['shift_start']}');
    final shiftEnd = DateTime.tryParse('${schedule['shift_end']}');
    if (shiftStart == null || shiftEnd == null) return [];

    return _facilityReports.where((report) {
      final createdAt = DateTime.tryParse('${report['created_at']}');
      if (createdAt == null) return false;
      final afterStart =
          createdAt.isAfter(shiftStart) ||
          createdAt.isAtSameMomentAs(shiftStart);
      final beforeEnd =
          createdAt.isBefore(shiftEnd) || createdAt.isAtSameMomentAs(shiftEnd);
      return afterStart && beforeEnd;
    }).toList()..sort(
      (a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    return DateFormat('dd MMM HH:mm').format(time);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'DIPROSES';
      case 'RESOLVED':
        return 'SELESAI';
      default:
        return 'MENUNGGU';
    }
  }

  Color _facilityStatusColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return const Color(0xFFB45309);
      case 'RESOLVED':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  void _showSchedulePreview(Map<String, dynamic> schedule) {
    final group = Map<String, dynamic>.from((schedule['group'] ?? {}) as Map);
    final coordinator = Map<String, dynamic>.from(
      (schedule['coordinator'] ?? {}) as Map,
    );
    final checkpoints = schedule['checkpoints'] is List
        ? schedule['checkpoints'] as List
        : const [];
    final now = DateTime.now();
    final rawLogs = schedule['checkpoint_logs'] is List
        ? schedule['checkpoint_logs'] as List
        : const [];
    final checkpointLogs = rawLogs.whereType<Map>().where((log) {
      final timestampStr = log['scanned_at'] ?? log['created_at'];
      if (timestampStr == null) return true;
      final date = DateTime.tryParse(timestampStr.toString());
      if (date == null) return true;
      final localDate = date.toLocal();
      return localDate.year == now.year &&
          localDate.month == now.month &&
          localDate.day == now.day;
    }).toList();
    final members = group['members'] is List
        ? group['members'] as List
        : const [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group['name']?.toString() ?? 'Jadwal Ronda',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                    ),
                    _buildStatusBadge(schedule['status']?.toString() ?? '-'),
                  ],
                ),
                const SizedBox(height: 18),
                _buildPreviewRow(
                  Icons.calendar_today_rounded,
                  'Tanggal',
                  _formatScheduleDate(schedule),
                ),
                _buildPreviewRow(
                  Icons.access_time_rounded,
                  'Shift',
                  _formatShift(schedule),
                ),
                _buildPreviewRow(
                  Icons.person_pin_circle_rounded,
                  'Koordinator',
                  coordinator['full_name']?.toString() ?? '-',
                ),
                _buildPreviewRow(
                  Icons.groups_rounded,
                  'Anggota',
                  '${members.length} orang',
                ),
                _buildPreviewRow(
                  Icons.qr_code_scanner_rounded,
                  'Checkpoint',
                  '${checkpointLogs.length}/${checkpoints.length}',
                ),
                const SizedBox(height: 18),
                Text(
                  'Daftar Checkpoint',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 10),
                if (checkpoints.isEmpty)
                  Text(
                    'Belum ada checkpoint pada jadwal ini.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  )
                else
                  ...checkpoints.map((checkpoint) {
                    final data = Map<String, dynamic>.from(checkpoint as Map);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['name']?.toString() ?? '-',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSchedule = _activeSchedule;
    final activeSession = _activeSession;
    final activeGroup = activeSchedule == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from((activeSchedule['group'] ?? {}) as Map);
    final coordinator = activeSchedule == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
            (activeSchedule['coordinator'] ?? {}) as Map,
          );
    final now = DateTime.now();
    final rawLogs = activeSchedule?['checkpoint_logs'] is List
        ? activeSchedule!['checkpoint_logs'] as List
        : const [];
    final checkpointLogs = rawLogs.whereType<Map>().where((log) {
      final timestampStr = log['scanned_at'] ?? log['created_at'];
      if (timestampStr == null) return true;
      final date = DateTime.tryParse(timestampStr.toString());
      if (date == null) return true;
      final localDate = date.toLocal();
      return localDate.year == now.year &&
          localDate.month == now.month &&
          localDate.day == now.day;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Dashboard Ronda',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 20),

          // Security Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF004E92), Color(0xFF001F3F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF004E92).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS KEAMANAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoading
                      ? 'Memuat...'
                      : activeSession != null
                      ? '$_scannedCheckpoints/$_totalCheckpoints Titik Terpantau'
                      : 'Tidak ada jadwal aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          if (activeSession != null) ...[
            const SizedBox(height: 20),

            // Stats Row
          ] else ...[
            const SizedBox(height: 48),
          ],

          if (activeSession != null) ...[
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'PETUGAS AKTIF',
                    value: '$_activeMembers Orang',
                    icon: Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    label: 'TITIK CEK',
                    value: '$_scannedCheckpoints/$_totalCheckpoints',
                    icon: Icons.check_circle_outline_rounded,
                    valueColor: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktivitas Terkini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoring pergerakan petugas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LiveRondaScreen(schedule: activeSchedule),
                      ),
                    );
                  },
                  child: Text(
                    'Lihat Peta',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity List
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (checkpointLogs.isEmpty)
              _buildIncidentCard(
                title: 'Belum ada scan checkpoint',
                description:
                    'Aktivitas scan akan muncul ketika koordinator melakukan patroli.',
                reporter: coordinator['full_name']?.toString() ?? '-',
                time: 'Sekarang',
                type: 'INFO',
                icon: Icons.info_outline_rounded,
                color: AppColors.primary,
              )
            else
              ...checkpointLogs.take(3).map((log) {
                final data = Map<String, dynamic>.from(log as Map);
                final checkpoint = Map<String, dynamic>.from(
                  (data['checkpoint'] ?? {}) as Map,
                );
                final scanner = Map<String, dynamic>.from(
                  (data['scanner'] ?? {}) as Map,
                );
                final scannerName =
                    scanner['full_name']?.toString() ?? 'Petugas';
                final scannerPictureUrl =
                    scanner['profile_picture_url']?.toString() ?? '';
                final scannedAt = DateTime.tryParse('${data['scanned_at']}');
                return _buildActivityItem(
                  scannerName,
                  activeGroup['name']?.toString() ?? 'Regu ronda',
                  'Scan ${checkpoint['name'] ?? 'checkpoint'}',
                  scannerPictureUrl,
                  scannedAt,
                );
              }),

            const SizedBox(height: 32),
          ],

          // Patrol Schedule Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwal Ronda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageRondaScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_rounded, size: 16),
                label: const Text('Atur Jadwal Ronda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004E92),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                activeSchedule == null
                    ? 'Belum ada jadwal ronda'
                    : 'Shift ${_formatShift(activeSchedule)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Color(0xFF004E92),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Schedule Card
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: activeSchedule == null
                ? null
                : () => _showSchedulePreview(activeSchedule),
            child: Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F2FD),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          children: [
                            Text(
                              activeSchedule == null
                                  ? '-'
                                  : DateFormat('EEE')
                                        .format(
                                          DateTime.parse(
                                            '${activeSchedule['schedule_date']}',
                                          ),
                                        )
                                        .toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              activeSchedule == null
                                  ? '-'
                                  : DateFormat('dd').format(
                                      DateTime.parse(
                                        '${activeSchedule['schedule_date']}',
                                      ),
                                    ),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${activeGroup['name'] ?? 'Belum ada regu'} ($_activeMembers ORANG)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildMemberAvatars(activeGroup['members']),
                                const SizedBox(width: 8),
                                Text(
                                  coordinator['full_name']?.toString() ?? '-',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activeSchedule == null
                                ? 'Buat jadwal ronda baru untuk mulai monitoring.'
                                : 'Ketuk kartu untuk melihat preview jadwal.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Incident Reports
          Text(
            'Laporan Kejadian',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 16),
          if (_shiftFacilityReports.isEmpty)
            _buildEmptyIncidentCard()
          else
            ..._shiftFacilityReports.take(3).map((report) {
              final reporter = report['reporter'] is Map
                  ? Map<String, dynamic>.from(report['reporter'] as Map)
                  : <String, dynamic>{};
              final status = report['status']?.toString() ?? 'SUBMITTED';
              final createdAt =
                  DateTime.tryParse('${report['created_at']}') ??
                  DateTime.now();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildIncidentCard(
                  title: report['title']?.toString() ?? 'Laporan fasilitas',
                  description: report['description']?.toString() ?? '-',
                  reporter: reporter['full_name']?.toString() ?? 'Warga',
                  time: _relativeTime(createdAt),
                  type: _statusLabel(status),
                  icon: Icons.report_problem_outlined,
                  color: _facilityStatusColor(status),
                ),
              );
            }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? const Color(0xFF0D1B2A),
                ),
              ),
              Icon(icon, color: Colors.grey[300], size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = switch (status) {
      'ONGOING' => const Color(0xFF0284C7),
      'COMPLETED' => AppColors.success,
      'MISSED' => AppColors.danger,
      _ => const Color(0xFF64748B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String name,
    String role,
    String status,
    String avatarUrl, [
    DateTime? scannedAt,
  ]) {
    final relativeTime = scannedAt == null ? 'LIVE' : _relativeTime(scannedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          avatarUrl.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl),
                  radius: 24,
                )
              : CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            relativeTime,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatars(dynamic membersData) {
    final members = membersData is List
        ? (membersData as List)
              .take(3)
              .map(
                (m) => m is Map
                    ? Map<String, dynamic>.from(m as Map)
                    : <String, dynamic>{},
              )
              .toList()
        : <Map<String, dynamic>>[];

    if (members.isEmpty) {
      return SizedBox(
        height: 24,
        width: 60,
        child: Text(
          'Tidak ada anggota',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      );
    }

    return SizedBox(
      height: 24,
      width: members.length > 1 ? 60 : 32,
      child: Stack(
        children: List.generate(members.length, (index) {
          final member = members[index];
          final name = member['full_name']?.toString() ?? '?';
          final pictureUrl = member['profile_picture_url']?.toString() ?? '';
          final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

          return Positioned(
            left: index * 14.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: pictureUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(pictureUrl),
                    )
                  : CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIncidentCard({
    required String title,
    required String description,
    required String reporter,
    required String time,
    required String type,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?u=reporter',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dilaporkan oleh $reporter • $time',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIncidentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Belum ada laporan fasilitas yang masuk selama shift ronda ini.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
