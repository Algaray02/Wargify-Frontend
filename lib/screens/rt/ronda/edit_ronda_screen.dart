import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/services/api_service.dart';

import '../../../core/constants/colors.dart';
import 'edit_checkpoints_screen.dart';

class EditRondaScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;

  const EditRondaScreen({super.key, required this.schedule});

  @override
  State<EditRondaScreen> createState() => _EditRondaScreenState();
}

class _EditRondaScreenState extends State<EditRondaScreen> {
  final ApiService _apiService = ApiService();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 2, minute: 0);
  String? _selectedGroupId;
  String? _selectedCoordinatorId;
  String _selectedStatus = 'SCHEDULED';
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _checkpoints = [];

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
    _selectedDate =
        DateTime.tryParse('${schedule['schedule_date']}') ?? DateTime.now();

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
        _apiService.getList(ApiEndpoints.rondaCheckpoints),
      ]);
      final groups = (results[0])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final selectedCheckpointIds = widget.schedule['checkpoints'] is List
          ? (widget.schedule['checkpoints'] as List)
                .map((row) => Map<String, dynamic>.from(row as Map))
                .map((row) => row['checkpoint_id']?.toString())
                .whereType<String>()
                .toSet()
          : <String>{};
      final checkpoints = (results[1]).map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        data['checked'] = selectedCheckpointIds.contains(
          data['checkpoint_id']?.toString(),
        );
        return data;
      }).toList();

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _checkpoints = checkpoints;
        _syncMembers(keepCoordinator: true);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Gagal memuat data ronda: $error', true);
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

  Future<void> _submit() async {
    final scheduleId = widget.schedule['schedule_id']?.toString();
    if (scheduleId == null ||
        _selectedGroupId == null ||
        _selectedCoordinatorId == null ||
        _isSubmitting) {
      _showSnack('Regu dan koordinator harus dipilih.', true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final checkpointIds = _checkpoints
          .where((checkpoint) => checkpoint['checked'] == true)
          .map((checkpoint) => checkpoint['checkpoint_id']?.toString())
          .whereType<String>()
          .toList();
      await _apiService.patch('${ApiEndpoints.rondaSchedules}/$scheduleId', {
        'group_id': _selectedGroupId,
        'coordinator_id': _selectedCoordinatorId,
        'schedule_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'shift_start': _combine(_selectedDate, _startTime).toIso8601String(),
        'shift_end': _combine(
          _selectedDate,
          _endTime,
          nextDayIfEarlier: true,
        ).toIso8601String(),
        'status': _selectedStatus,
        'checkpoint_ids': checkpointIds,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showSnack('Gagal menyimpan perubahan: $error', true);
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
                  _buildLabel('PILIH TANGGAL'),
                  const SizedBox(height: 12),
                  _buildDatePicker(),
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('PILIH CHECKPOINT / WILAYAH'),
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EditCheckpointsScreen(),
                            ),
                          );
                          _loadOptions();
                        },
                        child: Text(
                          'Edit Checkpoint',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF004E92),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._checkpoints.map(_buildCheckpointTile),
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

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: _fieldContainer(
        Row(
          children: [
            Text(
              DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF0D1B2A),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: Color(0xFF004E92),
            ),
          ],
        ),
      ),
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

  Widget _buildCheckpointTile(Map<String, dynamic> cp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: cp['checked'] == true,
        onChanged: (val) => setState(() => cp['checked'] = val),
        title: Text(
          cp['name']?.toString() ?? '-',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          cp['qr_code_data']?.toString() ?? '',
          style: GoogleFonts.plusJakartaSans(fontSize: 11),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF004E92),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
