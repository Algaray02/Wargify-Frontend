import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wargify/core/constants/colors.dart';
import 'package:wargify/screens/warga/pages/profil_page.dart';
import 'package:wargify/screens/warga/pages/notifikasi_page.dart';

class WargaHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;

  const WargaHeader({super.key, this.onNotificationTap});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilPage()),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: const Icon(Icons.person, color: AppColors.white, size: 22),
          ),
        ),
      ),
      title: Text(
        'WARGIFY',
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: AppColors.textPrimary,
            size: 26,
          ),
          onPressed: () {
            // Panggil callback custom jika ada, lalu navigasi ke NotifikasiPage
            onNotificationTap?.call();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotifikasiPage()),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
