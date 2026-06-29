import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';

import 'add_kegiatan_screen.dart';

class ActivityItem {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime activityDate;
  final String locationName;
  final String status;
  final String qrCode;
  final String creatorName;
  final int participantsCount;
  final int targetGroupsCount;
  final int invitedUsersCount;
  final List<String> targetGroupNames;
  final List<String> invitedUserNames;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.activityDate,
    required this.locationName,
    required this.status,
    required this.qrCode,
    required this.creatorName,
    required this.participantsCount,
    required this.targetGroupsCount,
    required this.invitedUsersCount,
    required this.targetGroupNames,
    required this.invitedUserNames,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    final creator = Map<String, dynamic>.from((json['creator'] ?? {}) as Map);
    final groups = (json['target_groups'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    final users = (json['invited_users'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item['full_name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    return ActivityItem(
      id: json['activity_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'KEGIATAN_UMUM',
      title: json['title']?.toString() ?? 'Kegiatan warga',
      description: json['description']?.toString() ?? '',
      activityDate:
          DateTime.tryParse('${json['activity_date']}') ?? DateTime.now(),
      locationName: json['location_name']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'DRAFT',
      qrCode: json['attendance_qr_code']?.toString() ?? '',
      creatorName: creator['full_name']?.toString() ?? 'Pengurus',
      participantsCount:
          int.tryParse('${json['participants_count'] ?? 0}') ?? 0,
      targetGroupsCount:
          int.tryParse('${json['target_groups_count'] ?? groups.length}') ??
          groups.length,
      invitedUsersCount:
          int.tryParse('${json['invited_users_count'] ?? users.length}') ??
          users.length,
      targetGroupNames: groups,
      invitedUserNames: users,
    );
  }
}

class KegiatanScreen extends StatefulWidget {
  const KegiatanScreen({super.key});

  @override
  State<KegiatanScreen> createState() => _KegiatanScreenState();
}

class _KegiatanScreenState extends State<KegiatanScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<ActivityItem> _activities = [];
  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;
  String _statusFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await _apiService.getList(ApiEndpoints.activities);
      final activities =
          rows
              .whereType<Map>()
              .map(
                (row) => ActivityItem.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList()
            ..sort((a, b) => b.activityDate.compareTo(a.activityDate));

      if (!mounted) return;
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat kegiatan.';
      });
    }
  }

  List<ActivityItem> get _filteredActivities {
    final query = _searchQuery.trim().toLowerCase();

    return _activities.where((activity) {
      final matchesStatus =
          _statusFilter == 'ALL' || activity.status == _statusFilter;
      final matchesSearch =
          query.isEmpty ||
          [
            activity.title,
            activity.description,
            activity.locationName,
            activity.creatorName,
            _typeLabel(activity.type),
            _statusLabel(activity.status),
          ].any((value) => value.toLowerCase().contains(query));

      return matchesStatus && matchesSearch;
    }).toList();
  }

  int _countByStatus(String status) =>
      _activities.where((activity) => activity.status == status).length;

  String _typeLabel(String type) => type == 'RAPAT' ? 'Rapat' : 'Kegiatan Umum';

  String _statusLabel(String status) {
    switch (status) {
      case 'ANNOUNCED':
        return 'Terbit';
      case 'COMPLETED':
        return 'Selesai';
      default:
        return 'Draft';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ANNOUNCED':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.success;
      default:
        return const Color(0xFFE65100);
    }
  }

  Future<void> _mutateActivity(
    Future<void> Function() mutation,
    String successMessage,
  ) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await mutation();
      await _fetchActivities();
      if (!mounted) return;
      _showSnack(successMessage);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal memproses kegiatan: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _confirmDelete(ActivityItem activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Hapus kegiatan?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '"${activity.title}" akan dihapus dari database.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _mutateActivity(
      () => _apiService.delete('${ApiEndpoints.activities}/${activity.id}'),
      'Kegiatan berhasil dihapus.',
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQrDialog(ActivityItem activity) {
    final qrData =
        (activity.qrCode.trim().isNotEmpty
                ? activity.qrCode.trim()
                : 'ACTIVITY-${activity.id}')
            .trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'QR Presensi',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activity.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
              const SizedBox(height: 18),
              Container(
                width: 236,
                height: 236,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: QrImageView(
                  key: ValueKey(qrData),
                  data: qrData,
                  version: QrVersions.auto,
                  size: 212,
                  padding: const EdgeInsets.all(8),
                  backgroundColor: Colors.white,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                qrData,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Absensi hanya berlaku untuk rapat yang sudah diterbitkan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredActivities = _filteredActivities;

    return RefreshIndicator(
      onRefresh: _fetchActivities,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          Text(
            'Kegiatan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildAddButton(),
          const SizedBox(height: 16),
          _buildFilterTabs(),
          const SizedBox(height: 12),
          _buildSearchField(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            _buildErrorState()
          else if (filteredActivities.isEmpty)
            _buildEmptyState()
          else
            ...filteredActivities.map(_buildActivityCard),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0056B3), Color(0xFF003C80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AGENDA WARGA',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_activities.length} Kegiatan',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMiniStat('Draft', _countByStatus('DRAFT')),
              _buildMiniStat('Terbit', _countByStatus('ANNOUNCED')),
              _buildMiniStat('Selesai', _countByStatus('COMPLETED')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddKegiatanScreen()),
          );
          if (changed == true) _fetchActivities();
        },
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: Text(
          'Jadwalkan Kegiatan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      ('ALL', 'Semua'),
      ('DRAFT', 'Draft'),
      ('ANNOUNCED', 'Terbit'),
      ('COMPLETED', 'Selesai'),
    ];

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.map((tab) {
          final selected = _statusFilter == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  tab.$2,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? AppColors.primary : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Cari judul, lokasi, pembuat, status',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.grey[400],
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Colors.grey,
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _fetchActivities,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 54, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Belum ada kegiatan',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data kegiatan akan muncul setelah tersimpan di backend.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActivityDetail(ActivityItem activity) async {
    try {
      final detail = await _apiService.getMap(
        '${ApiEndpoints.activities}/${activity.id}',
      );
      if (!mounted) return;
      await _showActivityDetailSheet(detail);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal memuat detail kegiatan.', isError: true);
    }
  }

  Future<void> _showActivityDetailSheet(Map<String, dynamic> detail) {
    final participants = detail['participants'] is List
        ? detail['participants'] as List
        : const [];
    final presentIds = participants
        .whereType<Map>()
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .toSet();
    final invited = <Map<String, dynamic>>[];

    for (final group
        in (detail['target_groups'] as List? ?? const []).whereType<Map>()) {
      for (final member
          in (group['members'] as List? ?? const []).whereType<Map>()) {
        final data = Map<String, dynamic>.from(member);
        if (!invited.any(
          (item) => item['user_id']?.toString() == data['user_id']?.toString(),
        )) {
          invited.add(data);
        }
      }
    }

    for (final user
        in (detail['invited_users'] as List? ?? const []).whereType<Map>()) {
      final data = Map<String, dynamic>.from(user);
      if (!invited.any(
        (item) => item['user_id']?.toString() == data['user_id']?.toString(),
      )) {
        invited.add(data);
      }
    }

    final rows = invited.isEmpty
        ? participants
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList()
        : invited;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0B63B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail['title']?.toString() ?? 'Kegiatan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail['description']?.toString() ?? '-',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _detailSummary('Undangan', rows.length.toString()),
                        const SizedBox(width: 10),
                        _detailSummary('Hadir', presentIds.length.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                invited.isEmpty ? 'Warga yang Sudah Hadir' : 'Daftar Anggota',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Belum ada anggota/peserta.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
                  ),
                )
              else
                ...rows.map((user) {
                  final present = presentIds.contains(
                    user['user_id']?.toString(),
                  );
                  return _participantRow(user, present, invited.isEmpty);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSummary(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _participantRow(
    Map<String, dynamic> user,
    bool present,
    bool presentOnly,
  ) {
    final name = user['full_name']?.toString() ?? 'Warga';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9F1F8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'W',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  user['phone_number']?.toString() ??
                      user['role']?.toString() ??
                      '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildBadge(
            present || presentOnly ? 'Hadir' : 'Belum hadir',
            present || presentOnly
                ? AppColors.success
                : const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityItem activity) {
    final dayFormatter = DateFormat('dd');
    final monthFormatter = DateFormat('MMM');
    final timeFormatter = DateFormat('HH:mm');
    final statusColor = _statusColor(activity.status);
    final typeIsMeeting = activity.type == 'RAPAT';
    final targetLabel =
        activity.targetGroupsCount == 0 && activity.invitedUsersCount == 0
        ? 'Seluruh warga'
        : [
            if (activity.targetGroupNames.isNotEmpty)
              activity.targetGroupNames.join(', '),
            if (activity.invitedUserNames.isNotEmpty)
              '${activity.invitedUsersCount} warga khusus',
          ].join(' + ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9F1F8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      monthFormatter
                          .format(activity.activityDate)
                          .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      dayFormatter.format(activity.activityDate),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0D1B2A),
                            ),
                          ),
                        ),
                        _buildBadge(_statusLabel(activity.status), statusColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildIconText(
                      Icons.event_note_rounded,
                      activity.description,
                    ),
                    _buildIconText(
                      Icons.location_on_outlined,
                      activity.locationName,
                    ),
                    _buildIconText(
                      Icons.person_outline_rounded,
                      activity.creatorName,
                    ),
                    _buildIconText(
                      Icons.access_time_rounded,
                      '${timeFormatter.format(activity.activityDate)} WIB',
                    ),
                    _buildIconText(Icons.groups_rounded, targetLabel),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildBadge(
                _typeLabel(activity.type),
                typeIsMeeting ? AppColors.primary : AppColors.success,
              ),
              const SizedBox(width: 8),
              if (typeIsMeeting)
                _buildBadge(
                  '${activity.participantsCount} hadir',
                  const Color(0xFF6B7280),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showActivityDetail(activity),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(
                    'Detail',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: typeIsMeeting && activity.status == 'ANNOUNCED'
                      ? () => _showQrDialog(activity)
                      : null,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: Text(
                    typeIsMeeting ? 'QR Presensi' : 'Tanpa Absensi',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildPopupActions(activity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopupActions(ActivityItem activity) {
    return PopupMenuButton<String>(
      enabled: !_isMutating,
      onSelected: (value) {
        if (value == 'announce') {
          _mutateActivity(
            () => _apiService
                .post('${ApiEndpoints.activities}/${activity.id}/announce', {})
                .then((_) {}),
            'Kegiatan berhasil diumumkan.',
          );
        } else if (value == 'complete') {
          _mutateActivity(
            () => _apiService
                .post('${ApiEndpoints.activities}/${activity.id}/complete', {})
                .then((_) {}),
            'Kegiatan berhasil diselesaikan.',
          );
        } else if (value == 'delete') {
          _confirmDelete(activity);
        }
      },
      itemBuilder: (context) => [
        if (activity.status == 'DRAFT')
          const PopupMenuItem(value: 'announce', child: Text('Umumkan')),
        if (activity.status == 'ANNOUNCED')
          const PopupMenuItem(value: 'complete', child: Text('Tandai selesai')),
        const PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
      child: Container(
        height: 40,
        width: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.more_horiz_rounded, color: AppColors.primary),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
