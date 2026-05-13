import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../models/user_model.dart';
import '../../services/auth/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _pushNotifications = true;

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRT = widget.user.role.toLowerCase().contains('rt');
    bool isBendahara = widget.user.role.toLowerCase().contains('bendahara');
    bool isStaff = isRT || isBendahara;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D47A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profil',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://ui-avatars.com/api/?name=${widget.user.fullName}&background=0D1B2A&color=fff&size=128',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.user.fullName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.role.toUpperCase().replaceAll('_', ' '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (!isStaff) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Blok B4, No. 12',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!isStaff) ...[
                          _buildBadge(Icons.verified, 'WARGA TERVERIFIKASI', const Color(0xFFC1F3AF), const Color(0xFF2A6B2C)),
                          _buildBadge(Icons.home, 'KEPALA KELUARGA', const Color(0xFFE3F2FD), const Color(0xFF0D47A1)),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Neighbor Section (RT only)
              if (isRT) ...[
                _buildSectionTitle('Tetangga'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tetangga',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('TAMBAH BARU'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildNeighborItem('Pak Abi', 'TETANGGA DEPAN RUMAH', 'S'),
                      const SizedBox(height: 12),
                      _buildNeighborItem('RUSDI', 'TETANGGA SEBELAH', 'R'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Preferences Section
              _buildSectionTitle('Preferensi'),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildPreferenceSwitch(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi Push',
                        value: _pushNotifications,
                        onChanged: (val) => setState(() => _pushNotifications = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Account Security Section
              _buildSectionTitle('Keamanan Akun'),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _buildSecurityCard(
                      icon: Icons.password_rounded,
                      title: 'Ubah Kata Sandi',
                      subtitle: 'Terakhir diubah 3 bulan lalu',
                      actionLabel: 'Update Keamanan',
                      iconBgColor: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF0D47A1),
                    ),
                    const SizedBox(height: 12),
                    _buildSecurityCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Autentikasi Dua Faktor',
                      subtitle: 'Aktif untuk perlindungan ekstra',
                      actionLabel: 'Kelola 2FA',
                      iconBgColor: const Color(0xFFC1F3AF).withOpacity(0.5),
                      iconColor: const Color(0xFF2A6B2C),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[50]!,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.logout_rounded, color: Colors.red[400], size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Keluar dari Akun',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0D1B2A)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        side: BorderSide(color: Colors.red[100]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('KELUAR'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          ),
        ),
      ),
    );
  }

  Widget _buildNeighborItem(String name, String relation, String initial) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(initial, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(relation, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.grey[500], letterSpacing: 0.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch({required IconData icon, required String title, required bool value, required Function(bool) onChanged}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D47A1), size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D1B2A)),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2A6B2C),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem({required IconData icon, required String title, required Widget trailing}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D47A1), size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D1B2A)),
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                actionLabel,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0D47A1)),
            ],
          ),
        ],
      ),
    );
  }
}
