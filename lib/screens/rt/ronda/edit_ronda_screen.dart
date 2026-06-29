import 'package:wargify/core/utils/app_error.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/services/api_service.dart';

import '../../../core/constants/colors.dart';

class EditRondaScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;

  const EditRondaScreen({super.key, required this.schedule});

  @override
  State<EditRondaScreen> createState() => _EditRondaScreenState();
}

class _EditRondaScreenState extends State<EditRondaScreen> {
  final ApiService _apiService = ApiService();

  int _selectedWeekday = DateTime.now().weekday;
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 2, minute: 0);
  String? _selectedGroupId;
  String? _selectedCoordinatorId;
  String _selectedStatus = 'SCHEDULED';
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _schedules = [];
  static const List<String> _weekdayLabels = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  void initState() {
    super.initState();
    _hydrateInitialValue();
    _loadOptions();
  }

  void _hydrateInitialValue() {
    final schedule = widget.schedule;
    _selectedGroupId = schedule['group_id']?.toString();
    _selectedCoordinatorId = schedule['coordinator_id']?.toString();
    _selectedStatus = schedule['status']?.toString() ?? 'SCHEDULED';
    final scheduleDate =
        DateTime.tryParse('${schedule['schedule_date']}') ?? DateTime.now();
    _selectedWeekday = scheduleDate.weekday;

    final start = DateTime.tryParse('${schedule['shift_start']}');
    final end = DateTime.tryParse('${schedule['shift_end']}');
    if (start != null) {
      _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
    }
    if (end != null) {
      _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
    }
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        _apiService.getList(ApiEndpoints.rondaGroups),
        _apiService.getList(ApiEndpoints.rondaSchedules),
      ]);
      final groups = (results[0])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final schedules = (results[1])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _schedules = schedules;
        _syncMembers(keepCoordinator: true);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Gagal memuat data ronda: ${AppError.userFriendly(error)}', true);
    }
  }

  void _syncMembers({bool keepCoordinator = false}) {
    final group = _groups.firstWhere(
      (item) => item['group_id']?.toString() == _selectedGroupId,
      orElse: () => {},
    );
    final members = group['members'];
    _members = members is List
        ? members.map((row) => Map<String, dynamic>.from(row as Map)).toList()
        : [];
    if (!keepCoordinator ||
        !_members.any(
          (item) => item['user_id']?.toString() == _selectedCoordinatorId,
        )) {
      _selectedCoordinatorId = _members.isNotEmpty
          ? _members.first['user_id']?.toString()
          : null;
    }
  }

  DateTime _combine(
    DateTime date,
    TimeOfDay time, {
    bool nextDayIfEarlier = false,
  }) {
    var result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      _startTime.hour,
      _startTime.minute,
    );
    if (nextDayIfEarlier && result.isBefore(start)) {
      result = result.add(const Duration(days: 1));
    }
    return result;
  }

  DateTime _dateForWeekday(int weekday) {
    final today = DateTime.now();
    final daysUntilTarget = (weekday - today.weekday + 7) % 7;
    final date = today.add(Duration(days: daysUntilTarget));

    return DateTime(date.year, date.month, date.day);
  }

  bool _hasScheduleOnSelectedWeekday(String scheduleId) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return _schedules.any((schedule) {
      if (schedule['schedule_id']?.toString() == scheduleId) return false;

      final status = schedule['status']?.toString();
      if (status != 'SCHEDULED' && status != 'ONGOING') return false;

      final date = DateTime.tryParse('${schedule['schedule_date']}');
      if (date == null) return false;
      final scheduleDate = DateTime(date.year, date.month, date.day);

      return !scheduleDate.isBefore(todayDate) &&
          scheduleDate.weekday == _selectedWeekday;
    });
  }

  bool _isWeekdayTaken(int weekday) {
    final currentScheduleId = widget.schedule['schedule_id']?.toString();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return _schedules.any((schedule) {
      if (schedule['schedule_id']?.toString() == currentScheduleId) {
        return false;
      }

      final status = schedule['status']?.toString();
      if (status != 'SCHEDULED' && status != 'ONGOING') return false;

      final date = DateTime.tryParse('${schedule['schedule_date']}');
      if (date == null) return false;
      final scheduleDate = DateTime(date.year, date.month, date.day);

      return !scheduleDate.isBefore(todayDate) &&
          scheduleDate.weekday == weekday;
    });
  }

  Future<void> _submit() async {
    final scheduleId = widget.schedule['schedule_id']?.toString();
    if (scheduleId == null ||
        _selectedGroupId == null ||
        _selectedCoordinatorId == null ||
        _isSubmitting) {
      _showSnack('Regu dan koordinator harus dipilih.', true);
      return;
    }
    if (_hasScheduleOnSelectedWeekday(scheduleId)) {
      _showSnack(
        'Jadwal ronda hari ${_weekdayLabels[_selectedWeekday - 1]} sudah ada.',
        true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final scheduleDate = _dateForWeekday(_selectedWeekday);
      await _apiService.patch('${ApiEndpoints.rondaSchedules}/$scheduleId', {
        'group_id': _selectedGroupId,
        'coordinator_id': _selectedCoordinatorId,
        'schedule_date': DateFormat('yyyy-MM-dd').format(scheduleDate),
        'shift_start': _combine(scheduleDate, _startTime).toIso8601String(),
        'shift_end': _combine(
          scheduleDate,
          _endTime,
          nextDayIfEarlier: true,
        ).toIso8601String(),
        'status': _selectedStatus,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showSnack('Gagal menyimpan perubahan: ${AppError.userFriendly(error)}', true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0D1B2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Jadwal Ronda',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('PILIH HARI JADWAL'),
                  const SizedBox(height: 12),
                  _buildWeekdayPicker(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(
                          'JAM MULAI',
                          _startTime,
                          (value) => setState(() => _startTime = value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePicker(
                          'JAM SELESAI',
                          _endTime,
                          (value) => setState(() => _endTime = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('PILIH REGU KELOMPOK'),
                  const SizedBox(height: 12),
                  _buildGroupDropdown(),
                  const SizedBox(height: 24),
                  _buildLabel('DAFTAR PESERTA'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _members.map(_buildMemberChip).toList(),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('PILIH KOORDINATOR REGU'),
                  const SizedBox(height: 12),
                  _buildCoordinatorDropdown(),
                  const SizedBox(height: 24),
                  _buildLabel('STATUS JADWAL'),
                  const SizedBox(height: 12),
                  _buildStatusDropdown(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        _isSubmitting ? 'Menyimpan...' : 'Simpan Perubahan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004E92),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildWeekdayPicker() {
    return _fieldContainer(
      DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedWeekday,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF004E92),
          ),
          items: List.generate(7, (index) {
            final weekday = index + 1;
            final isTaken = _isWeekdayTaken(weekday);
            return DropdownMenuItem<int>(
              value: weekday,
              enabled: !isTaken,
              child: Text(
                isTaken
                    ? '${_weekdayLabels[index]} (sudah ada)'
                    : _weekdayLabels[index],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isTaken ? Colors.grey : const Color(0xFF0D1B2A),
                ),
              ),
            );
          }),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedWeekday = value);
            }
          },
        ),
      ),
      backgroundColor: const Color(0xFFF0F5F9),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay value,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: value,
            );
            if (picked != null) onChanged(picked);
          },
          child: _fieldContainer(
            Row(
              children: [
                Text(
                  value.format(context),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: Color(0xFF004E92),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupDropdown() {
    return _fieldContainer(
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGroupId,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF004E92),
          ),
          items: _groups.map((group) {
            return DropdownMenuItem<String>(
              value: group['group_id']?.toString(),
              child: Text(
                group['name']?.toString() ?? '-',
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() {
            _selectedGroupId = val;
            _syncMembers();
          }),
        ),
      ),
    );
  }

  Widget _buildCoordinatorDropdown() {
    return _fieldContainer(
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCoordinatorId,
          hint: Text(
            'Pilih Koordinator',
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF004E92),
          ),
          items: _members.map((member) {
            return DropdownMenuItem<String>(
              value: member['user_id']?.toString(),
              child: Text(
                member['full_name']?.toString() ?? '-',
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCoordinatorId = val),
        ),
      ),
      backgroundColor: const Color(0xFFE6F2FD),
    );
  }

  Widget _buildStatusDropdown() {
    const statuses = ['SCHEDULED', 'ONGOING', 'COMPLETED', 'MISSED'];
    return _fieldContainer(
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          items: statuses
              .map(
                (status) => DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedStatus = val!),
        ),
      ),
    );
  }

  Widget _fieldContainer(Widget child, {Color backgroundColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildMemberChip(Map<String, dynamic> member) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EEF5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(member['full_name']?.toString() ?? 'Warga')}&background=00468B&color=fff',
            ),
          ),
          const SizedBox(width: 8),
          Text(
            member['full_name']?.toString() ?? '-',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
