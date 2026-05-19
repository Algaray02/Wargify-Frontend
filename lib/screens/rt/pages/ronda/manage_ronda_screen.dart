import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import 'add_ronda_screen.dart';
import 'edit_checkpoints_screen.dart';
import 'edit_ronda_screen.dart';

class RondaSchedule {
  final String id;
  final String groupId;
  final String coordinatorId;
  final String dateStr;
  final String shiftHours;
  final String status; // SCHEDULED, ONGOING, COMPLETED, MISSED

  RondaSchedule({
    required this.id,
    required this.groupId,
    required this.coordinatorId,
    required this.dateStr,
    required this.shiftHours,
    required this.status,
  });

  RondaSchedule copyWith({
    String? id,
    String? groupId,
    String? coordinatorId,
    String? dateStr,
    String? shiftHours,
    String? status,
  }) {
    return RondaSchedule(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      dateStr: dateStr ?? this.dateStr,
      shiftHours: shiftHours ?? this.shiftHours,
      status: status ?? this.status,
    );
  }
}

class ManageRondaScreen extends StatefulWidget {
  const ManageRondaScreen({super.key});

  @override
  State<ManageRondaScreen> createState() => _ManageRondaScreenState();
}

class _ManageRondaScreenState extends State<ManageRondaScreen> {
  String _selectedFilter = 'SEMUA';

  // Mock list matching the DB table structure 'ronda_schedules'
  final List<RondaSchedule> _schedules = [
    RondaSchedule(
      id: 'sch_1',
      groupId: 'Regu Yakuzs',
      coordinatorId: 'Agus (Pak RW)',
      dateStr: 'Senin, 24 Juli 2024',
      shiftHours: '22:00 - 04:00',
      status: 'SCHEDULED',
    ),
    RondaSchedule(
      id: 'sch_2',
      groupId: 'Regu Elang',
      coordinatorId: 'Budi Santoso',
      dateStr: 'Selasa, 25 Juli 2024',
      shiftHours: '22:00 - 04:00',
      status: 'ONGOING',
    ),
    RondaSchedule(
      id: 'sch_3',
      groupId: 'Regu Mawar',
      coordinatorId: 'Siti (Bu RT)',
      dateStr: 'Minggu, 23 Juli 2024',
      shiftHours: '22:00 - 04:00',
      status: 'COMPLETED',
    ),
    RondaSchedule(
      id: 'sch_4',
      groupId: 'Regu Rajawali',
      coordinatorId: 'Pak Doni',
      dateStr: 'Sabtu, 22 Juli 2024',
      shiftHours: '22:00 - 04:00',
      status: 'MISSED',
    ),
  ];

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

  void _deleteSchedule(int index) {
    final sch = _getFilteredSchedules()[index];
    setState(() {
      _schedules.removeWhere((item) => item.id == sch.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Jadwal untuk ${sch.groupId} berhasil dihapus.', style: GoogleFonts.plusJakartaSans()),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
              children: ['SEMUA', 'SCHEDULED', 'ONGOING', 'COMPLETED', 'MISSED'].map((filter) {
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.12),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Schedules List
          Expanded(
            child: filteredSchedules.isEmpty
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
          // Navigate to existing AddRondaScreen!
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRondaScreen()),
          );
          
          // Mimic adding a new item after return (demo data fallback)
          setState(() {
            _schedules.insert(
              0,
              RondaSchedule(
                id: DateTime.now().toString(),
                groupId: 'Regu Elang',
                coordinatorId: 'Budi Santoso',
                dateStr: 'Rabu, 26 Juli 2024',
                shiftHours: '22:00 - 04:00',
                status: 'SCHEDULED',
              ),
            );
          });
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
            child: Icon(Icons.calendar_today_rounded, size: 40, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada jadwal ronda ditemukan.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            'Silakan tekan tombol Tambah Jadwal.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(RondaSchedule item, int index) {
    final statusColor = _getStatusColor(item.status);
    final statusBgColor = _getStatusBgColor(item.status);

    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
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
              const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
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

          // Coordinator info & actions row
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  item.coordinatorId[0],
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koordinator',
                      style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.grey[500]),
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
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                onPressed: () async {
                  final result = await Navigator.push<Map<String, String>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditRondaScreen(
                        groupId: item.groupId,
                        coordinatorId: item.coordinatorId,
                        dateStr: item.dateStr,
                        status: item.status,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      final idx = _schedules.indexWhere((s) => s.id == item.id);
                      if (idx != -1) {
                        _schedules[idx] = _schedules[idx].copyWith(
                          groupId: result['groupId'],
                          coordinatorId: result['coordinatorId'],
                          dateStr: result['dateStr'],
                        );
                      }
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                onPressed: () => _deleteSchedule(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
