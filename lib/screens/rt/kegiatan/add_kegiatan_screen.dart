import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/services/api_service.dart';

class CitizenGroupOption {
  final String id;
  final String name;
  final int membersCount;
  final Set<String> memberIds;

  const CitizenGroupOption({
    required this.id,
    required this.name,
    required this.membersCount,
    required this.memberIds,
  });

  factory CitizenGroupOption.fromJson(Map<String, dynamic> json) {
    final members = (json['members'] as List? ?? const [])
        .whereType<Map>()
        .map((member) => member['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    return CitizenGroupOption(
      id: json['group_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Kelompok warga',
      membersCount:
          int.tryParse('${json['members_count'] ?? members.length}') ??
          members.length,
      memberIds: members,
    );
  }
}

class UserOption {
  final String id;
  final String name;
  final String role;

  const UserOption({required this.id, required this.name, required this.role});

  factory UserOption.fromJson(Map<String, dynamic> json) {
    return UserOption(
      id: json['user_id']?.toString() ?? '',
      name: json['full_name']?.toString() ?? 'Warga',
      role: json['role']?.toString() ?? 'WARGA',
    );
  }
}

class HouseholdOption {
  final String id;
  final String blockNumber;
  final String houseNumber;
  final String qrCodeData;

  const HouseholdOption({
    required this.id,
    required this.blockNumber,
    required this.houseNumber,
    required this.qrCodeData,
  });

  String get label => 'Blok $blockNumber No. $houseNumber';

  factory HouseholdOption.fromJson(Map<String, dynamic> json) {
    return HouseholdOption(
      id: json['household_id']?.toString() ?? '',
      blockNumber: json['block_number']?.toString() ?? '-',
      houseNumber: json['house_number']?.toString() ?? '-',
      qrCodeData: json['qr_code_data']?.toString() ?? '',
    );
  }
}

class AddKegiatanScreen extends StatefulWidget {
  const AddKegiatanScreen({super.key});

  @override
  State<AddKegiatanScreen> createState() => _AddKegiatanScreenState();
}

class _AddKegiatanScreenState extends State<AddKegiatanScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();

  bool _isLoadingOptions = true;
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedType = 'RAPAT';
  String _locationMode = 'custom';
  bool _targetAll = true;
  String _userSearch = '';
  List<CitizenGroupOption> _groups = [];
  List<UserOption> _users = [];
  List<HouseholdOption> _households = [];
  String? _selectedHouseholdId;
  final Set<String> _selectedGroupIds = {};
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOptions() async {
    try {
      final result = await Future.wait([
        _apiService.getList(ApiEndpoints.citizenGroups),
        _apiService.getList(ApiEndpoints.users),
        _apiService.getList(ApiEndpoints.households),
      ]);

      final groups = result[0]
          .whereType<Map>()
          .map(
            (row) =>
                CitizenGroupOption.fromJson(Map<String, dynamic>.from(row)),
          )
          .where((group) => group.id.isNotEmpty)
          .toList();
      final users =
          result[1]
              .whereType<Map>()
              .map((row) => UserOption.fromJson(Map<String, dynamic>.from(row)))
              .where((user) => user.id.isNotEmpty && user.role != 'SUPERADMIN')
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      final households =
          result[2]
              .whereType<Map>()
              .map(
                (row) =>
                    HouseholdOption.fromJson(Map<String, dynamic>.from(row)),
              )
              .where((household) => household.id.isNotEmpty)
              .toList()
            ..sort((a, b) {
              final blockCompare = a.blockNumber.compareTo(b.blockNumber);
              if (blockCompare != 0) return blockCompare;
              return a.houseNumber.compareTo(b.houseNumber);
            });

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _users = users;
        _households = households;
        _isLoadingOptions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingOptions = false);
      _showSnack(
        'Gagal memuat kelompok, warga, atau rumah: $error',
        isError: true,
      );
    }
  }

  DateTime _activityDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final selectedHousehold = _selectedHousehold;
    final usesHouseholdLocation =
        _selectedType == 'RAPAT' && _locationMode == 'household';
    final location = usesHouseholdLocation
        ? selectedHousehold?.label ?? ''
        : _locationController.text.trim();

    if (title.isEmpty || description.isEmpty || location.isEmpty) {
      _showSnack('Judul, deskripsi, dan lokasi wajib diisi.', isError: true);
      return;
    }

    if (usesHouseholdLocation && selectedHousehold == null) {
      _showSnack('Pilih rumah warga untuk lokasi rapat.', isError: true);
      return;
    }

    if (!_targetAll && _selectedGroupIds.isEmpty && _selectedUserIds.isEmpty) {
      _showSnack('Pilih minimal satu kelompok atau warga.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _apiService.post(ApiEndpoints.activities, {
        'type': _selectedType,
        'title': title,
        'description': description,
        'activity_date': _activityDateTime().toIso8601String(),
        'location_name': location,
        'household_id': usesHouseholdLocation ? selectedHousehold?.id : null,
        'target_group_ids': _targetAll
            ? <String>[]
            : _selectedGroupIds.toList(),
        'target_user_ids': _targetAll
            ? <String>[]
            : _selectedUserIds.difference(_selectedGroupMemberIds).toList(),
      });

      if (!mounted) return;
      _showSnack('Draft kegiatan berhasil dibuat.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal menjadwalkan kegiatan: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  List<UserOption> get _filteredUsers {
    final query = _userSearch.trim().toLowerCase();
    return _users.where((user) {
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();
  }

  Set<String> get _selectedGroupMemberIds {
    return _groups
        .where((group) => _selectedGroupIds.contains(group.id))
        .expand((group) => group.memberIds)
        .toSet();
  }

  HouseholdOption? get _selectedHousehold {
    for (final household in _households) {
      if (household.id == _selectedHouseholdId) return household;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Jadwalkan Kegiatan',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Kegiatan Baru',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kegiatan akan tersimpan sebagai draft. Terbitkan dari daftar kegiatan saat siap diumumkan.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildCard(
            children: [
              _buildLabel('Judul'),
              _buildTextField(
                controller: _titleController,
                hint: 'Contoh: Rapat Koordinasi RT',
              ),
              const SizedBox(height: 16),
              _buildLabel('Deskripsi'),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Tuliskan agenda atau informasi kegiatan',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildLabel('Tipe kegiatan'),
              _buildTypeSelector(),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 16),
              _buildDateTimePicker(),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            children: [
              _buildLabel('Target undangan'),
              _buildTargetScopeToggle(),
              const SizedBox(height: 14),
              if (_isLoadingOptions)
                const Center(child: CircularProgressIndicator())
              else if (_targetAll)
                _buildAllTargetInfo()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Kelompok warga'),
                    _buildGroupPicker(),
                    const SizedBox(height: 16),
                    _buildLabel('Warga tertentu'),
                    _buildUserPicker(),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSubmitting ? 'Menyimpan...' : 'Simpan Draft',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.grey[600],
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.grey[400],
        ),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FBFE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1EAF3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1EAF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final options = [
      ('RAPAT', 'Rapat', Icons.groups_2_rounded),
      ('KEGIATAN_UMUM', 'Kegiatan Umum', Icons.event_available_rounded),
    ];

    return Row(
      children: options.map((option) {
        final selected = _selectedType == option.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedType = option.$1;
              if (_selectedType != 'RAPAT') {
                _locationMode = 'custom';
                _selectedHouseholdId = null;
              }
            }),
            child: Container(
              margin: EdgeInsets.only(right: option.$1 == 'RAPAT' ? 8 : 0),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : const Color(0xFFF8FBFE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE1EAF3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    option.$3,
                    color: selected ? AppColors.primary : Colors.grey[500],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.$2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.primary : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Lokasi'),
        if (_selectedType == 'RAPAT') ...[
          _buildLocationModeSelector(),
          const SizedBox(height: 12),
        ],
        if (_selectedType == 'RAPAT' && _locationMode == 'household')
          _buildHouseholdDropdown()
        else ...[
          _buildTextField(
            controller: _locationController,
            hint: _selectedType == 'RAPAT'
                ? 'Balai Warga / Pos RT / Lokasi bebas'
                : 'Lapangan / Balai Warga / Area kegiatan',
            icon: Icons.location_on_outlined,
          ),
          if (_selectedType != 'RAPAT') ...[
            const SizedBox(height: 8),
            _buildInlineInfo(
              icon: Icons.qr_code_2_rounded,
              message: 'Kegiatan umum tidak memakai QR presensi.',
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLocationModeSelector() {
    final options = [
      ('custom', 'Lokasi bebas', Icons.edit_location_alt_rounded),
      ('household', 'Rumah warga', Icons.home_rounded),
    ];

    return Row(
      children: options.map((option) {
        final selected = _locationMode == option.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _locationMode = option.$1),
            child: Container(
              margin: EdgeInsets.only(right: option.$1 == 'custom' ? 8 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : const Color(0xFFF8FBFE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE1EAF3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    option.$3,
                    size: 18,
                    color: selected ? AppColors.primary : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      option.$2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected ? AppColors.primary : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHouseholdDropdown() {
    if (_isLoadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_households.isEmpty) {
      return _buildEmptyOption('Belum ada data rumah warga.');
    }

    final selectedHousehold = _selectedHousehold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1EAF3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedHouseholdId,
              isExpanded: true,
              hint: Text(
                'Pilih rumah warga',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _households.map((household) {
                return DropdownMenuItem<String>(
                  value: household.id,
                  child: Text(
                    household.label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedHouseholdId = value);
              },
            ),
          ),
        ),
        if (selectedHousehold != null) ...[
          const SizedBox(height: 8),
          _buildInlineInfo(
            icon: Icons.qr_code_2_rounded,
            message: selectedHousehold.qrCodeData.isEmpty
                ? 'QR presensi akan memakai QR rumah ini.'
                : 'QR presensi akan memakai ${selectedHousehold.qrCodeData}.',
          ),
        ],
      ],
    );
  }

  Widget _buildInlineInfo({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1EAF3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              child: _buildPickerValue(
                Icons.calendar_today_outlined,
                'Tanggal',
                DateFormat('dd MMM yyyy').format(_selectedDate),
              ),
            ),
          ),
          Container(width: 1, height: 42, color: const Color(0xFFE1EAF3)),
          Expanded(
            child: InkWell(
              onTap: _pickTime,
              child: _buildPickerValue(
                Icons.access_time_rounded,
                'Jam',
                _selectedTime.format(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerValue(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetScopeToggle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _targetAll
                ? 'Diumumkan ke seluruh warga'
                : 'Pilih kelompok dan/atau warga tertentu',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D1B2A),
            ),
          ),
        ),
        Switch(
          value: !_targetAll,
          activeThumbColor: AppColors.primary,
          onChanged: (value) => setState(() {
            _targetAll = !value;
            if (_targetAll) {
              _selectedGroupIds.clear();
              _selectedUserIds.clear();
              _userSearchController.clear();
              _userSearch = '';
            }
          }),
        ),
      ],
    );
  }

  Widget _buildSelectionSummary() {
    final groupCount = _selectedGroupIds.length;
    final userCount = _selectedUserIds.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        groupCount == 0 && userCount == 0
            ? 'Belum ada target khusus yang dipilih.'
            : '$groupCount kelompok dan $userCount warga dipilih.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildGroupPicker() {
    if (_groups.isEmpty) {
      return _buildEmptyOption('Belum ada kelompok warga.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionSummary(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _groups.map((group) {
            final selected = _selectedGroupIds.contains(group.id);
            return FilterChip(
              selected: selected,
              label: Text('${group.name} (${group.membersCount})'),
              onSelected: (value) => setState(() {
                if (value) {
                  _selectedGroupIds.add(group.id);
                } else {
                  _selectedGroupIds.remove(group.id);
                }
                _selectedUserIds.removeAll(_selectedGroupMemberIds);
              }),
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              checkmarkColor: AppColors.primary,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : Colors.grey[700],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUserPicker() {
    final users = _filteredUsers;
    final selectedGroupMemberIds = _selectedGroupMemberIds;

    return Column(
      children: [
        TextField(
          controller: _userSearchController,
          onChanged: (value) => setState(() => _userSearch = value),
          decoration: InputDecoration(
            hintText: 'Cari nama warga',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: const Color(0xFFF8FBFE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE1EAF3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE1EAF3)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (users.isEmpty)
          _buildEmptyOption('Tidak ada warga yang cocok.')
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                final includedByGroup = selectedGroupMemberIds.contains(
                  user.id,
                );
                final selected =
                    !includedByGroup && _selectedUserIds.contains(user.id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: includedByGroup
                      ? null
                      : (value) => setState(() {
                          if (value == true) {
                            _selectedUserIds.add(user.id);
                          } else {
                            _selectedUserIds.remove(user.id);
                          }
                        }),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: Text(
                    user.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    includedByGroup
                        ? 'Sudah termasuk dari kelompok yang dipilih'
                        : user.role.replaceAll('_', ' '),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAllTargetInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1EAF3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kegiatan akan ditujukan ke seluruh warga. Aktifkan target khusus jika ingin memilih kelompok dan warga tertentu sekaligus.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D1B2A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOption(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1EAF3)),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
