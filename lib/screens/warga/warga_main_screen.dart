import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../services/auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'pages/warga_home_page.dart';

class WargaMainScreen extends StatefulWidget {
  const WargaMainScreen({super.key});

  @override
  State<WargaMainScreen> createState() => _WargaMainScreenState();
}

class _WargaMainScreenState extends State<WargaMainScreen> {
  int _selectedIndex = 0;

  // Placeholder untuk halaman-halaman warga kedepannya
  final List<Widget> _pages = [
    const WargaHomePage(),
    const Center(child: Text('Iuran Saya')),
    const Center(child: Text('Profil Warga')),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Wargify Warga', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authService.logout();
              if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Iuran'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
