import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../warga/warga_main_screen.dart';
import '../rt/rt_main_screen.dart';
import '../bendahara/bendahara_main_screen.dart';

class DashboardWrapper extends StatelessWidget {
  const DashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Jika user tidak ditemukan/belum login, arahkan ke Login
        if (user == null) {
          return const LoginScreen();
        }

        // Logika Pengalihan berdasarkan Role (lowercase untuk keamanan)
        final role = user.role.toLowerCase();
        
        if (role == 'warga') {
          return const WargaMainScreen();
        } else if (role == 'ketua_rt' || role == 'rt') {
          return RTMainScreen(user: user);
        } else if (role == 'bendahara') {
          return BendaharaMainScreen(user: user);
        } else {
          // Default jika role tidak dikenali
          return Scaffold(
            body: Center(child: Text('Role "$role" tidak dikenali.')),
          );
        }
      },
    );
  }
}
