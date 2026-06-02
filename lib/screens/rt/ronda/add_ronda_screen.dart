import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';
import 'edit_checkpoints_screen.dart';

class AddRondaScreen extends StatefulWidget {
  const AddRondaScreen({super.key});

  @override
  State<AddRondaScreen> createState() => _AddRondaScreenState();
}

class _AddRondaScreenState extends State<AddRondaScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _groupNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 2, minute: 0);
  String? _selectedGroupId;
  String? _selectedCoordinatorId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _checkpoints = [];

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        _apiService.getList(ApiEndpoints.rondaGroups),
        _apiService.getList(ApiEndpoints.rondaCheckpoints),
        _apiService.getList(ApiEndpoints.users),
      ]);
      final groups = (results[0])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final checkpoints = (results[1]).map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        data['checked'] = true;
        return data;
      }).toList();
      final users = (results[2])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .where((user) => user['role']?.toString() != 'BENDAHARA')
          .toList();

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _users = users;
        _checkpoints = checkpoints;
        if (_selectedGroupId == null ||
            !_groups.any(
              (group) => group['group_id']?.toString() == _selectedGroupId,
            )) {
          _selectedGroupId = groups.isNotEmpty
              ? groups.first['group_id']?.toString()
              : null;
        }
        _syncMembers();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Gagal memuat data ronda: $error', isError: true);
    }
  }

  void _syncMembers() {
    final group = _groups.firstWhere(
      (item) => item['group_id']?.toString() == _selectedGroupId,
      orElse: () => {},
    );
    final members = group['members'];
    _members = members is List
        ? members.map((row) => Map<String, dynamic>.from(row as Map)).toList()
        : [];
    _selectedCoordinatorId = _members.isNotEmpty
        ? _members.first['user_id']?.toString()
        : null;
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
    if (_isSubmitting) {
      return;
    }
    if (_selectedGroupId == null) {
      _showSnack('Buat atau pilih regu ronda terlebih dahulu.', isError: true);
      return;
    }
    if (_selectedCoordinatorId == null) {
      _showSnack('Pilih koordinator regu terlebih dahulu.', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final checkpointIds = _checkpoints
          .where((checkpoint) => checkpoint['checked'] == true)
          .map((checkpoint) => checkpoint['checkpoint_id']?.toString())
          .whereType<String>()
          .toList();
      await _apiService.post(ApiEndpoints.rondaSchedules, {
        'group_id': _selectedGroupId,
        'coordinator_id': _selectedCoordinatorId,
        'schedule_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'shift_start': _combine(_selectedDate, _startTime).toIso8601String(),
        'shift_end': _combine(
          _selectedDate,
          _endTime,
          nextDayIfEarlier: true,
        ).toIso8601String(),
        'status': 'SCHEDULED',
        'checkpoint_ids': checkpointIds,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan jadwal ronda: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createGroup(List<String> memberIds) async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Nama regu ronda wajib diisi.', isError: true);
      return;
    }

    final group = await _apiService.post(ApiEndpoints.rondaGroups, {
      'name': name,
      'member_ids': memberIds,
    });
    if (!mounted) return;
    setState(() {
      _groups.insert(0, group);
      _selectedGroupId = group['group_id']?.toString();
      _groupNameController.clear();
      _syncMembers();
    });
    _showSnack('Regu ronda berhasil dibuat.');
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> _showAddGroupSheet() async {
    final selectedMemberIds = <String>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                ),
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tambah Regu Ronda',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D1B2A),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        hintText: 'Nama regu',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF0F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('PILIH ANGGOTA REGU'),
                    const SizedBox(height: 8),
                    Flexible(
                      child: _users.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada data warga.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final userId = user['user_id']?.toString();
                                final checked =
                                    userId != null &&
                                    selectedMemberIds.contains(userId);
                                return CheckboxListTile(
                                  value: checked,
                                  activeColor: AppColors.primary,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    user['full_name']?.toString() ?? '-',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    user['role']?.toString() ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onChanged: userId == null
                                      ? null
                                      : (value) {
                                          setModalState(() {
                                            if (value == true) {
                                              selectedMemberIds.add(userId);
                                            } else {
                                              selectedMemberIds.remove(userId);
                                            }
                                          });
                                        },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _createGroup(selectedMemberIds.toList());
                            if (context.mounted) Navigator.pop(context);
                          } catch (error) {
                            if (!mounted) return;
                            _showSnack(
                              'Gagal membuat regu ronda: $error',
                              isError: true,
                            );
                          }
                        },
                        icon: const Icon(Icons.group_add_rounded, size: 20),
                        label: Text(
                          'Simpan Regu',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
          'Tambah Jadwal Ronda',
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
                  // Select Date
                  _buildLabel('PILIH TANGGAL'),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat(
                              'EEEE, dd MMM yyyy',
                            ).format(_selectedDate),
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
                  ),
                  const SizedBox(height: 24),

                  // Select Time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('JAM MULAI'),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime,
                                );
                                if (time != null) {
                                  setState(() => _startTime = time);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _startTime.format(context),
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
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('JAM SELESAI'),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime,
                                );
                                if (time != null) {
                                  setState(() => _endTime = time);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _endTime.format(context),
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Select Group
                  _buildLabel('PILIH REGU KELOMPOK'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5EEF5)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGroupId,
                              hint: Text(
                                'Pilih regu ronda',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                ),
                              ),
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
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: const Color(0xFF0D1B2A),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() {
                                _selectedGroupId = val;
                                _syncMembers();
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: _showAddGroupSheet,
                        icon: const Icon(Icons.group_add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          fixedSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Member List
                  _buildLabel('DAFTAR PESERTA'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _members
                        .map((member) => _buildMemberChip(member))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_members.isEmpty)
                    Text(
                      'Regu ini belum memiliki anggota.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Coordinator Selection
                  _buildLabel('PILIH KOORDINATOR REGU'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF004E92).withOpacity(0.5),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
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
                        onChanged: (val) =>
                            setState(() => _selectedCoordinatorId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Checkpoints
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
                  ..._checkpoints.map((cp) => _buildCheckpointTile(cp)),
                  const SizedBox(height: 32),

                  // Submit Button
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
                        _isSubmitting ? 'Menyimpan...' : 'Simpan Jadwal',
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
                        elevation: 4,
                        shadowColor: const Color(0xFF004E92).withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
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
          const SizedBox(width: 4),
          Icon(Icons.close_rounded, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
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
        value: cp['checked'],
        onChanged: (val) => setState(() => cp['checked'] = val),
        title: Text(
          cp['name']?.toString() ?? '-',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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
