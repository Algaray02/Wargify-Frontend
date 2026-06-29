import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../services/auth/auth_service.dart';
import '../../../models/user_model.dart';
import 'package:wargify/screens/auth/login_screen.dart';
import 'kegiatan/kegiatan_screen.dart';
import 'gallery/gallery_screen.dart';
import 'home/home_screen.dart';
import 'home/home_qr_scanner_screen.dart';
import 'ronda/ronda_screen.dart';
import 'package:wargify/screens/profile/profile_screen.dart';
import 'package:wargify/screens/common/notifikasi/notifikasi_log_screen.dart';

class RTMainScreen extends StatefulWidget {
  final UserModel user;
  const RTMainScreen({super.key, required this.user});

  @override
  State<RTMainScreen> createState() => _RTMainScreenState();
}

class _RTMainScreenState extends State<RTMainScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();
  late UserModel _currentUser;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _pages = [
      RTHomePage(user: _currentUser),
      const KegiatanScreen(),
      const GalleryScreen(),
      const RondaScreen(),
    ];
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    try {
      final user = await _authService.getProfile();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {}
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
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          color: AppColors.background,
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'logout') {
                            _handleLogout();
                          } else if (value == 'profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileScreen(user: _currentUser),
                              ),
                            ).then((_) => _refreshProfile());
                          }
                        },
                        offset: const Offset(0, 50),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Lihat Profil',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.logout,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Keluar',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.red,
                                  ),
                                ),
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
                              image: _avatarProvider(_currentUser),
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
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotifikasiLogScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: SafeArea(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            child: Center(child: _buildQrButton()),
          ),
        ],
      ),
    );
  }

  Widget _buildQrButton() {
    return SizedBox(
      height: 65,
      width: 65,
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeQrScannerScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: const Color(0xFFF8FBFE),
      elevation: 10,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 60,
          child: Row(
            children: [
              _buildNavItem(Icons.home_rounded, 'HOME', 0),
              _buildNavItem(Icons.people_alt_rounded, 'KEGIATAN', 1),
              const SizedBox(width: 48),
              _buildNavItem(Icons.collections_bookmark_rounded, 'GALLERY', 2),
              _buildNavItem(Icons.report_gmailerrorred_rounded, 'RONDA', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  ImageProvider _avatarProvider(UserModel user) {
    if (user.profilePictureUrl.isNotEmpty) {
      return NetworkImage(user.profilePictureUrl);
    }

    final encodedName = Uri.encodeComponent(user.fullName);
    return NetworkImage(
      'https://ui-avatars.com/api/?name=$encodedName&background=00468B&color=fff',
    );
  }
}
