import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../services/auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'pages/bendahara_home_page.dart';

class BendaharaMainScreen extends StatefulWidget {
  const BendaharaMainScreen({super.key});

  @override
  State<BendaharaMainScreen> createState() => _BendaharaMainScreenState();
}

class _BendaharaMainScreenState extends State<BendaharaMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BendaharaHomePage(),
    const Center(child: Text('Catat Kas')),
    const Center(child: Text('Laporan')),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Wargify Bendahara', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
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
        selectedItemColor: Colors.teal.shade700,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Kas'),
          BottomNavigationBarItem(icon: Icon(Icons.add_card), label: 'Catat'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Laporan'),
        ],
      ),
    );
  }
}
