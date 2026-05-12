import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../services/auth/auth_service.dart';
import '../../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'pages/bendahara_home_page.dart';
import 'pages/activity/activity_screen.dart';
import 'pages/residents/residents_screen.dart';
import 'pages/audit/audit_screen.dart';
import 'pages/scan/attendance_scanner_screen.dart';

class BendaharaMainScreen extends StatefulWidget {
  final UserModel user;
  const BendaharaMainScreen({super.key, required this.user});

  @override
  State<BendaharaMainScreen> createState() => _BendaharaMainScreenState();
}

class _BendaharaMainScreenState extends State<BendaharaMainScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BendaharaHomePage(user: widget.user),
      const ActivityScreen(),
      const ResidentsScreen(),
      const AuditScreen(),
    ];
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: AppColors.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'logout') {
                          _handleLogout();
                        }
                      },
                      offset: const Offset(0, 50),
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text('Lihat Profil', style: GoogleFonts.plusJakartaSans()),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout, size: 20, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Keluar', style: GoogleFonts.plusJakartaSans(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://ui-avatars.com/api/?name=${widget.user.fullName}&background=00468B&color=fff',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'WARGIFY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.notifications_none_rounded, size: 28),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 65,
        width: 65,
        margin: const EdgeInsets.only(top: 30),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AttendanceScannerScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFF8FBFE),
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_rounded, 'Beranda', 0),
              _buildNavItem(Icons.receipt_long_rounded, 'Aktivitas', 1),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(Icons.people_alt_rounded, 'Warga', 2),
              _buildNavItem(Icons.bar_chart_rounded, 'AUDIT', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
