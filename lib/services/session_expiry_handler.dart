import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import 'secure_session_storage.dart';

class SessionExpiryHandler {
  SessionExpiryHandler._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static bool _isHandling = false;

  static Future<void> forceLogout({String? message}) async {
    if (_isHandling) return;
    _isHandling = true;

    await SecureSessionStorage().clear();

    final navigator = navigatorKey.currentState;

    if (message != null && message.isNotEmpty) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    navigator?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );

    Future.delayed(const Duration(seconds: 1), () {
      _isHandling = false;
    });
  }
}
