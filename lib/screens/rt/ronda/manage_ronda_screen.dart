import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'add_ronda_screen.dart';
import 'edit_ronda_screen.dart';

class RondaSchedule {
  final String id;
  final String groupId;
  final String coordinatorId;
  final String dateStr;
  final String shiftHours;
  final String status; // SCHEDULED, ONGOING, COMPLETED, MISSED
  final int checkpoints;
  final int scanned;
  final Map<String, dynamic> raw;

  RondaSchedule({
    required this.id,
    required this.groupId,
    required this.coordinatorId,
    required this.dateStr,
    required this.shiftHours,
    required this.status,
    this.checkpoints = 0,
    this.scanned = 0,
    this.raw = const <String, dynamic>{},
  });

  RondaSchedule copyWith({
    String? id,
    String? groupId,
    String? coordinatorId,
    String? dateStr,
    String? shiftHours,
    String? status,
    int? checkpoints,
    int? scanned,
    Map<String, dynamic>? raw,
  }) {
    return RondaSchedule(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      dateStr: dateStr ?? this.dateStr,
      shiftHours: shiftHours ?? this.shiftHours,
      status: status ?? this.status,
      checkpoints: checkpoints ?? this.checkpoints,
      scanned: scanned ?? this.scanned,
      raw: raw ?? this.raw,
    );
  }
}

class ManageRondaScreen extends StatefulWidget {
  const ManageRondaScreen({super.key});

  @override
  State<ManageRondaScreen> createState() => _ManageRondaScreenState();
}

class _ManageRondaScreenState extends State<ManageRondaScreen> {
  final ApiService _apiService = ApiService();
  String _selectedFilter = 'SEMUA';
  bool _isLoading = true;

  final List<RondaSchedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    try {
      final rows = await _apiService.getList(ApiEndpoints.rondaSchedules);
      final dateFormatter = DateFormat('EEEE, dd MMM yyyy');
      final timeFormatter = DateFormat('HH:mm');
      final items = rows.map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        final group = Map<String, dynamic>.from((data['group'] ?? {}) as Map);
        final coordinator = Map<String, dynamic>.from(
          (data['coordinator'] ?? {}) as Map,
        );
        final checkpoints = data['checkpoints'] is List
            ? data['checkpoints'] as List
            : const [];
        final logs = data['checkpoint_logs'] is List
            ? data['checkpoint_logs'] as List
            : const [];
        final start = DateTime.tryParse('${data['shift_start']}');
        final end = DateTime.tryParse('${data['shift_end']}');
        final date =
            DateTime.tryParse('${data['schedule_date']}') ??
            start ??
            DateTime.now();

        return RondaSchedule(
          id: data['schedule_id']?.toString() ?? '',
          groupId: group['name']?.toString() ?? '-',
          coordinatorId: coordinator['full_name']?.toString() ?? '-',
          dateStr: dateFormatter.format(date),
          shiftHours: start != null && end != null
              ? '${timeFormatter.format(start)} - ${timeFormatter.format(end)}'
              : '-',
          status: data['status']?.toString() ?? 'SCHEDULED',
          checkpoints: checkpoints.length,
          scanned: logs.length,
          raw: data,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _schedules
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<RondaSchedule> _getFilteredSchedules() {
    if (_selectedFilter == 'SEMUA') return _schedules;
    return _schedules.where((s) => s.status == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SCHEDULED':
        return const Color(0xFF64748B); // Slate Grey
      case 'ONGOING':
        return const Color(0xFF0284C7); // Sky Blue
      case 'COMPLETED':
        return AppColors.success; // Green
      case 'MISSED':
        return AppColors.danger; // Red
      default:
        return Colors.black;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'SCHEDULED':
        return const Color(0xFFF1F5F9);
      case 'ONGOING':
        return const Color(0xFFF0F9FF);
      case 'COMPLETED':
        return const Color(0xFFF0FDF4);
      case 'MISSED':
        return const Color(0xFFFEF2F2);
      default:
        return Colors.grey[100]!;
    }
  }

  Future<void> _deleteSchedule(int index) async {
    final sch = _getFilteredSchedules()[index];
    await _apiService.patch('${ApiEndpoints.rondaSchedules}/${sch.id}', {
      'status': 'MISSED',
    });
    await _fetchSchedules();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Jadwal untuk ${sch.groupId} berhasil dihapus.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSchedulePreview(RondaSchedule item) {
    final data = item.raw;
    final group = data['group'] is Map
        ? Map<String, dynamic>.from(data['group'] as Map)
        : <String, dynamic>{};
    final coordinator = data['coordinator'] is Map
        ? Map<String, dynamic>.from(data['coordinator'] as Map)
        : <String, dynamic>{};
    final checkpoints = data['checkpoints'] is List
        ? data['checkpoints'] as List
        : const [];
    final logs = data['checkpoint_logs'] is List
        ? data['checkpoint_logs'] as List
        : const [];
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        group['name']?.toString() ?? item.groupId,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(item.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(item.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildPreviewRow(
                  Icons.calendar_today_rounded,
                  'Tanggal',
                  item.dateStr,
                ),
                _buildPreviewRow(
                  Icons.access_time_rounded,
                  'Shift',
                  item.shiftHours,
                ),
                _buildPreviewRow(
                  Icons.person_pin_circle_rounded,
                  'Koordinator',
                  coordinator['full_name']?.toString() ?? item.coordinatorId,
                ),
                _buildPreviewRow(
                  Icons.groups_rounded,
                  'Anggota',
                  '${members.length} orang',
                ),
                _buildPreviewRow(
                  Icons.qr_code_scanner_rounded,
                  'Checkpoint',
                  '${logs.length}/${checkpoints.length}',
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
                    final checkpointData = Map<String, dynamic>.from(
                      checkpoint as Map,
                    );
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
                              checkpointData['name']?.toString() ?? '-',
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
    final filteredSchedules = _getFilteredSchedules();

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
                  color: Colors.black.withOpacity(0.04),
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
          'Atur Jadwal Ronda',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // Header title & count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Jadwal Ronda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                Text(
                  '${filteredSchedules.length} Jadwal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Filter Status Chips (NO checkmark!)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['SEMUA', 'SCHEDULED', 'ONGOING', 'COMPLETED', 'MISSED']
                  .map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.withOpacity(0.12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Schedules List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSchedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredSchedules.length,
                    itemBuilder: (context, index) {
                      final item = filteredSchedules[index];
                      return _buildScheduleCard(item, index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddRondaScreen()),
          );
          if (changed == true) _fetchSchedules();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          'Tambah Jadwal',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 40,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada jadwal ronda ditemukan.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Silakan tekan tombol Tambah Jadwal.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(RondaSchedule item, int index) {
    final statusColor = _getStatusColor(item.status);
    final statusBgColor = _getStatusBgColor(item.status);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showSchedulePreview(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header of Card (Group name & status badge)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.groupId,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Date & Time rows
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  item.dateStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  item.shiftHours,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Divider(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Checkpoint ${item.scanned}/${item.checkpoints}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Coordinator info & actions row
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    item.coordinatorId[0],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koordinator',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        item.coordinatorId,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditRondaScreen(schedule: item.raw),
                      ),
                    );
                    if (result == true) _fetchSchedules();
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _deleteSchedule(index),
                ),
              ],
            ),
          ],
        ),
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
}
