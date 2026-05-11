import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../services/auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'pages/rt_home_page.dart';

class RTMainScreen extends StatefulWidget {
  const RTMainScreen({super.key});

  @override
  State<RTMainScreen> createState() => _RTMainScreenState();
}

class _RTMainScreenState extends State<RTMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const RTHomePage(),
    const Center(child: Text('Data Warga')),
    const Center(child: Text('Pengumuman')),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Panel Ketua RT', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange.shade800,
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange.shade800,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Warga'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Info'),
        ],
      ),
    );
  }
}
