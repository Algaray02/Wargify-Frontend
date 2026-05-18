import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class JadwalRondaCard extends StatelessWidget {
  final String bulan;
  final String tanggal;
  final String hariNama;
  final String namaTempat;
  final String waktu;
  final String status;
  final int jumlahAnggota;
  final VoidCallback? onTap;

  const JadwalRondaCard({
    super.key,
    required this.bulan,
    required this.tanggal,
    required this.hariNama,
    required this.namaTempat,
    required this.waktu,
    required this.status,
    required this.jumlahAnggota,
    this.onTap,
  });

  Color get _statusColor {
    switch (status.toUpperCase()) {
      case 'MENDATANG':
        return AppColors.primary;
      case 'BERJALAN':
        return AppColors.success;
      case 'SELESAI':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  Color get _statusBgColor {
    switch (status.toUpperCase()) {
      case 'MENDATANG':
        return AppColors.secondary;
      case 'BERJALAN':
        return const Color(0xFFD4EDDA);
      case 'SELESAI':
        return const Color(0xFFEEEEEE);
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date badge
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    bulan.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    tanggal,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    hariNama.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaTempat,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        waktu,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: status + anggota avatars
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Anggota avatar stack
                _AnggotaAvatarStack(jumlah: jumlahAnggota),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnggotaAvatarStack extends StatelessWidget {
  final int jumlah;

  const _AnggotaAvatarStack({required this.jumlah});

  @override
  Widget build(BuildContext context) {
    final tampil = jumlah > 3 ? 2 : jumlah;
    final sisa = jumlah - tampil;

    return Row(
      children: [
        SizedBox(
          width: tampil * 20.0 + (sisa > 0 ? 24 : 0),
          height: 26,
          child: Stack(
            children: [
              for (int i = 0; i < tampil; i++)
                Positioned(
                  left: i * 18.0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.7 - i * 0.2),
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.person, size: 14, color: AppColors.white),
                  ),
                ),
              if (sisa > 0)
                Positioned(
                  left: tampil * 18.0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '+$sisa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}