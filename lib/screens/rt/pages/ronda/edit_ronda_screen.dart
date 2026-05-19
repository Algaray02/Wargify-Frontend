import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import 'edit_checkpoints_screen.dart';

class EditRondaScreen extends StatefulWidget {
  final String groupId;
  final String coordinatorId;
  final String dateStr;
  final String status;

  const EditRondaScreen({
    super.key,
    required this.groupId,
    required this.coordinatorId,
    required this.dateStr,
    required this.status,
  });

  @override
  State<EditRondaScreen> createState() => _EditRondaScreenState();
}

class _EditRondaScreenState extends State<EditRondaScreen> {
  late String _selectedGroup;
  late String _selectedCoordinator;
  late String _dateStr;
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 2, minute: 0);

  final List<String> _groups = ['Regu Yakuzs', 'Regu Elang', 'Regu Mawar', 'Regu Rajawali'];
  
  final List<Map<String, String>> _members = [
    {'name': 'Agus (Pak RW)', 'avatar': 'https://i.pravatar.cc/150?u=agus'},
    {'name': 'Siti (Bu RT)', 'avatar': 'https://i.pravatar.cc/150?u=siti'},
    {'name': 'Budi Santoso', 'avatar': 'https://i.pravatar.cc/150?u=budi'},
    {'name': 'Dewi', 'avatar': 'https://i.pravatar.cc/150?u=dewi'},
    {'name': 'Pak Doni', 'avatar': 'https://i.pravatar.cc/150?u=doni'},
  ];
  
  final List<Map<String, dynamic>> _checkpoints = [
    {'name': 'Area Belakang', 'checked': true},
    {'name': 'Pos Utama', 'checked': true},
    {'name': 'Sektor Barat', 'checked': false},
  ];

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.groupId;
    _selectedCoordinator = widget.coordinatorId;
    _dateStr = widget.dateStr;

    // Robust fall-safe check for group dropdown
    if (!_groups.contains(_selectedGroup)) {
      _groups.add(_selectedGroup);
    }

    // Robust fall-safe check: dynamically add coordinator to list if not present to avoid assertion crash
    final exists = _members.any((member) => member['name'] == _selectedCoordinator);
    if (!exists) {
      _members.add({
        'name': _selectedCoordinator,
        'avatar': 'https://i.pravatar.cc/150?u=${_selectedCoordinator.toLowerCase().replaceAll(' ', '')}',
      });
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Date
            _buildLabel('PILIH TANGGAL'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    _dateStr,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF0D1B2A)),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF004E92)),
                ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _startTime.format(context),
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF0D1B2A)),
                              ),
                              const Spacer(),
                              const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF004E92)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _endTime.format(context),
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF0D1B2A)),
                              ),
                              const Spacer(),
                              const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF004E92)),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EEF5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGroup,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF004E92)),
                  items: _groups.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF0D1B2A))),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedGroup = val!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Member List
            _buildLabel('DAFTAR PESERTA: $_selectedGroup'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _members.map((member) => _buildMemberChip(member)).toList(),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {},
              child: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Color(0xFF004E92)),
                  const SizedBox(width: 8),
                  Text(
                    '+ Tambah Orang Lain',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF004E92),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Coordinator Selection
            _buildLabel('PILIH KOORDINATOR REGU'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF004E92).withOpacity(0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCoordinator,
                  hint: Text('Pilih Koordinator', style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF004E92)),
                  items: _members.map((member) {
                    return DropdownMenuItem<String>(
                      value: member['name'],
                      child: Text(member['name']!, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCoordinator = val!),
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
                  onPressed: () {
                    // Navigate to the beautiful drag & drop EditCheckpointsScreen!
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditCheckpointsScreen()),
                    );
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
            ..._checkpoints.map((cp) => _buildCheckpointTile(cp)).toList(),
            const SizedBox(height: 24),
            
            // Special Notes
            _buildLabel('CATATAN KHUSUS (OPSIONAL)'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Fokus patroli area belakang...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[500]),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, {
                    'groupId': _selectedGroup,
                    'coordinatorId': _selectedCoordinator,
                    'dateStr': _dateStr,
                  });
                },
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Simpan Perubahan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004E92),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildMemberChip(Map<String, String> member) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EEF5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 14, backgroundImage: NetworkImage(member['avatar']!)),
          const SizedBox(width: 8),
          Text(
            member['name']!,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0D1B2A)),
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
        title: Text(cp['name'], style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF004E92),
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
