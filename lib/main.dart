import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/colors.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_wrapper.dart';
import 'services/app_notification_service.dart';
import 'services/auth/auth_service.dart';
import 'services/session_expiry_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for date formatting
  await initializeDateFormatting('id', null);

  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final authService = AuthService();
  final bool loggedIn = await authService.isLoggedIn();
  if (!kIsWeb) {
    try {
      await AppNotificationService().initialize(registerToken: loggedIn);
    } catch (_) {}
  }

  runApp(
    MyApp(
      initialPage: loggedIn ? const DashboardWrapper() : const LoginScreen(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialPage;

  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SessionExpiryHandler.navigatorKey,
      scaffoldMessengerKey: SessionExpiryHandler.scaffoldMessengerKey,
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
