import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/models/user_model.dart';
import 'package:wargify/screens/auth/login_screen.dart';
import 'package:wargify/screens/profile/profile_screen.dart';
import 'package:wargify/services/auth/auth_service.dart';

class WargaHeader extends StatelessWidget implements PreferredSizeWidget {
  final UserModel? user;
  final VoidCallback? onNotificationTap;

  const WargaHeader({super.key, this.user, this.onNotificationTap});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: AppColors.background,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FutureBuilder<UserModel?>(
                  future: user == null
                      ? _loadHeaderUser(authService)
                      : Future.value(user),
                  builder: (context, snapshot) {
                    return _buildProfileMenu(
                      context,
                      authService,
                      snapshot.data,
                    );
                  },
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
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
              onPressed: onNotificationTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(
    BuildContext context,
    AuthService authService,
    UserModel? headerUser,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'logout') {
          await authService.logout();
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } else if (value == 'profile' && headerUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(user: headerUser),
            ),
          );
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
              Text(
                'Keluar',
                style: GoogleFonts.plusJakartaSans(color: Colors.red),
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
          image: headerUser != null
              ? DecorationImage(
                  image: _avatarProvider(headerUser),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: headerUser == null
            ? const Icon(Icons.person, color: AppColors.primary, size: 22)
            : null,
      ),
    );
  }

  Future<UserModel?> _loadHeaderUser(AuthService authService) async {
    try {
      return await authService.getProfile();
    } catch (_) {
      return authService.getCurrentUser();
    }
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
