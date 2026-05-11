import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/colors.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_wrapper.dart';
import 'services/auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  final bool loggedIn = await authService.isLoggedIn();
  
  runApp(MyApp(initialPage: loggedIn ? const DashboardWrapper() : const LoginScreen()));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  
  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wargify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: initialPage,
    );
  }
}