import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import 'edit_checkpoints_screen.dart';

class ManageRondaScreen extends StatefulWidget {
  const ManageRondaScreen({super.key});

  @override
  State<ManageRondaScreen> createState() => _ManageRondaScreenState();
}

class _ManageRondaScreenState extends State<ManageRondaScreen> {
  // Mock Active Squad Data
  String _selectedSquad = 'REGU ELANG';
  String _startTime = '22:00';
  String _endTime = '04:00';
  bool _sendReminder = true;
  
  final List<String> _members = ['Bpk. Ahmad', 'Bpk. Doni', 'Bpk. Bambang', 'Ibu Rini'];
  final List<String> _allSquads = ['REGU ELANG', 'REGU GARUDA', 'REGU RAJAWALI', 'REGU MACAN'];
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  final List<String> _activeDays = ['Senin', 'Rabu', 'Jumat'];

  void _addMember() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Tambah Anggota Ronda',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Nama lengkap warga...',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _members.add(name);
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Simpan', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Big Banner Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4C81), Color(0xFF1B4F72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F4C81).withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PENGATURAN PATROLI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola shift, anggota regu, dan checkpoint ronda secara sentral.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Short-cut to Checkpoint Settings (Premium Glowing Button)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditCheckpointsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.pin_drop_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atur Checkpoint Patroli',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D1B2A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Edit koordinasi peta dan titik penanda QR warga.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 1. Shift Time Picker Settings
            Text(
              'Shift & Jam Operasional',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Waktu Mulai', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[700])),
                      DropdownButton<String>(
                        value: _startTime,
                        underline: const SizedBox(),
                        onChanged: (val) {
                          if (val != null) setState(() => _startTime = val);
                        },
                        items: ['20:00', '21:00', '22:00', '23:00'].map((time) {
                          return DropdownMenuItem(value: time, child: Text(time, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)));
                        }).toList(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Waktu Selesai', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[700])),
                      DropdownButton<String>(
                        value: _endTime,
                        underline: const SizedBox(),
                        onChanged: (val) {
                          if (val != null) setState(() => _endTime = val);
                        },
                        items: ['03:00', '04:00', '05:00', '06:00'].map((time) {
                          return DropdownMenuItem(value: time, child: Text(time, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)));
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. Active Days Selector
            Text(
              'Hari Ronda Aktif',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _days.map((day) {
                final isSelected = _activeDays.contains(day);
                return FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  checkmarkColor: AppColors.primary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? AppColors.primary.withOpacity(0.4) : Colors.grey.withOpacity(0.1)),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _activeDays.add(day);
                      } else {
                        _activeDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // 3. Regu Ronda / Active Squad Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Regu Ronda Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedSquad,
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSquad = val);
                  },
                  items: _allSquads.map((squad) {
                    return DropdownMenuItem(
                      value: squad,
                      child: Text(
                        squad,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Squad Members List
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Anggota Regu (${_members.length})',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[500]),
                      ),
                      TextButton.icon(
                        onPressed: _addMember,
                        icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                        label: Text('Tambah', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                _members[index][0],
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _members[index],
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D1B2A)),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                              onPressed: () {
                                setState(() {
                                  _members.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Notifications/Reminders
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: Text(
                  'Kirim Pengingat Otomatis',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0D1B2A)),
                ),
                subtitle: Text(
                  'Kirim notifikasi pengingat ke warga H-1 sebelum jaga.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500]),
                ),
                value: _sendReminder,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _sendReminder = val),
              ),
            ),
            const SizedBox(height: 40),

            // Save Big Button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Jadwal ronda berhasil diperbarui!', style: GoogleFonts.plusJakartaSans()),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Text(
                'Simpan Pengaturan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
