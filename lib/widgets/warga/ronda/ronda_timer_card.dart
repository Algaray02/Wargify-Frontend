import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';

class RondaTimerCard extends StatelessWidget {
  final String timer;
  final String lokasi;
  final bool isMulai;
  final VoidCallback? onLokasiTap;

  const RondaTimerCard({
    super.key,
    required this.timer,
    required this.lokasi,
    required this.isMulai,
    this.onLokasiTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isMulai ? AppColors.successLight : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isMulai ? 'RONDA BERJALAN' : 'MULAI RONDA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Lokasi icon
              GestureDetector(
                onTap: onLokasiTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gps_fixed,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timer
          Text(
            timer,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          // Lokasi
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                lokasi,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}